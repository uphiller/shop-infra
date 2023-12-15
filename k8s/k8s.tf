resource "aws_lightsail_instance" "k8s-master" {
  name              = "k8s-master"
  availability_zone = "ap-northeast-2a"
  blueprint_id      = "ubuntu_22_04"
  bundle_id         = "small_3_0"
  key_pair_name     = "shop"
  user_data = "cd /home/ubuntu && sudo git clone https://github.com/uphiller/shop-infra.git && chmod 777 ./shop-infra/k8s/k8s-master.sh"
}

resource "aws_lightsail_instance_public_ports" "k8s-master" {
  instance_name = aws_lightsail_instance.k8s-master.name

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
  }

  port_info {
    protocol  = "tcp"
    from_port = 10259
    to_port   = 10259
  }

  port_info {
    protocol  = "tcp"
    from_port = 2379
    to_port   = 2379
  }

  port_info {
    protocol  = "tcp"
    from_port = 2380
    to_port   = 2380
  }

  port_info {
    protocol  = "tcp"
    from_port = 10250
    to_port   = 10250
  }

  port_info {
    protocol  = "tcp"
    from_port = 10257
    to_port   = 10257
  }

  port_info {
    protocol  = "tcp"
    from_port = 10259
    to_port   = 10259
  }
}