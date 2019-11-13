provider "aws" {
  region = "us-east-1"
}

locals {
    waf_ip_set_descriptors = [
      { type = "IPV4", value = "128.0.0.0/1"},
  ]
}

variable "cdn_base_instance_id" { type = "string" }

variable "cdn_base_instance_name" { type = "string" }

module "cdn" {
  source = "./modules/cdn"
  waf_ip_set_descriptors = "${local.waf_ip_set_descriptors}"
  cdn_base_instance_id = "${var.cdn_base_instance_id}"
  cdn_base_instance_name = "${var.cdn_base_instance_name}"
}