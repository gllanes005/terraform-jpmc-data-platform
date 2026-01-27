variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "bucket_names" {
  description = "List of bucket types to create"
  type        = list(string)
}

variable "enable_versioning" {
  description = "Enable versioning on buckets"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for S3 buckets"
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