output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.etl_pipeline.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.etl_pipeline.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = aws_sns_topic.pipeline_notifications.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Step Functions"
  value       = aws_cloudwatch_log_group.step_functions_logs.name
}