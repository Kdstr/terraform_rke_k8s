  - address: ${public_dns}
    user: ubuntu
    role: [${role}]
    ssh_key_path: "./ssh_keys/id_rsa"
    internal_address: ${internal_address}