###############################################################################
# CDN Firewall
###############################################################################

module "ip_whitelist" {
  source = "../ip-whitelist"
  wafs = ["${var.waf_ip_set_descriptors}"]
}

resource "aws_waf_ipset" "ipset1" {
  name = "SIE"

  ip_set_descriptors = ["${module.ip_whitelist.waf}"]

}

resource "aws_waf_rule" "wafrule1" {
  depends_on  = ["aws_waf_ipset.ipset1"]
  name        = "SIE Rule"
  metric_name = "sieIpRule"

  predicates {
    data_id = "${aws_waf_ipset.ipset1.id}"
    negated = false
    type    = "IPMatch"
  }
}


resource "aws_waf_web_acl" "waf_acl" {
  depends_on  = ["aws_waf_ipset.ipset1", "aws_waf_rule.wafrule1"]
  name        = "${var.cdn_base_instance_name}"
  metric_name = "${var.cdn_base_instance_id}"

  default_action {
    type = "BLOCK"
  }

  rules {
    action {
      type = "ALLOW"
    }

    priority = 1
    rule_id  = "${aws_waf_rule.wafrule1.id}"
    type     = "REGULAR"
  }

 
  logging_configuration {
    log_destination = "${aws_kinesis_firehose_delivery_stream.waf_logs_stream.arn}"

    redacted_fields {
      field_to_match {
        type = "URI"
      }

      field_to_match {
        data = "referer"
        type = "HEADER"
      }
    }
  }
}
