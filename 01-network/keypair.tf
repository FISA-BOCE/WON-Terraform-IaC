resource "tls_private_key" "boce_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "boce_key" {
  key_name   = "boce-keypair"
  public_key = tls_private_key.boce_key.public_key_openssh

  tags = merge(var.default_tags, {
    Name = "boce-keypair"
  })
}

resource "local_file" "boce_private_key" {
  content         = tls_private_key.boce_key.private_key_pem
  filename        = "${path.module}/boce-keypair.pem"
  file_permission = "0400"
}
