{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.server.common

{#
 Replica needs to be prepared first on master using
   ipa-replica-prepare ipareplica.example.com --ip-address 192.168.1.2 -p "$FREEIPA_LDAP_PASSWORD"
 and stored in /var/lib/ipa/replica-info-ipareplica.example.com.gpg
 #}

freeipa_server_install:
  cmd.run:
    - name: >
        ipa-replica-install
        -w "$FREEIPA_ADMIN_PASSWORD"
        --ssh-trust-dns
        {%- if not server.get('ntp', {}).get('enabled', True) %} --no-ntp{%- endif %}
        {%- if server.get('dns', {}).get('enabled', True) %} --setup-dns{%- endif %}
        --forward-policy={{ server.get('dns', {}).get('forward', 'first') }}
        {%- if server.get('dns', {}).get('forwarders', []) %}{%- for forwarder in server.dns.forwarders %} --forwarder={{ forwarder }}{%- endfor %}{%- else %} --no-forwarders{%- endif %}
        {%- if not server.get('dns', {}).get('dnssec', {}).get('validation', True) %} --no-dnssec-validation{%- endif %}
        {%- if server.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        {%- if server.get('no_host_dns', false) %} --no-host-dns{%- endif %}
        {%- if server.get('ca', true) %} --setup-ca{%- endif %}
        --skip-conncheck
        --no-reverse
        --unattended
        {%- if server.principal_user is defined %}
        --principal {{ server.principal_user }}
        --domain {{ server.domain }}
        --realm {{ server.realm }}
        --server {{ server.servers.0 }}
        --hostname {{ server.get('hostname', grains['fqdn']) }}
        {%- else %}
        --password "$FREEIPA_LDAP_PASSWORD"
        /var/lib/ipa/replica-info-{{ server.get('hostname', grains['fqdn']) }}.gpg
        {%- endif %}
    - env:
      - FREEIPA_LDAP_PASSWORD: {{ server.ldap.password }}
      - FREEIPA_ADMIN_PASSWORD: {{ server.admin.password }}
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_server_pkgs
    - require_in:
      - service: sssd_service
      - file: ldap_conf

