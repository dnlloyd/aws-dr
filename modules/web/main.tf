provider "aws" {
  alias = "acm"
  region = "us-east-1"
}

variable "domain" {}

variable "site_dns" {}

data "aws_route53_zone" "main" {
  name = var.domain
}

###################################################
# ACM

resource "aws_acm_certificate" "main" {
  provider = aws.acm

  domain_name = var.site_dns
  validation_method = "DNS"
  subject_alternative_names = ["*.${var.site_dns}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  provider = aws.acm
  
  certificate_arn = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

###################################################
# S3

resource "aws_s3_bucket" "web" {
  bucket_prefix = "fhcdan-web-content"
}

resource "aws_s3_bucket_public_access_block" "web" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_identity" "web" {}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id = "WEB"
    Statement = [
      {
        Sid = "S3Identity"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.web.iam_arn
        }
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.web.arn}/*"
      }
    ] 
  })
}

###################################################
# CloudFront

resource "aws_cloudfront_distribution" "frontend" {
  enabled = true
  default_root_object = "index.html"

  aliases = [data.aws_route53_zone.main.name]

  price_class = "PriceClass_200"

  origin {
    domain_name = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id   = "s3_web"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.web.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3_web"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 3600
  }

  viewer_certificate {
    acm_certificate_arn            = aws_acm_certificate_validation.main.certificate_arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_caching_min_ttl = "300"
    error_code            = "403"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = "31536000"
    error_code            = "404"
    response_code         = "200"
    response_page_path    = "/index.html"
  }
}

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name = aws_cloudfront_distribution.frontend.domain_name
    zone_id = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}
