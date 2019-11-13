###############################################################################
# CDN Firewall Logs
###############################################################################

resource "aws_s3_bucket" "waf_logs" {
  bucket = "${var.cdn_base_instance_name}-waf-logs"
  acl    = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket = "${aws_s3_bucket.waf_logs.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "firehose_role" {
  name = "${var.cdn_base_instance_name}-firehose-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs_stream" {
  name        = "aws-waf-logs-${var.cdn_base_instance_name}-firehose-stream"
  destination = "s3"

  s3_configuration {
    role_arn   = "${aws_iam_role.firehose_role.arn}"
    bucket_arn = "${aws_s3_bucket.waf_logs.arn}"
  }
}
