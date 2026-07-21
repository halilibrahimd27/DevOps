# budget.tf (referans çözüm) — koruma önce. Önce KENDİN dene.
resource "aws_budgets_budget" "monthly" {
  name         = "lab-monthly-guardrail"
  budget_type  = "COST"
  limit_amount = "5"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Gerçekleşen harcama %80'i geçince uyar
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["<YOUR_EMAIL>"]
  }

  # Tahmini harcama %100'ü geçecekse erken uyar
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["<YOUR_EMAIL>"]
  }
}
