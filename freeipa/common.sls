{%- from "freeipa/map.jinja" import client,server with context %}

include:
- openssh.server

sssd_service:
  service.running:
    - name: sssd
    - watch_in:
      - service: openssh_server_service
    - watch:
      - file: sssd_conf

sssd_conf:
  file.managed:
    - name: {{ client.sssd_conf }}
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - source: salt://freeipa/files/sssd.conf
    - makedirs: True

ldap_conf:
  file.managed:
    - name: {{ client.ldap_conf }}
    - template: jinja
    - source: salt://freeipa/files/ldap.conf
    - makedirs: True

{%- if grains.os_family == 'RedHat' %}
ldap_conf_nss:
  file.absent:
    - name: /etc/ldap.conf

nss_packages_absent:
  pkg.removed:
    - names: ['nss-pam-ldapd', 'nslcd']
    - watch_in:
      - file: ldap_conf_nss
{%- endif %}

{%- if client.get('mkhomedir', True) and server.get('mkhomedir', True) %}
{%- if grains.os_family == 'Debian' %}
# This should be shipped by package and setup with --mkhomedir above, but
# obviously isn't
pam_mkhomedir_config:
  file.managed:
    - name: /usr/share/pam-configs/mkhomedir
    - source: salt://freeipa/files/mkhomedir
    - require:
      - service: sssd_service

pam_auth_update:
  cmd.wait:
    - name: pam-auth-update --force
    - env:
      - DEBIAN_FRONTEND: noninteractive
    - watch:
      - file: pam_mkhomedir_config
{%- endif %}
{%- endif %}

