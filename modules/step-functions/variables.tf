variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "raw_crawler_name" {
  description = "Name of the raw data crawler"
  type        = string
}

variable "processed_crawler_name" {
  description = "Name of the processed data crawler"
  type        = string
}

variable "raw_to_processed_job_name" {
  description = "Name of the raw to processed Glue job"
  type        = string
}

variable "processed_to_curated_job_name" {
  description = "Name of the processed to curated Glue job"
  type        = string
}

variable "notification_email" {
  description = "Email address for pipeline notifications (optional)"
  type        = string
  default     = null
}

variable "schedule_expression" {
  description = "CloudWatch Events schedule expression (e.g., 'cron(0 2 * * ? *)' for daily at 2 AM UTC). Set to null to disable scheduling."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain Step Functions logs"
  type        = number
  default     = 7
}