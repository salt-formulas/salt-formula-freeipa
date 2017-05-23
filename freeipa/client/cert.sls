{%- from "freeipa/map.jinja" import client, server, ipa_host with context %}

include:
  {%- if server.get('enabled', False) %}
  - freeipa.server
  {%- else %}
  - freeipa.client
  {%- endif %}

freeipa_certmonger_service:
  service.running:
    - name: certmonger
    - require:
      {%- if server.get('enabled', False) %}
      - cmd: freeipa_server_install
      {%- else %}
      - cmd: freeipa_client_install
      {%- endif %}

{%- if grains.os_family == 'RedHat' %}
{#- Fix for Debian compatibility #}
freeipa_certmonger_symlink:
  file.symlink:
    - name: /usr/lib/certmonger
    - target: /usr/libexec/certmonger
    - watch_in:
      - service: freeipa_certmonger_service
{%- endif %}

{%- for principal, cert in client.get("cert", {}).iteritems() %}
{%- if cert.principal is defined %}
  {%- set principal = cert.principal %}
{%- endif %}
{%- set pparts = principal.split('/') %}
{%- set service = pparts[0] %}
{%- set cn = pparts[1] %}
{%- set cert_file = cert.get('cert', '/etc/ssl/certs/' + service|lower + '-' + cn + '.crt') %}
{%- set key_file = cert.get('key', '/etc/ssl/private/' + service|lower + '-' + cn + '.key') %}

{%- set key_dir = key_file|replace(key_file.split('/')[-1], "") %}
{%- set cert_dir = cert_file|replace(cert_file.split('/')[-1], "") %}
freeipa_cert_{{ principal }}_dirs:
  file.directory:
    - names:
      - {{ key_dir }}
      - {{ cert_dir }}
    - makedirs: true

freeipa_cert_{{ principal }}:
  cmd.run:
    - name: >
        ipa-getcert request -r
        -f {{ cert_file }}
        -k {{ key_file }}
        -N CN={{ cn }}
        -D {{ cn }}
        {%- if cert.mail is defined %} -E {{ cert.mail }}{%- endif %}
        -K {{ principal }};
        i=0; while [ $i -lt 10 ]; do
          ipa-getcert list -f {{ cert_file }} | grep 'status: MONITORING' && exit 0;
          i=$[ $i+1 ]; sleep 2;
        done;
        exit 1
    - unless: "ipa-getcert list -f {{ cert_file }} | grep 'status: MONITORING'"
    - require:
      - file: freeipa_cert_{{ principal }}_dirs
      - service: freeipa_certmonger_service

freeipa_cert_{{ key_file }}_key_permissions:
  file.managed:
    - name: {{ key_file }}
    - mode: {{ cert.get("mode", 0600) }}
    {%- if salt['user.info'](cert.get("user", "root")) %}
    - user: {{ cert.get("user", "root") }}
    {%- endif %}
    {%- if salt['group.info'](cert.get("group", "root")) %}
    - group: {{ cert.get("group", "root") }}
    {%- endif %}
    - watch:
      - cmd: freeipa_cert_{{ principal }}

freeipa_cert_{{ cert_file }}_cert_permissions:
  file.managed:
    - name: {{ cert_file }}
    - mode: {{ cert.get("mode", 0600) }}
    {%- if salt['user.info'](cert.get("user", "root")) %}
    - user: {{ cert.get("user", "root") }}
    {%- endif %}
    {%- if salt['group.info'](cert.get("group", "root")) %}
    - group: {{ cert.get("group", "root") }}
    {%- endif %}
    - watch:
      - cmd: freeipa_cert_{{ principal }}

{%- endfor %}
