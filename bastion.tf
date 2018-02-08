resource "aws_instance" "bastion" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.basic.id}"
  security_groups = ["${aws_security_group.cluster_instance_sg.id}"]
  subnet_id = "${module.vpc.public_subnets[0]}"
  associate_public_ip_address = true
  source_dest_check = false
  
  
#   provisioner "remote-exec" {
#         inline = [
#         "echo '${file("./templates/rke_base.tpl")}' > /home/ubuntu/cluster.yaml", 
#         "echo '${join("\n", data.template_file.rke_general_node_definition.*.rendered)}' >>  /home/ubuntu/cluster.yaml",
#         "echo '${join("\n", data.template_file.rke_worker_node_definition.*.rendered)}' >>  /home/ubuntu/cluster.yaml"
#         ]
#    }

#     provisioner "remote-exec" {
#      inline = [
#       "sudo chmod +x /tmp/install_rke.sh",
#       "sudo /tmp/install_rke.sh"
#     ]
#    }

  
#    provisioner "remote-exec" {
#      inline = [
#       "/home/ubuntu/rke up --config /home/ubuntu/cluster.yaml"
#     ]
#    }


  tags {
      role = "bastion"
  }

  provisioner "local-exec" {
  command = "sleep 15"
}

}
resource "null_resource" "run_rke" {

provisioner "file" {
    source      = "./scripts/install_rke.sh"
    destination = "/tmp/install_rke.sh"
   }

provisioner "file" {
    source      = "./scripts/install_kubectl.sh"
    destination = "/tmp/install_kubectl.sh"
   }
  provisioner "file" {
    source      = "./ssh_keys"
    destination = "/home/ubuntu/ssh_keys"
   }

provisioner "remote-exec" {
  inline = [
        "echo '${file("./templates/rke_base.tpl")}' > /home/ubuntu/cluster.yaml", 
        "echo '${join("\n", data.template_file.rke_general_node_definition.*.rendered)}' >>  /home/ubuntu/cluster.yaml",
        "echo '${join("\n", data.template_file.rke_worker_node_definition.*.rendered)}' >>  /home/ubuntu/cluster.yaml",
        "sudo chmod +x /tmp/install_rke.sh",
        "sudo /tmp/install_rke.sh",
        "sudo chmod +x /tmp/install_kubectl.sh",
        "sudo /tmp/install_kubectl.sh",
        "/home/ubuntu/rke up --config /home/ubuntu/cluster.yaml",
        "mkdir /home/ubuntu/kube",
        "mv /home/ubuntu/kube_config_cluster.yaml /home/ubuntu/kube/config"
  ]
}
  connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = "${file("./ssh_keys/id_rsa")}"
        timeout     = "1m"
        agent       = false
        host        = "${aws_instance.bastion.public_ip}"
    }
  

}
