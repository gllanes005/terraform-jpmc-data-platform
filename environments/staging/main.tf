# Staging Environment Configuration
# Uses the shared s3-data-lake module

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# Call the shared module
module "data_lake" {
  source = "../../modules/s3-data-lake"

  environment       = var.environment
  project_name      = var.project_name
  bucket_names      = var.bucket_names
  enable_versioning = var.enable_versioning
  common_tags       = var.common_tags
  lifecycle_rules   = var.lifecycle_rules
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment              = var.environment
  project_name             = var.project_name
  vpc_cidr                 = var.vpc_cidr
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs     = var.private_subnet_cidrs
  enable_nat_gateway       = var.enable_nat_gateway
  enable_flow_logs         = var.enable_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days
  common_tags              = var.common_tags
}

# Glue ETL Module
module "glue" {
  source = "../../modules/glue"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Pass in the data lake buckets from the S3 module
  data_lake_buckets = module.data_lake.buckets

  worker_type        = "G.2X" # ← Change from G.1X
  number_of_workers  = 5      # ← Change from 2
  max_retries        = 2      # ← Change from 1
  job_timeout        = 120    # ← Change from 60
  log_retention_days = 30     # ← Change from 7

  # Crawler schedule disabled for dev (run manually)
  crawler_schedule = null
}

# Step Functions Orchestration
module "step_functions" {
  source = "../../modules/step-functions"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Pass Glue resource names from the glue module
  raw_crawler_name              = module.glue.raw_crawler_name              // crawler_names[0]  # data-platform-dev-raw-crawler
  processed_crawler_name        = module.glue.processed_crawler_name        // crawler_names[1]  # data-platform-dev-processed-crawler
  raw_to_processed_job_name     = module.glue.raw_to_processed_job_name     # data-platform-dev-raw-to-processed
  processed_to_curated_job_name = module.glue.processed_to_curated_job_name # data-platform-dev-processed-to-curated

  # Optional: Email for notifications (set your email or leave as null)
  notification_email = null # Change to "your.email@example.com" if you want email alerts

  # Optional: Schedule (null = manual execution only)
  # Example: "cron(0 2 * * ? *)" = daily at 2 AM UTC
  schedule_expression = null

  # staging: 30-day log retention
  log_retention_days = 30
}

# Athena for SQL Analytics
module "athena" {
  source = "../../modules/athena"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags

  # Reference the Glue database
  glue_database_name = module.glue.database_name

  # Staging: 30-day query result retention (fast cleanup)
  query_results_retention_days = 30

  # Dev: 10 GB query limit (cost control)
  bytes_scanned_cutoff_per_query = 10737418240 # 10 GB
}

# Outputs
output "bucket_ids" {
  description = "Data lake bucket IDs"
  value       = module.data_lake.bucket_ids
}

output "bucket_arns" {
  description = "Data lake bucket ARNs"
  value       = module.data_lake.bucket_arns
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

# Glue Outputs
output "glue_database_name" {
  description = "Glue catalog database name"
  value       = module.glue.database_name
}

output "glue_scripts_bucket" {
  description = "S3 bucket containing Glue ETL scripts"
  value       = module.glue.scripts_bucket_name
}

output "glue_job_names" {
  description = "List of Glue job names"
  value       = module.glue.all_job_names
}

output "glue_crawler_names" {
  description = "List of Glue crawler names"
  value       = module.glue.all_crawler_names
}

# Step Functions Outputs
output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = module.step_functions.state_machine_arn
}
output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = module.step_functions.state_machine_name
}
output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = module.step_functions.sns_topic_arn
}
output "cloudwatch_log_group" {
  description = "CloudWatch log group for Step Functions"
  value       = module.step_functions.cloudwatch_log_group
}

# Athena outputs
output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = module.athena.workgroup_name
}

output "athena_query_results_bucket" {
  description = "S3 bucket for Athena query results"
  value       = module.athena.query_results_bucket
}

output "athena_saved_queries" {
  description = "Saved Athena queries"
  value       = module.athena.saved_queries
}