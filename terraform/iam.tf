# CI/CD user
resource "aws_iam_user" "s3" {
  name = aws_s3_bucket.b.id
}

# CI/CD user policy
resource "aws_iam_user_policy" "s3" {
  name = aws_s3_bucket.b.id
  user = aws_iam_user.s3.name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
        Effect   = "Allow"
        Resource = aws_s3_bucket.b.arn
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
        Resource = "${aws_s3_bucket.b.arn}/*"
      },
      {
        Sid      = "CloudFront"
        Action   = ["cloudfront:CreateInvalidation"]
        Effect   = "Allow"
        Resource = aws_cloudfront_distribution.s3_distribution.arn
      },
    ]
  })
}
