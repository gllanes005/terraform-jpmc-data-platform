environment        = "staging"
project_name       = "data-platform"
aws_region         = "us-east-1"
enable_versioning  = true

bucket_names = [
  "raw",
  "processed",
  "curated",
  "archive"
]

common_tags = {
  Owner      = "Gabriel"
  CostCenter = "Engineering"
  Team       = "Data"
}

# Lifecycle policies - moderate for staging
lifecycle_rules = {
  raw = {
    enabled = true
    transitions = [
      {
        days          = 60
        storage_class = "INTELLIGENT_TIERING"
      },
      {
        days          = 180
        storage_class = "GLACIER"
      }
    ]
    expiration_days = 365
  }
  processed = {
    enabled = true
    transitions = [
      {
        days          = 90
        storage_class = "INTELLIGENT_TIERING"
      },
      {
        days          = 270
        storage_class = "GLACIER"
      }
    ]
    expiration_days = 730  # 2 years
  }
  curated = {
    enabled = true
    transitions = [
      {
        days          = 180
        storage_class = "INTELLIGENT_TIERING"
      }
    ]
    expiration_days = null  # Never expire
  }
  archive = {
    enabled = true
    transitions = [
      {
        days          = 1  # Move to Glacier immediately
        storage_class = "GLACIER"
      }
    ]
    expiration_days = null
  }
}


# VPC Configuration - Dev (minimal NAT for cost savings)
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Public subnets: 10.1.1.0/24, 10.1.2.0/24
public_subnet_cidrs = [
  "10.1.1.0/24",
  "10.1.2.0/24"
]

# Private subnets: 10.1.11.0/24, 10.1.12.0/24
private_subnet_cidrs = [
  "10.1.11.0/24",
  "10.1.12.0/24"
]

enable_nat_gateway       = true   # Need NAT for private subnet internet access
enable_flow_logs         = true  # Enable in staging for testing
flow_logs_retention_days = 7