###############################################################################
# CDN
###############################################################################

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "CDN Origin Access Identity"
}


# resource "aws_s3_account_public_access_block" "s3_account_public_access_block" {
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }


data "aws_iam_policy_document" "aws_s3_bucket_policy" {
  statement {
    sid    = "1"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.cdn_base_instance_name}/*"]
  }
}

resource "aws_s3_bucket" "static_assets" {
  bucket = "${var.cdn_base_instance_name}"
  acl    = "private"

  force_destroy = true

  policy = "${data.aws_iam_policy_document.aws_s3_bucket_policy.json}"

  tags = {
    Name = "${var.cdn_base_instance_name}"
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = "${aws_s3_bucket.static_assets.id}"

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket" "s3_logs" {
  bucket = "${var.cdn_base_instance_name}-s3-logs"
  acl    = "private"

  force_destroy = true

  tags = {
    Name = "${var.cdn_base_instance_name}-s3-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_logs" {
  bucket = "${aws_s3_bucket.s3_logs.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${aws_s3_bucket.static_assets.bucket_regional_domain_name}"
    origin_id   = "${var.cdn_base_instance_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = ""
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.s3_logs.bucket_regional_domain_name}"
    prefix          = ""
  }

  aliases = []

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.cdn_base_instance_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "${var.cdn_base_instance_id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.cdn_base_instance_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "preproduction"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
