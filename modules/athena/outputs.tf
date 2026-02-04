output "workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}

output "workgroup_id" {
  description = "ID of the Athena workgroup"
  value       = aws_athena_workgroup.main.id
}

output "query_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = aws_s3_bucket.query_results.id
}

output "query_results_bucket_arn" {
  description = "ARN of the query results bucket"
  value       = aws_s3_bucket.query_results.arn
}

output "data_catalog_name" {
  description = "Name of the Athena data catalog"
  value       = aws_athena_data_catalog.glue_catalog.name
}

output "saved_queries" {
  description = "Map of saved query names and IDs"
  value = {
    top_customers     = aws_athena_named_query.top_customers.id
    orders_by_status  = aws_athena_named_query.orders_by_status.id
    recent_orders     = aws_athena_named_query.recent_orders.id
    category_analysis = aws_athena_named_query.category_analysis.id
  }
}