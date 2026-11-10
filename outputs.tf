# outputs.tf

output "schedule_arns" {
  description = "ARNs of the schedules created, keyed by schedule key"
  value       = { for key, s in aws_scheduler_schedule.cob_schedule : key => s.arn }
}


output "scheduler_role_arn" {
  description = "ARN of the role the scheduler uses to start tasks, created by the IAM module"
  value       = var.scheduler_role_arn
}