# modules/glue/outputs.tf
# Outputs for Glue ETL module

output "database_name" {
  description = "Name of the Glue catalog database"
  value       = aws_glue_catalog_database.main.name
}

output "database_id" {
  description = "ID of the Glue catalog database"
  value       = aws_glue_catalog_database.main.id
}

output "glue_role_arn" {
  description = "ARN of the IAM role used by Glue"
  value       = aws_iam_role.glue_service_role.arn
}

output "glue_role_name" {
  description = "Name of the IAM role used by Glue"
  value       = aws_iam_role.glue_service_role.name
}

output "scripts_bucket_name" {
  description = "Name of the S3 bucket containing Glue scripts"
  value       = aws_s3_bucket.scripts.id
}

output "scripts_bucket_arn" {
  description = "ARN of the S3 bucket containing Glue scripts"
  value       = aws_s3_bucket.scripts.arn
}

output "raw_crawler_name" {
  description = "Name of the raw data crawler"
  value       = aws_glue_crawler.raw_data_crawler.name
}

output "processed_crawler_name" {
  description = "Name of the processed data crawler"
  value       = aws_glue_crawler.processed_data_crawler.name
}

output "raw_to_processed_job_name" {
  description = "Name of the raw to processed ETL job"
  value       = aws_glue_job.raw_to_processed.name
}

output "processed_to_curated_job_name" {
  description = "Name of the processed to curated ETL job"
  value       = aws_glue_job.processed_to_curated.name
}

output "all_job_names" {
  description = "List of all Glue job names"
  value = [
    aws_glue_job.raw_to_processed.name,
    aws_glue_job.processed_to_curated.name
  ]
}

output "all_crawler_names" {
  description = "List of all Glue crawler names"
  value = [
    aws_glue_crawler.raw_data_crawler.name,
    aws_glue_crawler.processed_data_crawler.name
  ]
}