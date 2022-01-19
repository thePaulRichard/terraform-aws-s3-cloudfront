# S3 Bucket
resource "aws_s3_bucket" "b" {
  bucket = "${local.name}-${random_id.this.hex}"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${local.name}.${local.domain_name}"]
    max_age_seconds = 3000
  }
}

# Block public acess
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.b.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow CloudFront access and deny unencrypted objects
resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.b.id
  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "CloudFront"
          Effect   = "Allow"
          Action   = "s3:GetObject"
          Resource = "${aws_s3_bucket.b.arn}/*"
          Principal = {
            AWS = aws_cloudfront_origin_access_identity.s3.iam_arn
          }
        },
        {
          Sid       = "DenyIncorrectEncryptionHeader"
          Action    = "s3:PutObject"
          Effect    = "Deny"
          Resource  = "${aws_s3_bucket.b.arn}/*"
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
          Resource  = "${aws_s3_bucket.b.arn}/*"
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