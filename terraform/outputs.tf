output "bucket" {
  value       = aws_s3_bucket.b.id
  description = "S3 Bucket ID"
}

output "cloudfront" {
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "CloudFront DNS"
}

output "url" {
  value       = aws_route53_record.cloudfront.fqdn
  description = "url of the site"
}

output "iam_user" {
  value       = aws_iam_user.s3.name
  description = "The IAM user"
}
