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