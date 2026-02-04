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

variable "glue_database_name" {
  description = "Name of the Glue database to query"
  type        = string
}

variable "query_results_retention_days" {
  description = "Number of days to retain Athena query results"
  type        = number
  default     = 30
}

variable "bytes_scanned_cutoff_per_query" {
  description = "Maximum bytes scanned per query (cost control). Set to 0 to disable."
  type        = number
  default     = 10737418240 # 10 GB default
}