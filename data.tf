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
      public_dns = "${aws_instance.rancher_general.*.private_dns[count.index]}"
      internal_address = "${aws_instance.rancher_general.*.private_ip[count.index]}"
      role = "${aws_instance.rancher_general.*.tags.role[count.index]}"
   }
}

data "template_file" "rke_worker_node_definition" {
    count    = "${var.worker_counter}"
    template = "${file("./templates/rke_node.tpl")}"
    vars {
      public_dns = "${aws_instance.rancher_worker.*.private_dns[count.index]}"
      internal_address = "${aws_instance.rancher_worker.*.private_ip[count.index]}"
      role = "${aws_instance.rancher_worker.*.tags.role[count.index]}"
   }
}


