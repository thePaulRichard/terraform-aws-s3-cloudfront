terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

data "aws_default_tags" "this" {}

resource "random_id" "this" {
  byte_length = 8
}

locals {
  name = lower(replace(data.aws_default_tags.this.tags.Name, " ", ""))
}

#----IAM----#
#
# CI/CD user
resource "aws_iam_user" "ci_cd" {
  count = var.create_iam ? 1 : 0

  name = aws_s3_bucket.private.id
}

# Access 
resource "aws_iam_access_key" "ci_cd" {
  count = var.create_iam ? 1 : 0

  lifecycle {
    ignore_changes = [pgp_key]
  }
  user    = aws_iam_user.ci_cd[0].name
  pgp_key = var.pgp_key
}

# CI/CD user policy 
resource "aws_iam_user_policy" "ci_cd" {
  count = var.create_iam ? 1 : 0

  name = aws_s3_bucket.private.id
  user = aws_iam_user.ci_cd[0].name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Effect   = "Allow"
        Resource = aws_s3_bucket.private.arn
      },
      {
        Sid = "S3Access"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.private.arn}/*"
      },
      {
        Sid      = "CloudFront"
        Action   = ["cloudfront:CreateInvalidation"]
        Effect   = "Allow"
        Resource = aws_cloudfront_distribution.s3.arn
      },
    ]
  })
}
#----IAM----#

#----S3----#
#
# S3 Bucket
resource "aws_s3_bucket" "private" {
  bucket        = "${local.name}-${random_id.this.hex}"
  force_destroy = var.s3_destroy
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.private.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.private.id

  versioning_configuration {
    status = var.s3_versioning
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.private.bucket

  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

# Block public acess
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow CloudFront access and deny unencrypted objects
resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.private.id
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "CloudFront"
          Effect   = "Allow"
          Action   = "s3:GetObject"
          Resource = "${aws_s3_bucket.private.arn}/*"
          Principal = {
            AWS = aws_cloudfront_origin_access_identity.s3.iam_arn
          }
        },
        {
          Sid       = "DenyIncorrectEncryptionHeader"
          Action    = "s3:PutObject"
          Effect    = "Deny"
          Resource  = "${aws_s3_bucket.private.arn}/*"
          Principal = "*"
          Condition = {
            StringNotEquals = {
              "s3:x-amz-server-side-encryption" = "AES256"
            }
          }
        },
        {
          Sid       = "DenyUnencryptedObjectUploads"
          Effect    = "Deny"
          Action    = "s3:PutObject"
          Resource  = "${aws_s3_bucket.private.arn}/*"
          Principal = "*"
          Condition = {
            Null = {
              "s3:x-amz-server-side-encryption" = "true"
            }
          }
        },
      ]
    }
  )
}
#----S3----#

#----CLOUDFRONT----#
#
resource "aws_cloudfront_origin_access_identity" "s3" {
  comment = "access-identity-${aws_s3_bucket.private.id}.s3.amazonaws.com"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "s3" {
  origin {
    domain_name = aws_s3_bucket.private.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.private.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3.cloudfront_access_identity_path
    }
  }

  aliases             = var.aliases
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.description
  price_class         = var.price_class
  default_root_object = var.default_root_object

  dynamic "logging_config" {
    for_each = length(keys(var.logging_config)) == 0 ? [] : [var.logging_config]

    content {
      bucket          = logging_config.value["bucket"]
      prefix          = lookup(logging_config.value, "prefix", null)
      include_cookies = lookup(logging_config.value, "include_cookies", null)
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.private.id

    # This is id for SecurityHeadersPolicy copied from https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-response-headers-policies.html
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"

    forwarded_values {
      query_string = false

      headers = [
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "Origin",
      ]

      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    dynamic "geo_restriction" {
      for_each = [var.geo_restriction]

      content {
        restriction_type = lookup(geo_restriction.value, "restriction_type", "none")
        locations        = lookup(geo_restriction.value, "locations", [])
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn            = lookup(var.viewer_certificate, "acm_certificate_arn", null)
    cloudfront_default_certificate = lookup(var.viewer_certificate, "cloudfront_default_certificate", null)
    iam_certificate_id             = lookup(var.viewer_certificate, "iam_certificate_id", null)

    minimum_protocol_version = lookup(var.viewer_certificate, "minimum_protocol_version", "TLSv1")
    ssl_support_method       = lookup(var.viewer_certificate, "ssl_support_method", null)
  }
}
#----CLOUDFRONT----#
