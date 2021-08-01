{%- from "freeipa/map.jinja" import client,server with context %}

{%- if not client.get('manual_sshd', False) %}
include:
- openssh.server
{%- endif %}

sssd_service:
  service.running:
    - name: sssd
{%- if not client.get('manual_sshd', False) %}
    - watch_in:
      - service: openssh_server_service
{%- endif %}
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

# Workaround https://bugs.launchpad.net/ubuntu/+source/pam/+bug/682662
# by custom wrapper script
pam_enable_mkhomedir:
  file.managed:
    - name: /usr/local/bin/pam-enable-mkhomedir
    - source: salt://freeipa/files/pam-enable-mkhomedir
    - mode: 755
    - require:
      - service: sssd_service

pam_auth_update:
  cmd.wait:
    - name: /usr/local/bin/pam-enable-mkhomedir
    - watch:
      - file: pam_mkhomedir_config
{%- endif %}
{%- endif %}

