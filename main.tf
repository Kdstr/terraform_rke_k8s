
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}



# configure an aws keypair to use
# keys are used from the ssh_keys folder located in the folder where this .tf file resides in
resource "aws_key_pair" "basic" {
  key_name   = "basic"
  public_key = "${file("./ssh_keys/id_rsa.pub")}"
}





resource "aws_instance" "rancher_worker" {
  connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("./ssh_keys/id_rsa")}"
        timeout     = "1m"
        agent       = false
                bastion_host = "${aws_instance.bastion.public_dns}"

    }

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.basic.id}"
  security_groups = ["${aws_security_group.cluster_instance_sg.id}"]
  count = "${var.worker_counter}"

  subnet_id = "${module.vpc.private_subnets[0]}"
  associate_public_ip_address = false
  source_dest_check = false
 
  provisioner "file" {
    source      = "./scripts/install_docker.sh"
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
        # bastion_key = "${file("./ssh_keys/id_rsa")}"
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
    source      = "./scripts/install_docker.sh"
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


# this defines the outputs rendered by terraform if all is set and done
        

