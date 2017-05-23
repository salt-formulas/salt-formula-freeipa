{%- from "freeipa/map.jinja" import client, server, ipa_host with context %}
{% set otp = salt['random.get_str'](20) %}

push_principal:
  file.managed:
    - name: /tmp/principal.keytab
    - source: {{ client.get("install_principal", {}).get("source", "salt://freeipa/files/principal.keytab") }}
    - mode: {{ client.get("install_principal", {}).get("mode", 0600) }}
    - user: {{ client.get("install_principal", {}).get("file_user", "root") }}
    - group: {{ client.get("install_principal", {}).get("file_group", "root") }}
get_ticket:
  cmd.run:
    - name: kinit {{ client.get("install_principal", {}).get("principal_user", "root") }}@{{ client.get("realm", "") }} -kt /tmp/salt-service.keytab
    - require: 
      - file: push_principal
ipa_host_add:
  cmd.run:
    - name: >
        curl -k
        -H referer:https://{{ client.get("server", {}) }}/ipa
        --negotiate -u :
        -H "Content-Type:application/json"
        -H "Accept:applicaton/json"
        -c /tmp/cookiejar -b /tmp/cookiejar
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
        }' https://{{ client.get("server", {}) }}/ipa/json
    - require:
      - cmd: get_ticket
    - prereq:
      - cmd: freeipa_client_install
cleanup_cookiejar:
  file.absent:
    - name: /tmp/cookiejar
cleanup_keytab:
  file.absent:
    - name: /tmp/principal.keytab
kdestroy:
  cmd.shell:
    - name: kdestroy
