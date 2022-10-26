{%- from "freeipa/map.jinja" import client, ipa_host, ipa_servers with context %}

include:
- freeipa.common
- freeipa.client.keytab
- freeipa.client.nsupdate
- freeipa.client.cert

{%- if client.install_principal is defined %}
{%- if salt['salt_version.greater_than']('Aluminium') %}
{%- set otp = salt['random.get_str'](length=20, punctuation=False) %}
{%- else %}
{%- set otp = salt['random.get_str'](20) %}
{%- endif %}

freeipa_push_principal:
  file.managed:
    - name: /tmp/principal.keytab
    - source: {{ client.get("install_principal", {}).get("source", "salt://freeipa/files/principal.keytab") }}
    - mode: {{ client.get("install_principal", {}).get("mode", "0600") }}
    - user: {{ client.get("install_principal", {}).get("file_user", "root") }}
    - group: {{ client.get("install_principal", {}).get("file_group", "root") }}
    - unless:
      - ipa-client-install --unattended 2>&1 | grep "IPA client is already configured on this system"
freeipa_get_ticket:
  cmd.run:
    - name: kinit {{ client.get("install_principal", {}).get("principal_user", "root") }}@{{ client.get("realm", "") }} -kt /tmp/principal.keytab
    - require:
      - file: freeipa_push_principal
    - onchanges:
      - file: freeipa_push_principal
{%- if client.ip is defined %}
{%- set client_ip = client.get("ip") %}
freeipa_dnsrecord_add:
  cmd.run:
    - name: >
        curl -k -s
        -H referer:https://{{ ipa_servers[0] }}/ipa
        --negotiate -u :
        -H "Content-Type:application/json"
        -H "Accept:application/json"
        -c /tmp/cookiejar -b /tmp/cookiejar
        --output /dev/stderr
        --write-out "%{http_code}"
        -X POST
        -d '{
          "id": 0,
          "method": "dnsrecord_add",
          "params": [
            [
              "{{ client.get("domain", {}) }}",
              {
                "__dns_name__": "{{ client.get("hostname", {}).replace(client.get("domain", {}), "")[:-1] }}"
              }
            ],
            {
              {%- if client_ip.get("reverse", True) %}
              {%- if client_ip.get("aaaa") %}
              "aaaa_extra_create_reverse": true,
              {%- else %}
              "a_extra_create_reverse": true,
              {%- endif %}
              {%- endif %}
              {%- if client_ip.get("aaaa") %}
              "aaaa_part_ip_address": "{{ client_ip.get("aaaa") }}",
              {%- else %}
              "a_part_ip_address": "{{ client_ip.get("a", salt.grains.get("fqdn_ip4", [])[0]) }}",
              {%- endif %}
              "version": "2.156"
            }
          ]
        }' https://{{ ipa_servers[0] }}/ipa/json | awk '{if ($0<200||$0>399) exit $0}'
    - require:
      - cmd: freeipa_get_ticket
    - require_in:
      - cmd: freeipa_client_install
    - onchanges:
      - file: freeipa_push_principal
{%- endif %}
freeipa_host_add:
  cmd.run:
    - name: >
        curl -k -s
        -H referer:https://{{ ipa_servers[0] }}/ipa
        --negotiate -u :
        -H "Content-Type:application/json"
        -H "Accept:applicaton/json"
        -c /tmp/cookiejar -b /tmp/cookiejar
        --output /dev/stderr
        --write-out "%{http_code}"
        -X POST
        -d '{
          "id": 0,
          "method": "host_add",
                    "params": [
            [
              "{{ client.get("hostname", {})  }}"
            ],
            {
              "all": false,
              "force": false,
              "no_members": false,
              "no_reverse": false,
              "random": false,
              "raw": true,
              "userpassword": "{{ otp }}",
              "version": "2.156"
            }
          ]
        }' https://{{ ipa_servers[0] }}/ipa/json | awk '{if ($0<200||$0>399) exit $0}'
    - require:
      - cmd: freeipa_get_ticket
{%- if client.ip is defined %}
      - cmd: freeipa_dnsrecord_add
{%- endif %}
    - require_in:
      - cmd: freeipa_client_install
    - onchanges:
      - file: freeipa_push_principal

freeipa_cleanup_cookiejar:
  file.absent:
    - name: /tmp/cookiejar
    - require:
      - cmd: freeipa_host_add
    - require_in:
      -cmd: freeipa_client_install
    - onchanges:
      - cmd: freeipa_host_add
freeipa_cleanup_keytab:
  file.absent:
    - name: /tmp/principal.keytab
    - require:
      - cmd: freeipa_host_add
    - require_in:
      -cmd: freeipa_client_install
    - onchanges:
      - cmd: freeipa_host_add
freeipa_kdestroy:
  cmd.run:
    - name: kdestroy
    - require:
      - cmd: freeipa_host_add
    - require_in:
      -cmd: freeipa_client_install
    - onchanges:
      - file: freeipa_push_principal
{%- endif %}

{%- if client.get('enabled', False) %}

freeipa_client_pkgs:
  pkg.installed:
    - names: {{ client.pkgs|tojson }}

freeipa_client_install:
  cmd.run:
    - name: >
        ipa-client-install
        {%- for server in ipa_servers %}
        --server {{ server }}
        {%- endfor %}
        --domain {{ client.domain }}
        {%- if client.realm is defined %} --realm {{ client.realm }}{%- endif %}
        --hostname {{ ipa_host }}
        {%- if otp is defined %}
        -w '{{ otp }}'
        {%- else %}
        -w '{{ client.otp }}'
        {%- endif %}
        {%- if not client.get('ntp', {}).get('enabled', True) %} --no-ntp{%- endif %}
        {%- if client.get('mkhomedir', True) %} --mkhomedir{%- endif %}
        {%- if client.dns.updates %} --enable-dns-updates{%- endif %}
        --unattended
    - creates: /etc/ipa/default.conf
    - require:
      - pkg: freeipa_client_pkgs
    - require_in:
      - service: sssd_service
      - file: ldap_conf
      - file: krb5_conf
    {%- if client.install_principal is defined %}
    - onchanges:
      - file: freeipa_push_principal
    {%- endif %}

krb5_conf:
  file.managed:
    - name: {{ client.krb5_conf }}
    - template: jinja
    - source: salt://freeipa/files/krb5.conf

{%- endif %}
