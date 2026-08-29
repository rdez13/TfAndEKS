# Billing alert. Lives in bootstrap, not the main stack, so that `terraform destroy` on
# the EKS stack cannot delete the alarm that guards against a forgotten cluster.
#
# Budgets data lags real usage by up to ~24h, so treat this as a safety net, not a
# killswitch. It notifies; it does not stop anything.

locals {
  # Notify at 50% of budget on actual spend, and when the month is forecast to exceed it.
  budget_actual_threshold_percent   = 50
  budget_forecast_threshold_percent = 100
}

resource "aws_budgets_budget" "monthly_cost" {
  name         = "${var.project_name}-monthly-cost"
  budget_type  = "COST"
  limit_amount = var.budget_limit_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Fires once spend has already happened.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = local.budget_actual_threshold_percent
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Fires on projected month-end spend — this is the one that catches a cluster left
  # running, days before the actual charge lands.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = local.budget_forecast_threshold_percent
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}
