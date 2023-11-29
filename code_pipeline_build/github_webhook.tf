/*resource "random_password" "webhook_secret" {
  length = 16
  special = true
  override_special = "_%@"
}

resource "aws_ssm_parameter" "webhook_secret_parameter" {
  name  = "/${var.app}/webhook_secret"
  value = random_password.webhook_secret.result
  type  = "SecureString"
}

resource "aws_codepipeline_webhook" "github_webhook" {
  name            = var.webhook_name
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.project.name

  authentication_configuration {
    secret_token = aws_ssm_parameter.webhook_secret_parameter.value
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}*/