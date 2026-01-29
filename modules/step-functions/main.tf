# SNS Topic for notifications
resource "aws_sns_topic" "pipeline_notifications" {
  name = "${var.project_name}-${var.environment}-pipeline-notifications"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-pipeline-notifications"
    }
  )
}

# SNS Topic Subscription (email)
resource "aws_sns_topic_subscription" "pipeline_email" {
  count     = var.notification_email != null ? 1 : 0
  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# IAM Role for Step Functions
resource "aws_iam_role" "step_functions_role" {
  name = "${var.project_name}-${var.environment}-step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-step-functions-role"
    }
  )
}

# IAM Policy for Step Functions
resource "aws_iam_role_policy" "step_functions_policy" {
  name = "${var.project_name}-${var.environment}-step-functions-policy"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler",
          "glue:StartJobRun",
          "glue:GetJobRun"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.pipeline_notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "${aws_cloudwatch_log_group.step_functions_logs.arn}:*"
      }
    ]
  })
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions_logs" {
  name              = "/aws/stepfunctions/${var.project_name}-${var.environment}-etl-pipeline"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "/aws/stepfunctions/${var.project_name}-${var.environment}-etl-pipeline"
    }
  )
}

# Step Functions State Machine
resource "aws_sfn_state_machine" "etl_pipeline" {
  name     = "${var.project_name}-${var.environment}-etl-pipeline"
  role_arn = aws_iam_role.step_functions_role.arn

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions_logs.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  definition = templatefile("${path.module}/state-machine.json", {
    raw_crawler_name               = var.raw_crawler_name
    processed_crawler_name         = var.processed_crawler_name
    raw_to_processed_job_name      = var.raw_to_processed_job_name
    processed_to_curated_job_name  = var.processed_to_curated_job_name
    sns_topic_arn                  = aws_sns_topic.pipeline_notifications.arn
    environment                    = var.environment
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-etl-pipeline"
    }
  )
}

# EventBridge Rule for scheduled execution (optional)
resource "aws_cloudwatch_event_rule" "daily_pipeline" {
  count               = var.schedule_expression != null ? 1 : 0
  name                = "${var.project_name}-${var.environment}-daily-pipeline"
  description         = "Trigger ETL pipeline daily"
  schedule_expression = var.schedule_expression

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-daily-pipeline"
    }
  )
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "step_functions" {
  count     = var.schedule_expression != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.daily_pipeline[0].name
  target_id = "StepFunctionsTarget"
  arn       = aws_sfn_state_machine.etl_pipeline.arn
  role_arn  = aws_iam_role.eventbridge_role[0].arn
}

# IAM Role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  count = var.schedule_expression != null ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eventbridge-role"
    }
  )
}

# IAM Policy for EventBridge to invoke Step Functions
resource "aws_iam_role_policy" "eventbridge_policy" {
  count = var.schedule_expression != null ? 1 : 0
  name  = "${var.project_name}-${var.environment}-eventbridge-policy"
  role  = aws_iam_role.eventbridge_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = aws_sfn_state_machine.etl_pipeline.arn
      }
    ]
  })
}