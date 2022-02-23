# AWS S3 CloudFront Terraform module

Terraform module, which creates an S3 private bucket with encryption (SSE-S3) behind a CloudFront, also makes an IAM user with an encrypted Access Key (PGP) for use with your CI/CD ([.gitlab-ci.yml](examples/complete/.gitlab-ci.yml)).

*The use of **default_tags** inside providers it's **not** optional. But only **Name** is required to name the bucket.

## GitLab CI example

https://gitlab.com/paulrichard/aws-s3-bucket-sync.git

This repo syncs all data in the **s3bucket** folder to the s3 bucket and make a cache invalidation on the **CloudFront**.

## GPG

Execute the script [gpg.sh](gpg.sh) to create your gpg key for use with the IAM user (will make the key file in the folder).

After the **terraform apply** command, use the following command to display the IAM secret key:

```
terraform output iam_secret | base64 --decode --ignore-garbage | gpg --decrypt 
```

To re-create the IAM credentials, use:

```
terraform taint module.s3_cloudfront.aws_iam_access_key.ci_cd[0]

terraform apply
```

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
  source = "git@github.com:thePaulRichard/terraform-aws-s3-cloudfront.git"
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
  source = "git@github.com:thePaulRichard/terraform-aws-s3-cloudfront.git"

  pgp_key = filebase64("./key")

  comment = "My S3-CloudFront"
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

```

## Examples

- [Complete example with Route53 in AWS management account](examples/complete)

## Inputs

| Name | Description | Type | Default |	Required |
| --- | --- | --- | --- | --- |
| comment | Any description you want to include about the CloudFront resource. | `string` | `null` | no |
| aliases | Extra CNAMEs (alternate domain names), if any, for this distribution. | `list(string)` | `null` | no |
| default_root_object | The object that you want CloudFront to return (for example, index.html) when an end-user requests the root URL. | `string` | `null` | no |
| price_class | The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100. | `string` | `null` | no |
| geo_restriction | The restriction configuration for this distribution (geo_restrictions). | `any` | `null` | no |
| logging_config | The logging configuration that controls how logs are written to your distribution (maximum one). | `any` | `null` | no |
| viewer_certificate | The SSL configuration for this distribution. | `any` | `null` | no |
| create_iam | Whether to create the IAM user and Access Key. | `bool` | `false` | no |
| pgp_key | The PGP public key that is used to encrypt the IAM access key. | `string` | `keybase:test` | no |
| s3_destroy | Force all objects to be deleted from the bucket so that the bucket can be destroyed without error. | `bool` | `false` | no |
| s3_versioning | Wether to use versioning in the bucket. | `string` | `Suspended` | yes |

## Outputs

| Name | Description |
| --- | --- |
| s3_bucket_id | The S3 Bucket ID. |
| iam_access_key | The IAM access key id. |
| iam_secret | The IAM access key secret. |
| cloudfront_id | The identifier for the distribution. |
| cloudfront_domain_name | The domain name corresponding to the distribution. |
