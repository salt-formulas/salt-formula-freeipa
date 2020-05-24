{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.common
- freeipa.server.dns
{%- if pillar.get('sensu', {}).get('client', {}).get('enabled', False) %}
- sensu.client
{%- endif %}

freeipa_server_pkgs:
  pkg.installed:
    - names: {{ server.pkgs|tojson }}

/etc/dirsrv/password:
  file.managed:
    - contents: {{ server.ldap.password }}
    - mode: 640
    - owner: root
    {%- if pillar.get('sensu', {}).get('client', {}).get('enabled', False) %}
    - group: sensu
    - require:
      - pkg: sensu_client_packages
    {%- endif %}

ldap_secure_binds:
  cmd.run:
    - name: |
          ldapmodify -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-minssf
          nsslapd-minssf: {{ server.ldap.get('minssf', 0) }}
          EOF
    - unless: "ldapsearch -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-minssf: {{ server.ldap.get('minssf', 0) }}'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf

{%- if server.ldap.get('logging', {}).audit is defined %}
ldap_logs_audit:
  cmd.run:
    - name: |
          ldapmodify -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-auditlog-logging-enabled
          nsslapd-auditlog-logging-enabled: {% if server.ldap.logging.audit %}on{% else %}off{% endif %}
          EOF
    - unless: "ldapsearch -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-auditlog-logging-enabled: {% if server.ldap.logging.audit %}on{% else %}off{% endif %}'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf
{%- endif %}

{%- if server.ldap.get('logging', {}).access is defined %}
ldap_logs_access:
  cmd.run:
    - name: |
          ldapmodify -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-accesslog-logging-enabled
          nsslapd-accesslog-logging-enabled: {% if server.ldap.logging.access %}on{% else %}off{% endif %}
          EOF
    - unless: "ldapsearch -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-accesslog-logging-enabled: {% if server.ldap.logging.access %}on{% else %}off{% endif %}'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf
{%- endif %}

{%- if not server.ldap.get('anonymous') %}
ldap_disable_anonymous:
  cmd.run:
    - name: |
          ldapmodify -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -Z << EOF
          dn: cn=config
          changetype: modify
          replace: nsslapd-allow-anonymous-access
          nsslapd-allow-anonymous-access: off
          EOF
    - unless: "ldapsearch -h localhost -D 'cn=directory manager' -w {{ server.ldap.password }} -b 'cn=config' -Z | grep 'nsslapd-allow-anonymous-access: off'"
    - require:
      - cmd: freeipa_server_install
      - file: ldap_conf
{%- endif %}
