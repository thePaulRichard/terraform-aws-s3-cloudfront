provider "aws" {
  region  = "us-east-1"
  profile = "aws-dev"

  default_tags {
    tags = {
      Name        = "Paul Richard Test"
      Environment = "DEV"
      Owner       = "Paul Richard"
      Project     = "My Project"
    }
  }

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}

provider "aws" {
  region  = "us-east-1"
  profile = "aws-mgmt"
  alias   = "mgmt"
}

locals {
  domain_name = "rdeai-lab.net"
  zone_id     = data.aws_route53_zone.mgmt.zone_id
  subdomain   = "mycdn"
}

data "aws_route53_zone" "mgmt" {
  provider = aws.mgmt
  name     = local.domain_name
}

resource "aws_route53_record" "cloudfront" {
  provider = aws.mgmt

  zone_id = local.zone_id
  name    = local.subdomain
  type    = "CNAME"
  records = [module.s3_cloudfront.cloudfront_domain_name]
  ttl     = 300
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"


  domain_name = "${local.subdomain}.${local.domain_name}"
  zone_id     = local.zone_id

  create_route53_records  = false
  validation_record_fqdns = aws_route53_record.validation.*.fqdn
}

resource "aws_route53_record" "validation" {
  provider = aws.mgmt

  count = length(module.acm.distinct_domain_names)

  zone_id = local.zone_id
  name    = element(module.acm.validation_domains, count.index)["resource_record_name"]
  type    = element(module.acm.validation_domains, count.index)["resource_record_type"]
  records = [replace(element(module.acm.validation_domains, count.index)["resource_record_value"], "/.$/", "")]
  ttl     = 60
}

module "s3_cloudfront" {
  source = "../../"

  # To decrypt the iam_secret:
  # terraform output iam_secret | base64 --decode | gpg -d
  pgp_key = filebase64("./key")

  description = "My S3-CloudFront"
  aliases     = ["${local.subdomain}.${local.domain_name}"]

  viewer_certificate = {
    acm_certificate_arn = module.acm.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = module.s3_cloudfront.s3_bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${local.subdomain}.${local.domain_name}"]
    max_age_seconds = 3000
  }
}