{%- from "freeipa/map.jinja" import client, ipa_host with context %}
{%- if client.enabled %}

include:
  - freeipa.client

{%- for principal, cert in client.get("cert", {}).iteritems() %}
{%- if cert.principal is defined %}
  {%- set principal = cert.principal %}
{%- endif %}
{%- set pparts = principal.split('/') %}
{%- set service = pparts[0] %}
{%- set cn = pparts[1] %}
{%- set cert_file = cert.get('cert', '/etc/ssl/certs/' + service|lower + '-' + cn + '.crt') %}
{%- set key_file = cert.get('key', '/etc/ssl/private/' + service|lower + '-' + cn + '.key') %}

freeipa_cert_{{ principal }}:
  cmd.run:
    - name: >
        ipa-getcert request -r
        -f {{ cert_file }}
        -k {{ key_file }}
        -N CN={{ cn }}
        -D {{ cn }}
        {%- if cert.mail is defined %} -E {{ cert.mail }}{%- endif %}
        -K {{ principal }}
    - unless: "ipa-getcert list -t -f {{ cert_file }} | grep 'status: MONITORING'"
    - require:
      - cmd: freeipa_client_install

freeipa_cert_{{ key_file }}_key_permissions:
  file.managed:
    - name: {{ key_file }}
    - mode: {{ cert.get("mode", 0600) }}
    - user: {{ cert.get("user", "root") }}
    - group: {{ cert.get("group", "root") }}
    - watch:
      - cmd: freeipa_cert_{{ principal }}

{%- endfor %}

{%- endif %}
