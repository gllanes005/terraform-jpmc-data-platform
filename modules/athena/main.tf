# S3 Bucket for Athena Query Results
resource "aws_s3_bucket" "query_results" {
  bucket = "${var.project_name}-${var.environment}-athena-results-${random_string.suffix.result}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-athena-results"
    }
  )
}

# Random suffix for unique bucket naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Enable versioning on query results bucket
resource "aws_s3_bucket_versioning" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption for query results
resource "aws_s3_bucket_server_side_encryption_configuration" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for query results (auto-cleanup)
resource "aws_s3_bucket_lifecycle_configuration" "query_results" {
  bucket = aws_s3_bucket.query_results.id

  rule {
    id     = "cleanup-old-results"
    status = "Enabled"

    filter {}  # Apply to all objects

    expiration {
      days = var.query_results_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Athena Workgroup
resource "aws_athena_workgroup" "main" {
  name        = "${var.project_name}-${var.environment}-workgroup"
  description = "Athena workgroup for ${var.environment} environment"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.id}/results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    # Cost control settings
    bytes_scanned_cutoff_per_query = var.bytes_scanned_cutoff_per_query
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-athena-workgroup"
    }
  )
}

# Data Catalog (uses existing Glue database)
resource "aws_athena_data_catalog" "glue_catalog" {
  name        = "${var.project_name}-${var.environment}-glue-catalog"
  description = "Glue data catalog for ${var.environment}"
  type        = "GLUE"

  parameters = {
    "catalog-id" = data.aws_caller_identity.current.account_id
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-glue-catalog"
    }
  )
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Sample Named Query - Top Customers by Order Amount
resource "aws_athena_named_query" "top_customers" {
  name        = "${var.environment}-top-customers-by-amount"
  description = "Find top 10 customers by total order amount"
  workgroup   = aws_athena_workgroup.main.name
  database    = var.glue_database_name

  query = <<-SQL
    SELECT 
      customer_name,
      COUNT(*) as order_count,
      SUM(order_amount) as total_amount,
      AVG(order_amount) as avg_amount
    FROM "${var.glue_database_name}"."analytics"
    GROUP BY customer_name
    ORDER BY total_amount DESC
    LIMIT 10;
  SQL
}

# Sample Named Query - Orders by Status
resource "aws_athena_named_query" "orders_by_status" {
  name        = "${var.environment}-orders-by-status"
  description = "Count orders grouped by status"
  workgroup   = aws_athena_workgroup.main.name
  database    = var.glue_database_name

  query = <<-SQL
    SELECT 
      status,
      COUNT(*) as order_count,
      SUM(order_amount) as total_amount
    FROM "${var.glue_database_name}"."analytics"
    GROUP BY status
    ORDER BY order_count DESC;
  SQL
}

# Sample Named Query - Recent Orders
resource "aws_athena_named_query" "recent_orders" {
  name        = "${var.environment}-recent-orders"
  description = "Get orders from the last 30 days"
  workgroup   = aws_athena_workgroup.main.name
  database    = var.glue_database_name

  query = <<-SQL
    SELECT 
      id,
      customer_name,
      order_date,
      order_amount,
      status,
      product_category
    FROM "${var.glue_database_name}"."analytics"
    WHERE order_date >= date_add('day', -30, current_date)
    ORDER BY order_date DESC;
  SQL
}

# Sample Named Query - Product Category Analysis
resource "aws_athena_named_query" "category_analysis" {
  name        = "${var.environment}-product-category-analysis"
  description = "Analyze sales by product category"
  workgroup   = aws_athena_workgroup.main.name
  database    = var.glue_database_name

  query = <<-SQL
    SELECT 
      product_category,
      COUNT(*) as order_count,
      SUM(order_amount) as total_revenue,
      AVG(order_amount) as avg_order_value,
      MIN(order_amount) as min_order,
      MAX(order_amount) as max_order
    FROM "${var.glue_database_name}"."analytics"
    GROUP BY product_category
    ORDER BY total_revenue DESC;
  SQL
}