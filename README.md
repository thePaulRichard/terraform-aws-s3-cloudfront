# AWS S3 CloudFront Terraform module

Terraform module which creates an S3 private bucket with encryption (SSE-S3) behind a CloudFront, also creates an IAM user with an encrypted Access Key (PGP) to use in CI/CD ([.gitlab-ci.yml](.gitlab-cy.yml)).

*The use of **default_tags** inside providers it's **not** optional. But only **Name** is required to name the bucket.

## GPG

Execute the script [gpg.sh](gpg.sh) to create your gpg key for use with the IAM user.

## Usage 

```hcl
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
}

module "s3_cloudfront" {
  source = "git@github.com:thePaulRichard/terraform-s3-cloudfront.git"

  description = "My S3-CloudFront"
}
```

## Usage with Route53 DNS, ACM

```hcl
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
}

locals {
  domain_name = "example.com"
  subdomain   = "mycdn"
}

data "aws_route53_zone" "dev" {
  name     = local.domain_name
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  domain_name  = "${local.subdomain}.${local.domain_name}"
  zone_id      = data.aws_route53_zone.lab.zone_id

  wait_for_validation = true
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

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["${local.subdomain}.${local.domain_name}"]
      max_age_seconds = 3000
    }
  ]
}

```

## Examples

- [Complete example with Route53 in AWS management account](examples/complete)
