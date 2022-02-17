output "s3_bucket_id" {
  description = "The S3 Bucket ID."
  value       = aws_s3_bucket.private.id
}

output "iam_access_key" {
  description = "The IAM access key id."
  value       = element(concat(aws_iam_access_key.ci_cd.*.id, [""]), 0)
}

output "iam_secret" {
  description = "The IAM access key secret."
  value       = element(concat(aws_iam_access_key.ci_cd.*.encrypted_secret, [""]), 0)
}

output "cloudfront_id" {
  description = "The identifier for the distribution."
  value       = element(concat(aws_cloudfront_distribution.s3.*.id, [""]), 0)
}

output "cloudfront_domain_name" {
  description = "The domain name corresponding to the distribution."
  value       = element(concat(aws_cloudfront_distribution.s3.*.domain_name, [""]), 0)
}
