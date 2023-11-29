resource "aws_codepipeline" "project" {
  name     = "${var.app}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.releases.id
    type     = "S3"
  }

  dynamic "stage" {
    for_each = [for i in var.stages : {
      name   = i.name
      action = i.action
    }]
    content {
      name = stage.value.name
      action {
        name             = stage.value.action["name"]
        owner            = stage.value.action["owner"]
        version          = stage.value.action["version"]
        category         = stage.value.action["category"]
        provider         = stage.value.action["provider"]
        input_artifacts  = stage.value.action["input_artifacts"]
        output_artifacts = stage.value.action["output_artifacts"]
        configuration    = stage.value.action["configuration"]
      }
    }
  }

  tags = merge({ "Name" = var.app }, var.tags)

  lifecycle {
    ignore_changes = [
      stage.0.action.0.configuration.OAuthToken
    ]
  }
}
