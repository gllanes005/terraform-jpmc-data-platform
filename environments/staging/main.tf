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
  
  environment        = var.environment
  project_name       = var.project_name
  bucket_names       = var.bucket_names
  enable_versioning  = var.enable_versioning
  common_tags        = var.common_tags
  lifecycle_rules    = var.lifecycle_rules 
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  environment             = var.environment
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  availability_zones      = var.availability_zones
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  enable_nat_gateway      = var.enable_nat_gateway
  enable_flow_logs        = var.enable_flow_logs
  flow_logs_retention_days = var.flow_logs_retention_days
  common_tags             = var.common_tags
}

# Glue ETL Module
module "glue" {
  source = "../../modules/glue"
  
  project_name = var.project_name
  environment  = var.environment
  common_tags  = var.common_tags
  
  # Pass in the data lake buckets from the S3 module
  data_lake_buckets = module.data_lake.buckets
  
  worker_type        = "G.2X"     # ← Change from G.1X
  number_of_workers  = 5          # ← Change from 2
  max_retries        = 2          # ← Change from 1
  job_timeout        = 120        # ← Change from 60
  log_retention_days = 30         # ← Change from 7
    
  # Crawler schedule disabled for dev (run manually)
  crawler_schedule = null
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