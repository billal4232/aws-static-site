# Create s3 bucket
resource "aws_s3_bucket" "main" {
  bucket = "s3-bucket-688600819246"

  tags = {
    Name      = "My bucket"
  }
}
# Make bucket private and block public access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Give cloudfront permission to fetch data from s3 bucket
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "cloudfront-oac"
  description                       = "Allow cloudfront to read data from s3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
#Bucket policy
data "aws_iam_policy_document" "main" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.main.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.main.json
}
#Cloudfront distribution
resource "aws_cloudfront_distribution" "main" {
    enabled = true
    default_root_object = "index.html"
    aliases = ["cv.limonlab.online"]
    depends_on = [aws_acm_certificate_validation.main]
  origin {
    domain_name              = aws_s3_bucket.main.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
    origin_id                = "s3-cv-origin"
  }

  default_cache_behavior {
      
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-cv-origin"
    viewer_protocol_policy = "redirect-to-https"
  
  forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
    ssl_support_method  = "sni-only"
  }
}
# ACM certificate for custom domain
resource "aws_acm_certificate" "main" {
  domain_name       = "cv.limonlab.online"
  validation_method = "DNS"
  provider          = aws.us_east_1

  tags = {
    description = "HTTPS certificate for website"
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}
# Route53 hosted zone
data "aws_route53_zone" "main" {
  name         = "limonlab.online"
  }

# website A record for route53
resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.main.id
  name    = "cv.limonlab.online"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
# Prove to ACM that i own the domain
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}
# Tell terraform to wait untill ACM fully issued the certificate
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
  provider = aws.us_east_1
}


