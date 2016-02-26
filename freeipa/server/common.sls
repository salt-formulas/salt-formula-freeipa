{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.common
- freeipa.server.dns

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

{%- if server.ldap.get('logging', {}).audit is defined %}
ldap_logs_audit:
  cmd.run:
    - name: |
          ldapmodify -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-auditlog-logging-enabled
          nsslapd-auditlog-logging-enabled: {% if server.ldap.logging.audit %}on{% else %}off{% endif %}
          EOF
    - unless: "ldapsearch -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-auditlog-logging-enabled: {% if server.ldap.logging.audit %}on{% else %}off{% endif %}'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf
{%- endif %}

{%- if server.ldap.get('logging', {}).access is defined %}
ldap_logs_access:
  cmd.run:
    - name: |
          ldapmodify -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-accesslog-logging-enabled
          nsslapd-accesslog-logging-enabled: {% if server.ldap.logging.access %}on{% else %}off{% endif %}
          EOF
    - unless: "ldapsearch -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-accesslog-logging-enabled: {% if server.ldap.logging.access %}on{% else %}off{% endif %}'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf
{%- endif %}

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
