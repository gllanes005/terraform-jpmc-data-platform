variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "bucket_names" {
  description = "List of bucket types"
  type        = list(string)
}

variable "enable_versioning" {
  description = "Enable bucket versioning"
  type        = bool
}

variable "common_tags" {
  description = "Common resource tags"
  type        = map(string)
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for buckets"
  type = map(object({
    enabled = bool
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days = optional(number, null)
  }))
  default = {}
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention days"
  type        = number
  default     = 7
}