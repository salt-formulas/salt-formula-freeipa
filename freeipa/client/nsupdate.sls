{%- from "freeipa/map.jinja" import client, server, ipa_host with context %}

include:
  {%- if server.get('enabled', False) %}
  - freeipa.server
  {%- else %}
  - freeipa.client
  {%- endif %}

{%- set default_ipv4 = salt['cmd.run']("echo -n $(ip r get 8.8.8.8|grep -v -e 'dev lo'|head -1|awk '{print $NF}')") %}
{%- set default_ipv6 = salt['cmd.run']("echo -n $(ip r get 2a00:1450:400d:802::200e|grep -v -e 'dev lo'|head -1|awk '{print $NF}')") %}

{%- for host in client.get("nsupdate", {}) %}

/etc/nsupdate-{{ host.name }}:
  file.managed:
    - template: jinja
    - source: salt://freeipa/files/nsupdate
    - defaults:
        name: {{ host.name }}
        {%- if host.ipv4 is not defined and host.name == ipa_host and default_ipv4 != '' %}
        ipv4: ["{{ default_ipv4 }}"]
        {%- else %}
        ipv4: {{ host.ipv4|default([]) }}
        {%- endif %}
        {%- if host.ipv6 is not defined and host.name == ipa_host and default_ipv6 != '' %}
        ipv6: ["{{ default_ipv6 }}"]
        {%- else %}
        ipv6: {{ host.ipv6|default([]) }}
        {%- endif %}
        ttl: {{ host.get('ttl', 1800) }}
        {%- if host.server is defined %}
        server: {{ host.server }}
        {%- endif %}
        reverse: {{ host.get('reverse', False) }}
    - watch_in:
      - cmd: nsupdate_{{ host.name }}
    - require:
      {%- if host.name == ipa_host %}
      {%- if server.get('enabled', False) %}
      - cmd: freeipa_server_install
      {%- else %}
      - cmd: freeipa_client_install
      {%- endif %}
      {%- else %}
      - cmd: freeipa_keytab_{{ host.get('keytab', '/etc/krb5.keytab') }}_host_{{ host.name }}
      {%- endif %}

/etc/nsupdate-{{ host.name }}-delete:
  file.managed:
    - template: jinja
    - source: salt://freeipa/files/nsupdate-delete
    - defaults:
        name: {{ host.name }}
        {%- if host.ipv4 is not defined and host.name == ipa_host and default_ipv4 != '' %}
        ipv4: ["{{ default_ipv4 }}"]
        {%- else %}
        ipv4: {{ host.ipv4|default([]) }}
        {%- endif %}
        {%- if host.ipv6 is not defined and host.name == ipa_host and default_ipv6 != '' %}
        ipv6: ["{{ default_ipv6 }}"]
        {%- else %}
        ipv6: {{ host.ipv6|default([]) }}
        {%- endif %}
        {%- if host.server is defined %}
        server: {{ host.server }}
        {%- endif %}
        reverse: {{ host.get('reverse', False) }}
    - require:
      - file: /etc/nsupdate-{{ host.name }}

nsupdate_{{ host.name }}:
  cmd.wait:
    - name: "kinit -kt {{ host.get('keytab', '/etc/krb5.keytab') }} host/{{ host.name }} && nsupdate -g /etc/nsupdate-{{ host.name }}; E=$?; /usr/bin/kdestroy; exit $E"
    - env:
      - KRB5CCNAME: /tmp/krb5cc_salt

{%- endfor %}
