output "s3_bucket_id" {
  value       = aws_s3_bucket.private.id
  description = "S3 Bucket ID"
}

output "iam_access_key" {
  description = "The IAM access key secret"
  value       = aws_iam_access_key.ci_cd[0].id
}

output "iam_secret" {
  description = "The IAM access key secret"
  value       = aws_iam_access_key.ci_cd[0].encrypted_secret
}

output "cloudfront_id" {
  description = "The identifier for the distribution."
  value       = element(concat(aws_cloudfront_distribution.s3.*.id, [""]), 0)
}

output "cloudfront_domain_name" {
  description = "The domain name corresponding to the distribution."
  value       = element(concat(aws_cloudfront_distribution.s3.*.domain_name, [""]), 0)
}
