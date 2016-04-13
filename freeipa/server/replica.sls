{%- from "freeipa/map.jinja" import server with context %}

include:
- freeipa.server.common

{#
 Replica needs to be prepared first on master using
   ipa-replica-prepare ipareplica.example.com --ip-address 192.168.1.2 -p {{ server.ldap.password }}
 and stored in /var/lib/ipa/replica-info-ipareplica.example.com.gpg
 #}

freeipa_server_install:
  cmd.run:
    - name: >
        ipa-replica-install
        --password {{ server.ldap.password }}
        -w {{ server.admin.password }}
        --ssh-trust-dns
        {%- if not server.get('ntp', {}).get('enabled', True) %} --no-ntp{%- endif %}
        {%- if server.get('dns', {}).get('enabled', True) %} --setup-dns{%- endif %}
        {%- if server.get('dns', {}).get('forwarders', []) %}{%- for forwarder in server.dns.forwarders %} --forwarder={{ forwarder }}{%- endfor %}{%- else %} --no-forwarders{%- endif %}
        {%- if server.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        --no-host-dns
        --skip-conncheck
        --no-reverse
        --unattended
        /var/lib/ipa/replica-info-{{ server.get('hostname', grains['fqdn']) }}.gpg
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_server_pkgs
    - require_in:
      - service: sssd_service
      - file: ldap_conf

ipa_replica_connect_script:
  file.managed:
    - name: /usr/local/sbin/ipa_replica_connect.sh
    - source: salt://freeipa/files/ipa_replica_connect.sh
    - mode: 0755

freeipa_connect_replicas:
  cmd.run:
    - names:
      - echo "{{ server.admin.password }}" | kinit admin
      - /usr/local/sbin/ipa_replica_connect.sh
    - env:
      - KRB5CCNAME: /tmp/krb5cc_salt
    - require:
      - file: ipa_replica_connect_script
      - cmd: freeipa_server_install
