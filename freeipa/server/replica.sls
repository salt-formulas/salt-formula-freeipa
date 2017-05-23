{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.server.common

{#
 Replica needs to be prepared first on master using
   ipa-replica-prepare ipareplica.example.com --ip-address 192.168.1.2 -p {{ server.ldap.password }}
 and stored in /var/lib/ipa/replica-info-ipareplica.example.com.gpg
 #}

freeipa_server_install:
  cmd.shell:
    - name: >
        ipa-replica-install
        -w {{ server.admin.password }}
        --ssh-trust-dns
        {%- if not server.get('ntp', {}).get('enabled', True) %} --no-ntp{%- endif %}
        {%- if server.get('dns', {}).get('enabled', True) %} --setup-dns{%- endif %}
        {%- if server.get('dns', {}).get('forwarders', []) %}{%- for forwarder in server.dns.forwarders %} --forwarder={{ forwarder }}{%- endfor %}{%- else %} --no-forwarders{%- endif %}
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
        --hostname {{ grains['fqdn'] }}
        {%- else %}
        --password {{ server.ldap.password }}
        /var/lib/ipa/replica-info-{{ server.get('hostname', grains['fqdn']) }}.gpg
        {%- endif %}
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_server_pkgs
    - require_in:
      - service: sssd_service
      - file: ldap_conf

