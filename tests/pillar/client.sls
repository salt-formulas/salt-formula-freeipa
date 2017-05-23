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
    install_principal:
      source: salt://freeipa/files/principal.keytab
      mode: 0600
      principal_user: "salt-service"
      file_user: "root"
      file_group: "root
    keytab:
      /etc/apache2/ipa.keytab:
        mode: 0640
        user: root
        group: www-data
        identities:
          - service: HTTP
            host: test.example.com
          - service: host
            host: anothertest.example.com
    nsupdate:
      - name: test.example.com
        ipv4:
          - 8.8.8.8
        ipv6:
          - 2a00:1450:4001:80a::1009
        ttl: 1800
        keytab: /etc/krb5.keytab
      - name: anothertest.example.com
        ipv4:
          - 8.8.8.8
    cert:
      "HTTP/www.example.com":
        user: root
        group: www-data
        mode: 640
        cert: /etc/ssl/certs/http-www.example.com.crt
        key: /etc/ssl/private/http-www.example.com.key
openssh:
  server:
    enabled: true
    public_key_auth: true
    gssapi_auth: true
    kerberos_auth: false
    authorized_keys_command:
      command: /usr/bin/sss_ssh_authorizedkeys
      user: nobody
