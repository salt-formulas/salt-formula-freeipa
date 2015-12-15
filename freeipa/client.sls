{%- from "freeipa/map.jinja" import client with context %}
{%- if client.enabled %}

freeipa_client_pkgs:
  pkg.installed:
    - names: {{ client.pkgs }}

freeipa_client_install:
  cmd.run:
    - name: >
        ipa-client-install
        --server {{ client.server }}
        --domain {{ client.domain }}
        --realm {{ client.realm }}
        --hostname {% if client.hostname is defined %}{{ client.hostname }}{% else %}{{ grains['fqdn'] }}{% endif %}
        -w {{ client.otp }}
        {%- if client.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        {%- if client.dns.updates %} --enable-dns-updates{%- endif %}
        --unattended
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_client_pkgs

sssd_service:
  service.running:
    - name: sssd
    - require:
      - cmd: freeipa_client_install

{%- if client.get('mkhomedir', True) %}
# This should be shipped by package and setup with --mkhomedir above, but
# obviously isn't
pam_mkhomedir_config:
  file.managed:
    - name: /usr/share/pam-configs/mkhomedir
    - source: salt://freeipa/files/mkhomedir
    - require:
      - cmd: freeipa_client_install

pam_auth_update:
  cmd.wait:
    - name: pam-auth-update --force
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
    - require:
      - cmd: freeipa_client_install
    - watch_in:
      - service: sssd_service

{%- endif %}
