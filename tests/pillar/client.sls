freeipa:
  client:
    enabled: true
    hostname: client01.local
    server: idm01.local
    servers:
      - idm01.local
      - idm02.local
    domain: local
    realm: LOCAL
    otp: password
    keytab:
      /etc/apache2/ipa.keytab:
        mode: 0640
        user: root
        group: www-data
        identities:
          - service: HTTP
            host: test.example.com
openssh:
  server:
    enabled: true
    public_key_auth: true
    gssapi_auth: true
    kerberos_auth: false
    authorized_keys_command:
      command: /usr/bin/sss_ssh_authorizedkeys
      user: nobody
