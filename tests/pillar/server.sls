freeipa:
  server:
    enabled: true
    realm: KITCHENCI
    domain: kitchenci
    servers:
      - freeipa.ci.kitchenci
      - freeipa2.ci.kitchenci
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
