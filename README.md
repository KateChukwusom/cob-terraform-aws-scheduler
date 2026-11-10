# REUSABLE Scheduler Module

A reusable Terraform module that starts ECS Fargate tasks on a clock using EventBridge Scheduler. It also creates the one IAM role the scheduler needs, with only the permissions it requires.

## Design principles

- **Nothing is hardcoded.** Times, timezones, subnets and task definitions all come in through variables.
- **Least privilege.** The scheduler role may run only your task definitions on your clusters, and pass only your two ECS roles to ECS.
- **`for_each` over one-off resources.** Another schedule is one more entry in `schedules`.
- **Validation catches mistakes before `apply`.** Bad schedule expressions, task counts and retry values fail at `plan`.

## Variables

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `team` | string | required | Lowercase team name, used in names and tags (max 20 characters) |
| `environment` | string | required | `"dev"` or `"prod"` |
| `schedules` | map(object) | `{}` | Schedules keyed by name |

### `schedules` settings

| Setting | Default | Description |
| --- | --- | --- |
| `schedule_expression` | required | `cron(0 8 * * ? *)`, `rate(1 day)` or `at(2026-12-01T08:00:00)` |
| `timezone` | `"UTC"` | IANA name such as `"Africa/Lagos"`, so the send time does not drift |
| `enabled` | `true` | `false` pauses the schedule without deleting it |
| `flexible_time_window_minutes` | `0` | `0` runs at the exact time, otherwise runs within this window |
| `cluster_arn` | required | The ECS cluster (ECS module `cluster_arn`) |
| `task_definition_arn` | required | The task to run (ECS module `task_definition_arns`) |
| `execution_role_arn` | required | ECS module `execution_role_arn` |
| `task_role_arn` | required | ECS module `task_role_arns` |
| `subnet_ids` | required | Subnets the task runs in |
| `security_group_ids` | required | Security groups for the task |
| `assign_public_ip` | `false` | Needed in public subnets |
| `task_count` | `1` | Tasks started per run (1 to 10) |
| `maximum_retry_attempts` | `2` | Retries if EventBridge cannot start the task (not if your script fails) |
| `maximum_event_age_in_seconds` | `3600` | How long EventBridge keeps retrying |

## The cron format

EventBridge Scheduler cron has six fields: `minute hour day-of-month month day-of-week year`. One of day-of-month or day-of-week must be `?`.

| Expression | Meaning |
| --- | --- |
| `cron(0 8 * * ? *)` | Every day at 08:00 |
| `cron(0 8 ? * MON-FRI *)` | Weekdays at 08:00 |
| `rate(5 minutes)` | Every 5 minutes, handy for testing |

## Outputs

| Output | Description |
| --- | --- |
| `schedule_arns` | Map of key, schedule ARN |
| `scheduler_role_arn` | The scheduler role ARN, `null` when there are no schedules |

## Using this module

```hcl
module "scheduler" {
  source = "git::https://github.com/KateChukwusom/AWSTerraform_Modules.git//modules/Scheduler?ref=v1.0.0"

  team        = "platform"
  environment = "dev"
  schedules   = var.schedules
}
```

## Requirements

Terraform >= 1.9.0 and the AWS provider ~> 6.0.
