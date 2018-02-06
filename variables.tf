# keys must be set in your environment and then passed to terraform using the -vars option
variable "aws_access_key" {
  default = ""
}

# keys must be set in your environment and then passed to terraform using the -vars option
variable "aws_secret_key" {
  default = ""
}

# we are using an european region ofcourse
variable "aws_region" {
  default = "eu-central-1"
}

variable "worker_counter" {
  default = 2
}
variable "general_counter" {
  default = 2
}

variable "rke_cluster_config" {
    default = "kube/cluster_test.yml"
}
