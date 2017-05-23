{%- from "freeipa/map.jinja" import client, ipa_host with context %}

include:
- freeipa.common
{%- if pillar.freeipa.client.install_principal is defined %}
- freeipa.client.preinstall
{%- endif %}
- freeipa.client.keytab
- freeipa.client.nsupdate
- freeipa.client.cert

{%- if client.get('enabled', False) %}

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
        --hostname {{ ipa_host }}
        -w {{ client.otp }}
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

krb5_conf:
  file.managed:
    - name: {{ client.krb5_conf }}
    - template: jinja
    - source: salt://freeipa/files/krb5.conf

{%- endif %}
