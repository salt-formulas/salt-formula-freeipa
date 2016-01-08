{%- from "freeipa/map.jinja" import server with context %}
{%- if server.enabled %}

include:
- freeipa.common

freeipa_server_pkgs:
  pkg.installed:
    - names: {{ server.pkgs }}

freeipa_server_install:
  cmd.run:
    - name: >
        ipa-server-install
        --realm {{ server.realm }}
        --domain {{ server.domain }}
        --hostname {% if server.hostname is defined %}{{ server.hostname }}{% else %}{{ grains['fqdn'] }}{% endif %}
        --ds-password {{ server.ldap.password }}
        --admin-password {{ server.admin.password }}
        --ssh-trust-dns
        {%- if not server.get('ntp', {}).get('enabled', True) %} --no-ntp{%- endif %}
        {%- if server.get('dns', {}).get('zonemgr', False) %} --zonemgr {{ server.dns.zonemgr }}{%- endif %}
        {%- if server.get('dns', {}).get('enabled', True) %} --setup-dns{%- endif %}
        {%- if server.get('dns', {}).get('forwarders', []) %}{%- for forwarder in server.dns.forwarders %} --forwarder={{ forwarder }}{%- endfor %}{%- else %} --no-forwarders{%- endif %}
        {%- if server.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        --no-host-dns
        --unattended
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_server_pkgs
    - require_in:
      - service: sssd_service
      - cmd: freeipa_client_fix_1492226
      - file: ldap_conf

ldap_secure_binds:
  cmd.run:
    - name: |
          ldapmodify -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-minssf
          nsslapd-minssf: {{ server.ldap.minssf }}
          EOF
    - unless: "ldapsearch -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-minssf: {{ server.ldap.minssf }}'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf

{%- if not server.ldap.anonymous %}
ldap_disable_anonymous:
  cmd.run:
    - name: |
          ldapmodify -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-allow-anonymous-access
          nsslapd-allow-anonymous-access: off
          EOF
    - unless: "ldapsearch -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-allow-anonymous-access: off'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf
{%- endif %}

{%- if server.get('dns', {}).get('enabled', True) %}
named_service:
  service.running:
    - name: {{ server.named_service }}
    - require:
      - cmd: freeipa_server_install

named_disable_recursion:
  file.replace:
    - name: /etc/bind/named.conf
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
{%- endif %}

{%- endif %}
