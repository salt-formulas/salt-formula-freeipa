{%- from "freeipa/map.jinja" import server with context %}

{%- if server.get('dns', {}).get('enabled', True) %}

named_service:
  service.running:
    - name: {{ server.named_service }}
    - require:
      - cmd: freeipa_server_install

named_disable_recursion:
  file.replace:
    - name: {{ server.named_conf }}
    - pattern: 'allow-recursion \{ any; \};'
    - repl: 'allow-recursion { localhost; };'
    - require:
      - cmd: freeipa_server_install
    - watch_in:
      - service: named_service

named_hide_version:
  cmd.run:
    - name: "sed -i -e 's/options {/options {\\n\tversion \"hidden\";/' {{ server.named_conf }}"
    - unless: "grep 'version \"hidden\";' {{ server.named_conf }}"
    - require:
      - cmd: freeipa_server_install
    - watch_in:
      - service: named_service

{%- for name, zone in server.get('dns', {}).get('zone', {}).iteritems() %}
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
        ; ret=$?; kdestroy; exit $ret
    - unless: "echo {{ server.admin.password }} | kinit admin && ipa dnszone-find --name={{ name }}; ret=$?; kdestroy; exit $ret"
    - env:
      - KRB5CCNAME: /tmp/krb5cc_salt
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf

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
