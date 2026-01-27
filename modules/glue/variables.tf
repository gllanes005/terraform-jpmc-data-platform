# modules/glue/variables.tf
# Variables for Glue ETL module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "data_lake_buckets" {
  description = "Map of data lake S3 buckets with their ARNs and IDs"
  type = map(object({
    id  = string
    arn = string
  }))
}

variable "crawler_schedule" {
  description = "Cron expression for crawler schedule (leave null to disable)"
  type        = string
  default     = null
}

variable "worker_type" {
  description = "The type of predefined worker that is allocated when a job runs"
  type        = string
  default     = "G.1X"
  
  validation {
    condition     = contains(["Standard", "G.1X", "G.2X", "G.025X", "G.4X", "G.8X"], var.worker_type)
    error_message = "Worker type must be one of: Standard, G.1X, G.2X, G.025X, G.4X, G.8X"
  }
}

variable "number_of_workers" {
  description = "The number of workers to allocate when this job runs"
  type        = number
  default     = 2
  
  validation {
    condition     = var.number_of_workers >= 2 && var.number_of_workers <= 100
    error_message = "Number of workers must be between 2 and 100"
  }
}

variable "max_retries" {
  description = "Maximum number of times to retry this job if it fails"
  type        = number
  default     = 1
}

variable "job_timeout" {
  description = "Job timeout in minutes"
  type        = number
  default     = 60
}

variable "max_concurrent_runs" {
  description = "Maximum number of concurrent runs allowed for the job"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 7
}