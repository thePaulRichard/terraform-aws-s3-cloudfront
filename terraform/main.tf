provider "aws" {
  region  = "us-east-1" # CloudFront expects ACM resources in us-east-1 region only
  profile = "aws-dev"   # Default aws provider

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true

  # skip_requesting_account_id should be disabled to generate valid ARN in apigatewayv2_api_execution_arn
  skip_requesting_account_id = false

  default_tags {
    tags = {
      Name        = local.name
      Environment = "Production"
      Owner       = "Paul"
    }
  }
}

provider "aws" {
  alias   = "route53"
  region  = "us-east-1"
  profile = "aws-sys" # Profile for create de DNS record

  default_tags {
    tags = {
      Name        = local.name
      Environment = "Production"
      Owner       = "Paul"
    }
  }
}

locals {
  name         = "s3bucket"
  domain_name  = "example.com" # Domain to expose the CloudFront
  descrition   = "Public data"
  s3_origin_id = "myS3Origin"
}

resource "random_id" "this" {
  byte_length = 8
}