freeipa:
  client:
    enabled: true
    hostname: freeipa.ci.kitchenci
    server: freeipa.ci.kitchenci
    servers:
      - freeipa.ci.kitchenci
      - freeipa2.ci.kitchenci
    domain: kitchenci
    realm: KITCHENCI
    otp: password
    keytab:
      /etc/apache2/ipa.keytab:
        mode: 0640
        user: root
        group: www-data
        identities:
          - service: HTTP
            host: test.ci.kitchenci
          - service: host
            host: anothertest.ci.kitchenci
    nsupdate:
      - name: test.ci.kitchenci
        ipv4:
          - 8.8.8.8
        ipv6:
          - 2a00:1450:4001:80a::1009
        ttl: 1800
        keytab: /etc/krb5.keytab
      - name: anothertest.ci.kitchenci
        ipv4:
          - 8.8.8.8
    cert:
      "HTTP/www.ci.kitchenci":
        user: root
        group: www-data
        mode: 640
        cert: /etc/ssl/certs/http-www.ci.kitchenci.crt
        key: /etc/ssl/private/http-www.ci.kitchenci.key
openssh:
  server:
    enabled: true
    public_key_auth: true
    gssapi_auth: true
    kerberos_auth: false
    authorized_keys_command:
      command: /usr/bin/sss_ssh_authorizedkeys
      user: nobody
