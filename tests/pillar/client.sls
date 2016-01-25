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
openssh:
  server:
    enabled: true
    public_key_auth: true
    gssapi_auth: true
    kerberos_auth: false
    authorized_keys_command:
      command: /usr/bin/sss_ssh_authorizedkeys
      user: nobody
