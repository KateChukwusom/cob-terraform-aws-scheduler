locals {
  team_environment = "${var.team}-${var.environment}"
}

resource "aws_scheduler_schedule" "cob_schedule" {
  for_each = var.schedules

  name                         = "${local.team_environment}-${each.key}"
  state                        = each.value.enabled ? "ENABLED" : "DISABLED"
  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = each.value.timezone

  flexible_time_window {
    mode                      = each.value.flexible_time_window_minutes > 0 ? "FLEXIBLE" : "OFF"
    maximum_window_in_minutes = each.value.flexible_time_window_minutes > 0 ? each.value.flexible_time_window_minutes : null
  }

  target {
    arn      = each.value.cluster_arn
    role_arn = var.scheduler_role_arn

    ecs_parameters {
      task_definition_arn = each.value.task_definition_arn
      launch_type         = "FARGATE"
      task_count          = each.value.task_count

      network_configuration {
        subnets          = each.value.subnet_ids
        security_groups  = each.value.security_group_ids
        assign_public_ip = each.value.assign_public_ip
      }
    }

    retry_policy {
      maximum_event_age_in_seconds = each.value.maximum_event_age_in_seconds
      maximum_retry_attempts       = each.value.maximum_retry_attempts
    }
  }
}