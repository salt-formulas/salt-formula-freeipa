{%- from "freeipa/map.jinja" import server with context %}
{%- if server.enabled %}

include:
- freeipa.server.common

freeipa_server_install:
  cmd.run:
    - name: >
        ipa-server-install
        --realm {{ server.realm }}
        --domain {{ server.domain }}
        --hostname {% if server.hostname is defined %}{{ server.hostname }}{% else %}{{ grains['fqdn'] }}{% endif %}
        --ds-password {{ server.ldap.password }}
        --admin-password {{ server.admin.get('password', server.ldap.password) }}
        --ssh-trust-dns
        {%- if not server.get('ntp', {}).get('enabled', True) %} --no-ntp{%- endif %}
        {%- if server.get('dns', {}).get('zonemgr', False) %} --zonemgr {{ server.dns.zonemgr }}{%- endif %}
        {%- if server.get('dns', {}).get('enabled', True) %} --setup-dns{%- endif %}
        {%- if server.get('dns', {}).get('forwarders', []) %}{%- for forwarder in server.dns.forwarders %} --forwarder={{ forwarder }}{%- endfor %}{%- else %} --no-forwarders{%- endif %}
        {%- if server.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        --auto-reverse
        --no-host-dns
        --allow-zone-overlap
        --unattended
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_server_pkgs
    - require_in:
      - service: sssd_service
      - file: ldap_conf

{%- endif %}
