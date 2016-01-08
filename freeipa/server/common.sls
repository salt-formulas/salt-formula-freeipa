{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.common

freeipa_server_pkgs:
  pkg.installed:
    - names: {{ server.pkgs }}

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
