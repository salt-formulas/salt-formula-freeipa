{%- from "freeipa/map.jinja" import client,server with context %}

include:
- openssh.server

sssd_service:
  service.running:
    - name: sssd
    - watch_in:
      - service: openssh_server_service

{%- if client.get('mkhomedir', True) and server.get('mkhomedir', True) %}
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

# Workaround bug
# https://bugs.launchpad.net/ubuntu/+source/freeipa/+bug/1492226
# before freeipa-client version 4.1.4 is in trusty
freeipa_client_fix_1492226:
  cmd.run:
    - name: sed -i "/^services/s/$/, sudo/" /etc/sssd/sssd.conf
    - unless: grep services /etc/sssd/sssd.conf | grep sudo >/dev/null
    - watch_in:
      - service: sssd_service
