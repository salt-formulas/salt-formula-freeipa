{%- from "freeipa/map.jinja" import client, ipa_host with context %}
{%- if client.enabled %}

include:
- freeipa.common

freeipa_client_pkgs:
  pkg.installed:
    - names: {{ client.pkgs }}

freeipa_client_install:
  cmd.run:
    - name: >
        ipa-client-install
        --server {{ client.server }}
        --domain {{ client.domain }}
        {%- if client.realm is defined %} --realm {{ client.realm }}{%- endif %}
        --hostname {{ ipa_host }}
        -w {{ client.otp }}
        {%- if client.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        {%- if client.dns.updates %} --enable-dns-updates{%- endif %}
        --unattended
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_client_pkgs
    - require_in:
      - service: sssd_service
      {%- if grains.os_family == 'Debian' %}
      - cmd: freeipa_client_fix_1492226
      {%- endif %}
      - file: ldap_conf

{%- for keytab_file, keytab in client.get("keytab", {}).iteritems() %}

freeipa_keytab_{{ keytab_file }}:
  file.managed:
    - name: {{ keytab_file }}
    - mode: {{ keytab.get("mode", 0600) }}
    - user: {{ keytab.get("user", root) }}
    - group: {{ keytab.get("group", root) }}

{%- for identity in keytab.get("identities", []) %}
freeipa_keytab_{{ keytab_file }}_{{ identity.service }}_{{ identity.get('host', ipa_host) }}:
  cmd.run:
    - name: "kinit host/{{ ipa_host }} && ipa-getkeytab -k {{ keytab_file }} -p {{ identity.service }}/{{ identity.get('host', ipa_host) }}; E=$?; kdestroy; exit $E"
    - unless: "kinit -kt {{ keytab_file }} {{ identity.service }}/{{ identity.get('host', ipa_host) }}; E=$?; /usr/bin/kdestroy; exit $E"
    - require:
      - cmd: freeipa_client_install
      - file: freeipa_keytab_{{ keytab_file }}
{%- endfor %}

{%- endfor %}

{%- endif %}
