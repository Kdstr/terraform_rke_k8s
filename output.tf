output "public_dns" {
  value = ["${aws_instance.rancher_general.*.public_dns}", "${aws_instance.rancher_worker.*.public_dns}"]
}
# output "private_ips" {
#   value = ["${aws_instance.rancher_general.*.private_ip}"]
# }


output "public_bastion_dns" {
  value = ["${aws_instance.bastion.*.public_dns}"]
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