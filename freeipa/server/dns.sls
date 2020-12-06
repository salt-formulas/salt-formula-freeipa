{%- from "freeipa/map.jinja" import server with context %}

{%- if server.get('dns', {}).get('enabled', True) %}

named_service:
  service.running:
    - name: {{ server.named_service }}
    - watch:
      - file: named_config

named_config:
  file.managed:
    - name: {{ server.named_conf }}
    - source: salt://freeipa/files/named.conf
    - template: jinja
    - owner: root
    - group: named
    - mode: 640
    - require:
      - cmd: freeipa_server_install
    - watch_in:
      - service: named_service

freeipa_zones_dir:
  file.directory:
    - name: /var/lib/ipa/zones
    - require:
      - cmd: freeipa_server_install

{%- for name, zone in server.get('dns', {}).get('zone', {}).items() %}
{%- if zone.get('enabled', True) %}
freeipa_dnszone_{{ name }}:
  cmd.run:
    - name: >
        echo {{ server.admin.password }} | kinit admin &&
        ipa dnszone-add "{{ name }}"
        {%- if zone.admin is defined %} --admin-email={{ zone.admin|replace('@', '.') }}.{%- endif %}
        {%- if zone.refresh is defined %} --refresh={{ zone.refresh }}{%- endif %}
        {%- if zone.retry is defined %} --retry={{ zone.retry }}{%- endif %}
        {%- if zone.expire is defined %} --expire={{ zone.expire }}{%- endif %}
        {%- if zone.minimum is defined %} --minimum={{ zone.minimum }}{%- endif %}
        {%- if zone.ttl is defined %} --ttl={{ zone.ttl }}{%- endif %}
        --dynamic-update={{ 1 if zone.get('dynamic', {}).get('enabled', False) else 0 }}
        {%- if zone.get('dynamic', {}).policy is defined %} --update-policy="{%- for policy in zone.dynamic.policy %}{{ policy.get('permission', 'grant') }} {{ policy.identity }} {{ policy.match }} {{ policy.get('tname', '') }} {{ policy.get('rr', '') }};{%- endfor %}"{%- endif %}
        {%- if zone.transfer is defined %} --allow-transfer="{{ zone.transfer|join(';') }}"{%- endif %}
        {%- if zone.nameservers is defined %} --name-server="{{ zone.nameservers[0] }}."{%- endif %}
        ; ret=$?; [ $ret -eq 0 ] && touch /var/lib/ipa/zones/{{ name }}-created.lock ;kdestroy; exit $ret
    - unless: "test -f /var/lib/ipa/zones/{{ name }}-created.lock || (echo {{ server.admin.password }} | kinit admin && ipa dnszone-find --name={{ name }}; ret=$?; [ $ret -eq 0 ] && touch /var/lib/ipa/zones/{{ name }}-created.lock; kdestroy; exit $ret)"
    - env:
      - KRB5CCNAME: /tmp/krb5cc_salt
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf
      - file: freeipa_zones_dir

{%- if zone.transfer is defined %}
freeipa_dnszone_{{ name }}_transfer:
  cmd.run:
    - name: |
          ldapmodify -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: idnsname={{ name }}.,cn=dns,dc={{ server.domain|replace('.', ',dc=') }}
          changetype: modify
          replace: idnsAllowTransfer
          idnsAllowTransfer: {{ zone.transfer|join(';') }};
          EOF
    - unless: "ldapsearch -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'idnsname={{ name }}.,cn=dns,dc={{ server.domain|replace('.', ',dc=') }}' -Z | grep 'idnsAllowTransfer: {{ zone.transfer|join(';') }}'"
    - watch:
      - cmd: freeipa_dnszone_{{ name }}
{%- endif %}

{%- if zone.nameservers is defined %}
freeipa_dnszone_{{ name }}_nameservers:
  cmd.wait:
    - name: >
        echo {{ server.admin.password }} | kinit admin &&
        ipa dnsrecord-mod "{{ name }}" '@'
        {%- for server in zone.nameservers %}
        --ns-rec="{{ server }}."
        {%- endfor %}
        ; ret=$?; kdestroy; exit $ret
    - env:
      - KRB5CCNAME: /tmp/krb5cc_salt
    - watch:
      - cmd: freeipa_dnszone_{{ name }}
{%- endif %}

{%- endif %}
{%- endfor %}

{%- endif %}
