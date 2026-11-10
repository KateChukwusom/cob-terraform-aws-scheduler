#The name of the team
variable "team" {
  type        = string
  description = "The team that owns the schedules, used in resource names and tags"
  validation {
    condition     = length(var.team) <= 20
    error_message = "team must be 20 characters or fewer"
  }
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.team))
    error_message = "team must be lowercase letters, digits or hyphens only (ECR repository names must be lowercase)"
  }
}

#Deployment environment
variable "environment" {
  type        = string
  description = "Current environment"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod, it must be spelt that way"
  }
}

# Schedules, keyed by name. Each one starts an ECS Fargate task. This is what it should look like:

# schedules = {
#   quotes = {
#     schedule_expression = "cron(0 8 * * ? *)"      # every day at 08:00 in the timezone below
#     timezone            = "Africa/Lagos"
#     cluster_arn         = module.ECS.cluster_arn
#     task_definition_arn = module.ECS.task_definition_arns["quotes"]
#     execution_role_arn  = module.ECS.execution_role_arn
#     task_role_arn       = module.ECS.task_role_arns["quotes"]
#     subnet_ids          = values(module.Networking.public_subnet_ids)
#     security_group_ids  = [module.ECS.service_security_group_ids["quotes"]]
#     assign_public_ip    = true
#   }
# }
variable "schedules" {
  type = map(object({
    schedule_expression          = string
    timezone                     = optional(string, "UTC")
    enabled                      = optional(bool, true)
    flexible_time_window_minutes = optional(number, 0)
    cluster_arn                  = string
    task_definition_arn          = string
    subnet_ids                   = list(string)
    security_group_ids           = list(string)
    assign_public_ip             = optional(bool, false)
    task_count                   = optional(number, 1)
    maximum_retry_attempts       = optional(number, 2)
    maximum_event_age_in_seconds = optional(number, 3600)
  }))
  description = "Schedules keyed by name, each one starts an ECS Fargate task"
  default     = {}

  validation {
    condition     = alltrue([for key, s in var.schedules : can(regex("^[A-Za-z0-9_.-]+$", key)) && length(key) <= 35])
    error_message = "Schedule keys may only contain letters, digits, dots, hyphens and underscores, and must be 35 characters or fewer (schedule names are limited to 64 characters)."
  }

  validation {
    condition     = alltrue([for key, s in var.schedules : can(regex("^(cron|rate|at)\\(.+\\)$", s.schedule_expression))])
    error_message = "schedule_expression must look like cron(0 8 * * ? *), rate(1 day) or at(2026-12-01T08:00:00)."
  }

  validation {
    condition     = alltrue([for key, s in var.schedules : length(s.subnet_ids) > 0])
    error_message = "Every schedule needs at least one subnet."
  }

  validation {
    condition     = alltrue([for key, s in var.schedules : s.task_count >= 1 && s.task_count <= 10])
    error_message = "task_count must be between 1 and 10."
  }

  validation {
    condition     = alltrue([for key, s in var.schedules : s.flexible_time_window_minutes >= 0 && s.flexible_time_window_minutes <= 1440])
    error_message = "flexible_time_window_minutes must be between 0 (exact time) and 1440."
  }

  validation {
    condition     = alltrue([for key, s in var.schedules : s.maximum_retry_attempts >= 0 && s.maximum_retry_attempts <= 185])
    error_message = "maximum_retry_attempts must be between 0 and 185."
  }

  validation {
    condition     = alltrue([for key, s in var.schedules : s.maximum_event_age_in_seconds >= 60 && s.maximum_event_age_in_seconds <= 86400])
    error_message = "maximum_event_age_in_seconds must be between 60 and 86400."
  }
}

variable "scheduler_role_arn" {
  type        = string
  description = "ARN of the role EventBridge Scheduler uses to start tasks, created by the IAM module"
}