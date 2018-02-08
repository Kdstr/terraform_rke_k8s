resource "aws_security_group" "cluster_instance_sg" {
  name        = "Rancher-Instances"
  description = "Rules for connected Rancher host machines. These are the hosts that run containers placed on the cluster."
  vpc_id      = "${module.vpc.vpc_id}"

   // kubernetes specific ports
  ingress {
      from_port = 6443
      to_port   = 6443
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
      from_port = 2379
      to_port   = 2380
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    self      = true
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
