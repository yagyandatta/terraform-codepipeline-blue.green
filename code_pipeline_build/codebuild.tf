resource "aws_codebuild_project" "project" {
  count = var.build_stage ? 1 : 0

  name           = var.app
  description    = "${var.app} CodeBuild Project"
  build_timeout  = "60"
  queued_timeout = "480"
  service_role   = element(concat(aws_iam_role.codebuild_role.*.arn, [""]), 0)

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.build_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.privileged_mode

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id == null ? [] : list(1)
    content {
      vpc_id             = var.vpc_id
      subnets            = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.app}-log-group"
      stream_name = null
    }

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.releases.id}/build-log"
    }
  }

  source {
    type = "CODEPIPELINE"
  }

  tags = merge(tomap({"Name" = var.app}), var.tags)

  depends_on = [aws_iam_role.codebuild_role]
}
