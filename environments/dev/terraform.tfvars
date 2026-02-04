environment       = "dev"
project_name      = "data-platform"
aws_region        = "us-east-1"
enable_versioning = false

bucket_names = [
  "raw",
  "processed",
  "curated"
]

common_tags = {
  Owner      = "Gabriel"
  CostCenter = "Engineering"
  Team       = "Data"
}

# Lifecycle policies - aggressive for dev (save money)
lifecycle_rules = {
  raw = {
    enabled = true
    transitions = [
      {
        days          = 30
        storage_class = "GLACIER"
      }
    ]
    expiration_days = 90 # Delete after 90 days
  }
  processed = {
    enabled = true
    transitions = [
      {
        days          = 60
        storage_class = "GLACIER"
      }
    ]
    expiration_days = 180
  }
  curated = {
    enabled = true
    transitions = [
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]
    expiration_days = 365
  }
}

# VPC Configuration - Dev (minimal NAT for cost savings)
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Public subnets: 10.0.1.0/24, 10.0.2.0/24
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

# Private subnets: 10.0.11.0/24, 10.0.12.0/24
private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

enable_nat_gateway       = true  # Need NAT for private subnet internet access
enable_flow_logs         = false # Disable in dev to save costs
flow_logs_retention_days = 7
