{%- from "freeipa/map.jinja" import client with context %}
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
        --hostname {% if client.hostname is defined %}{{ client.hostname }}{% else %}{{ grains['fqdn'] }}{% endif %}
        -w {{ client.otp }}
        {%- if client.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        {%- if client.dns.updates %} --enable-dns-updates{%- endif %}
        --unattended
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_client_pkgs
    - require_in:
      - service: sssd_service
      - cmd: freeipa_client_fix_1492226

{%- endif %}
