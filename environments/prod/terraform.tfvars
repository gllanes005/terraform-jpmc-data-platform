environment       = "prod"
project_name      = "data-platform"
aws_region        = "us-east-1"
enable_versioning = true

bucket_names = [
  "raw",
  "processed",
  "curated",
  "archive",
  "backup"
]

common_tags = {
  Owner      = "Gabriel"
  CostCenter = "Engineering"
  Team       = "Data"
}

# Lifecycle policies - long retention for prod (compliance)
lifecycle_rules = {
  raw = {
    enabled = true
    transitions = [
      {
        days          = 90
        storage_class = "INTELLIGENT_TIERING"
      },
      {
        days          = 365
        storage_class = "GLACIER"
      },
      {
        days          = 730 # 2 years
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    expiration_days = 2555 # 7 years (typical compliance)
  }
  processed = {
    enabled = true
    transitions = [
      {
        days          = 180
        storage_class = "INTELLIGENT_TIERING"
      },
      {
        days          = 730
        storage_class = "GLACIER"
      }
    ]
    expiration_days = 2555
  }
  curated = {
    enabled = true
    transitions = [
      {
        days          = 365
        storage_class = "INTELLIGENT_TIERING"
      }
    ]
    expiration_days = null # Keep forever
  }
  archive = {
    enabled = true
    transitions = [
      {
        days          = 30
        storage_class = "GLACIER"
      },
      {
        days          = 365
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    expiration_days = null # Keep forever
  }
  backup = {
    enabled = true
    transitions = [
      {
        days          = 7 # Quick move to Glacier
        storage_class = "GLACIER"
      },
      {
        days          = 100
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    expiration_days = 2555 # 7 years
  }
}

# VPC Configuration - Dev (minimal NAT for cost savings)
vpc_cidr           = "10.2.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]

# Public subnets: 10.2.1.0/24, 10.2.2.0/24
public_subnet_cidrs = [
  "10.2.1.0/24",
  "10.2.2.0/24"
]

# Private subnets: 10.2.11.0/24, 10.2.12.0/24
private_subnet_cidrs = [
  "10.2.11.0/24",
  "10.2.12.0/24"
]

enable_nat_gateway       = true # Need NAT for private subnet internet access
enable_flow_logs         = true # Enable in prod for testing
flow_logs_retention_days = 30