# modules/glue/main.tf
# AWS Glue resources for ETL pipeline

# ====================================================================
# Glue Catalog Database
# ====================================================================
resource "aws_glue_catalog_database" "main" {
  name        = "${var.project_name}-${var.environment}-database"
  description = "Glue catalog database for ${var.environment} environment"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-glue-database"
    }
  )
}

# ====================================================================
# IAM Role for Glue Service
# ====================================================================
resource "aws_iam_role" "glue_service_role" {
  name = "${var.project_name}-${var.environment}-glue-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-glue-service-role"
    }
  )
}

# Attach AWS managed policy for Glue service
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom policy for S3 access to data lake buckets
resource "aws_iam_role_policy" "glue_s3_policy" {
  name = "${var.project_name}-${var.environment}-glue-s3-policy"
  role = aws_iam_role.glue_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = concat([
          for bucket in var.data_lake_buckets : "${bucket.arn}/*"
        ],
        ["${aws_s3_bucket.scripts.arn}/*"]  # Add scripts bucket
        )
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = concat([
          for bucket in var.data_lake_buckets : bucket.arn
        ],
        [aws_s3_bucket.scripts.arn]
        )
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:/aws-glue/*"
      }
    ]
  })
}

# Add this AFTER the IAM role section in your glue/main.tf

# ====================================================================
# S3 Bucket for Glue Scripts (if using dedicated bucket)
# ====================================================================
resource "aws_s3_bucket" "scripts" {
  bucket = "${var.project_name}-${var.environment}-glue-scripts-${random_string.scripts_suffix.result}"
  
  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-glue-scripts"
    }
  )
}

resource "random_string" "scripts_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  
  versioning_configuration {
    status = "Enabled"  # Version control for your scripts!
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
  bucket = aws_s3_bucket.scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ====================================================================
# Upload ETL Scripts to S3
# ====================================================================
resource "aws_s3_object" "raw_to_processed_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "scripts/raw_to_processed.py"
  source = "${path.module}/../../scripts/raw_to_processed.py"  # Local file path
  etag   = filemd5("${path.module}/../../scripts/raw_to_processed.py")  # Auto-detect changes
  
  tags = merge(
    var.common_tags,
    {
      Name = "raw-to-processed-script"
    }
  )
}

resource "aws_s3_object" "processed_to_curated_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "scripts/processed_to_curated.py"
  source = "${path.module}/../../scripts/processed_to_curated.py"
  etag   = filemd5("${path.module}/../../scripts/processed_to_curated.py")
  
  tags = merge(
    var.common_tags,
    {
      Name = "processed-to-curated-script"
    }
  )
}


# # Add this AFTER the IAM role section in your glue/main.tf

# # ====================================================================
# # S3 Bucket for Glue Scripts (if using dedicated bucket)
# # ====================================================================
# resource "aws_s3_bucket" "scripts" {
#   bucket = "${var.project_name}-${var.environment}-glue-scripts-${random_string.scripts_suffix.result}"
  
#   tags = merge(
#     var.common_tags,
#     {
#       Name = "${var.project_name}-${var.environment}-glue-scripts"
#     }
#   )
# }

# resource "random_string" "scripts_suffix" {
#   length  = 8
#   special = false
#   upper   = false
# }

# resource "aws_s3_bucket_versioning" "scripts" {
#   bucket = aws_s3_bucket.scripts.id
  
#   versioning_configuration {
#     status = "Enabled"  # Version control for your scripts!
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
#   bucket = aws_s3_bucket.scripts.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# # ====================================================================
# # Upload ETL Scripts to S3
# # ====================================================================
# resource "aws_s3_object" "raw_to_processed_script" {
#   bucket = aws_s3_bucket.scripts.id
#   key    = "scripts/raw_to_processed.py"
#   source = "${path.module}/../../scripts/raw_to_processed.py"  # Local file path
#   etag   = filemd5("${path.module}/../../scripts/raw_to_processed.py")  # Auto-detect changes
  
#   tags = merge(
#     var.common_tags,
#     {
#       Name = "raw-to-processed-script"
#     }
#   )
# }

# resource "aws_s3_object" "processed_to_curated_script" {
#   bucket = aws_s3_bucket.scripts.id
#   key    = "scripts/processed_to_curated.py"
#   source = "${path.module}/../../scripts/processed_to_curated.py"
#   etag   = filemd5("${path.module}/../../scripts/processed_to_curated.py")
  
#   tags = merge(
#     var.common_tags,
#     {
#       Name = "processed-to-curated-script"
#     }
#   )
# }

# ====================================================================
# Glue Crawlers - Auto-discover data schemas
# ====================================================================
resource "aws_glue_crawler" "raw_data_crawler" {
  name          = "${var.project_name}-${var.environment}-raw-crawler"
  role          = aws_iam_role.glue_service_role.arn
  database_name = aws_glue_catalog_database.main.name

  s3_target {
    path = "s3://${var.data_lake_buckets["raw"].id}/"
  }

  schedule = var.crawler_schedule

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-raw-crawler"
    }
  )
}

resource "aws_glue_crawler" "processed_data_crawler" {
  name          = "${var.project_name}-${var.environment}-processed-crawler"
  role          = aws_iam_role.glue_service_role.arn
  database_name = aws_glue_catalog_database.main.name

  s3_target {
    path = "s3://${var.data_lake_buckets["processed"].id}/"
  }

  schedule = var.crawler_schedule

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-processed-crawler"
    }
  )
}

# # ====================================================================
# # Glue ETL Job - Raw to Processed
# # ====================================================================
# Update the raw_to_processed job command block:
resource "aws_glue_job" "raw_to_processed" {
  name     = "${var.project_name}-${var.environment}-raw-to-processed"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/${aws_s3_object.raw_to_processed_script.key}"  # Dynamic reference
    python_version  = "3"
  }
  
  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--TempDir"                          = "s3://${var.data_lake_buckets["raw"].id}/temp/"
    "--SOURCE_BUCKET"                    = var.data_lake_buckets["raw"].id
    "--TARGET_BUCKET"                    = var.data_lake_buckets["processed"].id
    "--DATABASE_NAME"                    = aws_glue_catalog_database.main.name
  }

  max_retries       = var.max_retries
  timeout           = var.job_timeout
  glue_version      = "4.0"
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers

  execution_property {
    max_concurrent_runs = var.max_concurrent_runs
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-raw-to-processed-job"
    }
  )
}

# Update the processed_to_curated job command block:
resource "aws_glue_job" "processed_to_curated" {
  name     = "${var.project_name}-${var.environment}-processed-to-curated"
  role_arn = aws_iam_role.glue_service_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/${aws_s3_object.processed_to_curated_script.key}"
    python_version  = "3"
  }
  
  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--TempDir"                          = "s3://${var.data_lake_buckets["processed"].id}/temp/"
    "--SOURCE_BUCKET"                    = var.data_lake_buckets["processed"].id
    "--TARGET_BUCKET"                    = var.data_lake_buckets["curated"].id
    "--DATABASE_NAME"                    = aws_glue_catalog_database.main.name
  }

  max_retries       = var.max_retries
  timeout           = var.job_timeout
  glue_version      = "4.0"
  worker_type       = var.worker_type
  number_of_workers = var.number_of_workers

  execution_property {
    max_concurrent_runs = var.max_concurrent_runs
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-processed-to-curated-job"
    }
  )
}

# # ====================================================================
# # Glue ETL Job - Raw to Processed
# # ====================================================================
# resource "aws_glue_job" "raw_to_processed" {
#   name     = "${var.project_name}-${var.environment}-raw-to-processed"
#   role_arn = aws_iam_role.glue_service_role.arn

#   command {
#     name            = "glueetl"
#     script_location = "s3://${var.scripts_bucket}/${var.raw_to_processed_script}"
#     python_version  = "3"
#   }

#   default_arguments = {
#     "--job-language"                     = "python"
#     "--job-bookmark-option"              = "job-bookmark-enable"
#     "--enable-metrics"                   = "true"
#     "--enable-continuous-cloudwatch-log" = "true"
#     "--TempDir"                          = "s3://${var.data_lake_buckets["raw"].id}/temp/"
#     "--SOURCE_BUCKET"                    = var.data_lake_buckets["raw"].id
#     "--TARGET_BUCKET"                    = var.data_lake_buckets["processed"].id
#     "--DATABASE_NAME"                    = aws_glue_catalog_database.main.name
#   }

#   max_retries       = var.max_retries
#   timeout           = var.job_timeout
#   glue_version      = "4.0"
#   worker_type       = var.worker_type
#   number_of_workers = var.number_of_workers

#   execution_property {
#     max_concurrent_runs = var.max_concurrent_runs
#   }

#   tags = merge(
#     var.common_tags,
#     {
#       Name = "${var.project_name}-${var.environment}-raw-to-processed-job"
#     }
#   )
# }

# # ====================================================================
# # Glue ETL Job - Processed to Curated
# # ====================================================================
# resource "aws_glue_job" "processed_to_curated" {
#   name     = "${var.project_name}-${var.environment}-processed-to-curated"
#   role_arn = aws_iam_role.glue_service_role.arn

#   command {
#     name            = "glueetl"
#     script_location = "s3://${var.scripts_bucket}/${var.processed_to_curated_script}"
#     python_version  = "3"
#   }

#   default_arguments = {
#     "--job-language"                     = "python"
#     "--job-bookmark-option"              = "job-bookmark-enable"
#     "--enable-metrics"                   = "true"
#     "--enable-continuous-cloudwatch-log" = "true"
#     "--TempDir"                          = "s3://${var.data_lake_buckets["processed"].id}/temp/"
#     "--SOURCE_BUCKET"                    = var.data_lake_buckets["processed"].id
#     "--TARGET_BUCKET"                    = var.data_lake_buckets["curated"].id
#     "--DATABASE_NAME"                    = aws_glue_catalog_database.main.name
#   }

#   max_retries       = var.max_retries
#   timeout           = var.job_timeout
#   glue_version      = "4.0"
#   worker_type       = var.worker_type
#   number_of_workers = var.number_of_workers

#   execution_property {
#     max_concurrent_runs = var.max_concurrent_runs
#   }

#   tags = merge(
#     var.common_tags,
#     {
#       Name = "${var.project_name}-${var.environment}-processed-to-curated-job"
#     }
#   )
# }

# ====================================================================
# CloudWatch Log Groups for Glue Jobs
# ====================================================================
resource "aws_cloudwatch_log_group" "glue_jobs" {
  for_each = toset([
    aws_glue_job.raw_to_processed.name,
    aws_glue_job.processed_to_curated.name
  ])

  name              = "/aws-glue/jobs/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "/aws-glue/jobs/${each.value}"
    }
  )
}