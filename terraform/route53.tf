data "aws_route53_zone" "this" {
  provider     = aws.route53 #AWS account of the domain
  name         = local.domain_name
  private_zone = false
}

# CloudFront record
resource "aws_route53_record" "cloudfront" {
  provider = aws.route53 #AWS account of the domain

  zone_id = data.aws_route53_zone.this.zone_id
  name    = "${local.name}.${local.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_cloudfront_distribution.s3_distribution.domain_name]
}

# ACM record
resource "aws_acm_certificate" "this" {
  domain_name       = "${local.name}.${local.domain_name}"
  validation_method = "DNS"
}

resource "aws_route53_record" "acm" {
  provider = aws.route53 #AWS account of the domain
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.acm : record.fqdn]
}