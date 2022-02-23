output "cloudfront_id" {
  description = "The identifier for the distribution."
  value       = module.s3_cloudfront.cloudfront_id
}

output "s3_bucket_id" {
  description = "The identifier for the S3 bucket"
  value       = module.s3_cloudfront.s3_bucket_id
}

output "cloudfront_domain_name" {
  description = "The domain name corresponding to the distribution."
  value       = module.s3_cloudfront.cloudfront_domain_name
}

output "distinct_domain_names" {
  description = "List of distinct domains names used for the validation."
  value       = module.acm.distinct_domain_names
}

output "iam_access_key" {
  description = "The IAM access key secret"
  value       = module.s3_cloudfront.iam_access_key
}

output "iam_secret" {
  description = "The IAM access key secret"
  value       = module.s3_cloudfront.iam_secret
}