resource "aws_lightsail_instance" "jenkins" {
  name              = "jenkins"
  availability_zone = "ap-northeast-2a"
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "small_2_0"
  key_pair_name     = "shop"
}

resource "aws_lightsail_instance_public_ports" "jenkins" {
  instance_name = aws_lightsail_instance.jenkins.name

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
  }

  port_info {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
  }
}