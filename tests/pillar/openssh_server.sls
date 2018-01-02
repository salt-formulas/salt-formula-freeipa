openssh:
  server:
    enabled: true
    user:
      test:
        enabled: true
        name: test
        user: 
          enabled: true
          name: test
          sudo: true
          uid: 9999
          full_name: Test User
          home: /home/test
    public_keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCts9Ry.........
    bind:
      address: 0.0.0.0
      port: 8000
