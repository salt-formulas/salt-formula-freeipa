freeipa:
  server:
    enabled: true
    realm: LOCAL
    domain: local
    servers:
      - idm01.local
      - idm02.local
    admin:
      password: password
    ldap:
      password: password
      logging:
        access: false
        audit: true
      minssf: 56
      anonymous: false
openssh:
  server:
    enabled: true
    public_key_auth: true
    gssapi_auth: true
    kerberos_auth: false
    authorized_keys_command:
      command: /usr/bin/sss_ssh_authorizedkeys
      user: nobody
