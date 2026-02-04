# S3 Data Lake Module
# This is reusable infrastructure code

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Random suffix for unique bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Create multiple S3 buckets
resource "aws_s3_bucket" "data_buckets" {
  for_each = toset(var.bucket_names)

  bucket = "${var.environment}-${var.project_name}-${each.value}-${random_string.suffix.result}"

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-${each.value}"
      Environment = var.environment
      BucketType  = each.value
    }
  )
}

# Enable versioning
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  for_each = var.enable_versioning ? aws_s3_bucket.data_buckets : {}

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  for_each = aws_s3_bucket.data_buckets

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# # Lifecycle policies for cost optimization
# resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
#   for_each = var.lifecycle_rules

#   bucket = aws_s3_bucket.data_buckets[each.key].id

#   rule {
#     id     = "lifecycle-rule-${each.key}"
#     status = each.value.enabled ? "Enabled" : "Disabled"

#     # Transition to cheaper storage classes
#     dynamic "transition" {
#       for_each = each.value.transitions
#       content {
#         days          = transition.value.days
#         storage_class = transition.value.storage_class
#       }
#     }

#     # Delete after retention period
#     dynamic "expiration" {
#       for_each = each.value.expiration_days != null ? [1] : []
#       content {
#         days = each.value.expiration_days
#       }
#     }
#   }
# }

# Lifecycle policies for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  for_each = var.lifecycle_rules

  bucket = aws_s3_bucket.data_buckets[each.key].id

  rule {
    id     = "lifecycle-rule-${each.key}"
    status = each.value.enabled ? "Enabled" : "Disabled"

    # Apply to all objects in the bucket
    filter {}

    # Transition to cheaper storage classes
    dynamic "transition" {
      for_each = each.value.transitions
      content {
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }

    # Delete after retention period
    dynamic "expiration" {
      for_each = each.value.expiration_days != null ? [1] : []
      content {
        days = each.value.expiration_days
      }
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
  for_each = aws_s3_bucket.data_buckets

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}