
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "rke_general_node_definition" {
    count    = "${var.general_counter}"
    template = "${file("./templates/rke_node.tpl")}"
    vars {
      public_dns = "${aws_instance.rancher_general.*.public_dns[count.index]}"
      internal_address = "${aws_instance.rancher_general.*.private_ip[count.index]}"
      role = "${aws_instance.rancher_general.*.tags.role[count.index]}"
   }
}

data "template_file" "rke_worker_node_definition" {
    count    = "${var.worker_counter}"
    template = "${file("./templates/rke_node.tpl")}"
    vars {
      public_dns = "${aws_instance.rancher_worker.*.public_dns[count.index]}"
      internal_address = "${aws_instance.rancher_worker.*.private_ip[count.index]}"
      role = "${aws_instance.rancher_worker.*.tags.role[count.index]}"
   }
}

# configure an aws keypair to use
# keys are used from the ssh_keys folder located in the folder where this .tf file resides in
resource "aws_key_pair" "basic" {
  key_name   = "basic"
  public_key = "${file("./ssh_keys/id_rsa.pub")}"
}


resource "aws_security_group" "cluster_instance_sg" {
  name        = "Rancher-Instances"
  description = "Rules for connected Rancher host machines. These are the hosts that run containers placed on the cluster."
  vpc_id      = "${module.vpc.vpc_id}"

   // kubernetes specific ports
#   ingress {
#       from_port = 6443
#       to_port   = 6443
#       protocol  = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#   }
#  ingress {
#       from_port = 6443
#       to_port   = 6443
#       protocol  = "udp"
#       cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#       from_port = 2379
#       to_port   = 2380
#       protocol  = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#       from_port = 2379
#       to_port   = 2380
#       protocol  = "udp"
#       cidr_blocks = ["0.0.0.0/0"]
#   }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  // These are for maintenance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // This is for outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

 

  # NOTE: To allow ELB proxied traffic to private VPC


  #       hosts, open the necessary ports here..

  lifecycle {
    create_before_destroy = true
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "rancher_test1"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true
  enable_dns_hostnames = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }

}

resource "aws_instance" "bastion" {
  connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("./ssh_keys/id_rsa")}"
        timeout     = "1m"
        agent       = false
    }

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.basic.id}"
  security_groups = ["${aws_security_group.cluster_instance_sg.id}"]
  

  subnet_id = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  source_dest_check = false
 
  provisioner "file" {
    source      = "./install_rke.sh"
    destination = "/tmp/install_rke.sh"
   }

   

  
  
    provisioner "remote-exec" {
        inline = [
        "echo '${file("./templates/rke_base.tpl")}' > /tmp/cluster.yaml", 
        "echo '${join("\n", data.template_file.rke_general_node_definition.*.rendered)}' >>  /tmp/cluster.yaml",
        "echo '${join("\n", data.template_file.rke_worker_node_definition.*.rendered)}' >>  /tmp/cluster.yaml"
        ]
        
    }

    provisioner "remote-exec" {
     inline = [
      "sudo chmod +x /tmp/install_rke.sh",
      "sudo /tmp/install_rke.sh"
    ]
   }

  tags {
      role = "worker"
  }

}

resource "aws_instance" "rancher_worker" {
  connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("./ssh_keys/id_rsa")}"
        timeout     = "1m"
        agent       = false
    }

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.basic.id}"
  security_groups = ["${aws_security_group.cluster_instance_sg.id}"]
  count = "${var.worker_counter}"

  subnet_id = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  source_dest_check = false
 
  provisioner "file" {
    source      = "./install_docker.sh"
    destination = "/tmp/install_docker.sh"
   }

   provisioner "remote-exec" {
     inline = [
      "sudo chmod +x /tmp/install_docker.sh",
      "sudo /tmp/install_docker.sh"
    ]
   }

  provisioner "file" {
    content     = "ami used: ${self.ami}"
    destination = "/tmp/file.log"
  }

  tags {
      role = "worker"
  }

}

resource "aws_instance" "rancher_general" {
  connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("./ssh_keys/id_rsa")}"
        timeout     = "1m"
        agent       = false
    }

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.basic.id}"
  security_groups = ["${aws_security_group.cluster_instance_sg.id}"]
  count = "${var.general_counter}"

  subnet_id = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  source_dest_check = false
 
  provisioner "file" {
    source      = "./install_docker.sh"
    destination = "/tmp/install_docker.sh"
   }

   provisioner "remote-exec" {
     inline = [
      "sudo chmod +x /tmp/install_docker.sh",
      "sudo /tmp/install_docker.sh"
    ]
   }

  provisioner "file" {
    content     = "ami used: ${self.ami}"
    destination = "/tmp/file.log"
  }

  tags {
      role = "controlplane,etcd"
  }

}

resource "null_resource" "example1" {
    triggers {
        worker_instance_ids = "${join(",", aws_instance.rancher_worker.*.id)}"
        general_instance_ids = "${join(",", aws_instance.rancher_general.*.id)}"
    }

    provisioner "local-exec" {
        command = <<EOT
        echo '${file("./templates/rke_base.tpl")}' > ${var.rke_cluster_config} 
        echo '${join("\n", data.template_file.rke_general_node_definition.*.rendered)}' >> ${var.rke_cluster_config} 
        echo '${join("\n", data.template_file.rke_worker_node_definition.*.rendered)}' >> ${var.rke_cluster_config}
        EOT
    }
}
# this defines the outputs rendered by terraform if all is set and done
        

# output "public_dns" {
#   value = ["${aws_instance.rancher_general.*.public_dns}"]
# }
# output "private_ips" {
#   value = ["${aws_instance.rancher_general.*.private_ip}"]
# }


output "public_bastion_dns" {
  value = ["${aws_instance.bastion.*.public_dns}"]
}