# A workaround to create a list of cidrs from  a list of waf ip_list_descriptor maps

variable wafs {
    type = "list"
    default = []
}

resource "null_resource" "ipv4" {
    count = "${length(var.wafs)}"

    triggers {

        cidr = "${
        lookup(var.wafs[count.index], "type") == "IPV4"
        ? lookup(var.wafs[count.index], "value")
        : ""
        }"
    }
}

output "cidr" {
    value = ["${compact(null_resource.ipv4.*.triggers.cidr)}"]
}

output "waf" {
    value = ["${var.wafs}"]
}