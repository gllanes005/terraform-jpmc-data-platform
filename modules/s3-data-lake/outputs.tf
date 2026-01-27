output "bucket_ids" {
  description = "Map of bucket names to IDs"
  value       = { for k, v in aws_s3_bucket.data_buckets : k => v.id }
}

output "bucket_arns" {
  description = "Map of bucket names to ARNs"
  value       = { for k, v in aws_s3_bucket.data_buckets : k => v.arn }
}

output "bucket_regional_domain_names" {
  description = "Map of bucket names to regional domain names"
  value       = { for k, v in aws_s3_bucket.data_buckets : k => v.bucket_regional_domain_name }
}

# Add this new output for Glue module
output "buckets" {
  description = "Map of bucket names to bucket objects with id and arn"
  value = {
    for k, v in aws_s3_bucket.data_buckets : k => {
      id  = v.id
      arn = v.arn
    }
  }
}