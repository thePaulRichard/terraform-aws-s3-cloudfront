variable "comment" {
  description = "Any description you want to include about the CloudFront resource."
  type        = string
  default     = null
}

variable "aliases" {
  description = "Extra CNAMEs (alternate domain names), if any, for this distribution."
  type        = list(string)
  default     = null
}

variable "default_root_object" {
  description = "The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL."
  type        = string
  default     = null
}

variable "price_class" {
  description = "The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100."
  type        = string
  default     = null
}

variable "geo_restriction" {
  description = "The restriction configuration for this distribution (geo_restrictions)."
  type        = any
  default     = {}
}

variable "logging_config" {
  description = "The logging configuration that controls how logs are written to your distribution (maximum one)."
  type        = any
  default     = {}
}

variable "viewer_certificate" {
  description = "The SSL configuration for this distribution."
  type        = any
  default = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }
}

variable "create_iam" {
  description = "Whether to create the IAM user and Access Key."
  type        = bool
  default     = false
}

variable "pgp_key" {
  description = "The PGP public key that use to encrypted the IAM access key."
  type        = string
  default     = "keybase:test"
}

variable "s3_destroy" {
  description = "Force all objects to be deleted from the bucket so that the bucket can be destroyed without error."
  type        = bool
  default     = false
}

variable "s3_versioning" {
  description = "Wether to use versioning in the bucket."
  type        = string
  default     = "Suspended"
}
