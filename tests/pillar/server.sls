freeipa:
  server:
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
openssh:
  server:
    public_key_auth: true
    gssapi_auth: true
    kerberos_auth: false
    authorized_keys_command:
      command: /usr/bin/sss_ssh_authorizedkeys
      user: nobody
