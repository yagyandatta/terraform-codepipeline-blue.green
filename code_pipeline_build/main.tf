locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}
# Get AWS account ID
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}

data "template_file" "build_policy" {
  count    = var.build_stage ? 1 : 0
  template = file("${path.module}/files/codebuild.json")
  vars = {
    region               = local.region
    codebuild_project_id = element(concat(aws_codebuild_project.project.*.id, [""]), 0)
    account_id           = var.target_account_id
    s3_bucket_arn        = aws_s3_bucket.releases.arn
    app                  = var.app
  }
}

data "template_file" "pipeline_policy" {
  template = file("${path.module}/files/${var.iam_build_policy_file}")
  vars = {
    region        = local.region
    account_id    = var.target_account_id
    s3_bucket_arn = aws_s3_bucket.releases.arn
    app           = var.app
  }
}


## Create S3 bucket for the pipeline/build
resource "aws_s3_bucket" "releases" {
  bucket        = lower(replace("codepipeline-${var.app}", "_", "-"))
  force_destroy = true

  tags = merge(tomap({"Name" = "codepipeline-${var.app}-releases"}), var.tags)
}

resource "aws_s3_bucket_server_side_encryption_configuration" "releases" {
  bucket = aws_s3_bucket.releases.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "releases" {
  bucket = aws_s3_bucket.releases.id
  acl    = "private"
}


## Create the IAM role for the pipeline/build
resource "aws_iam_role" "codebuild_role" {
  count = var.build_stage ? 1 : 0
  name  = "codebuild-${var.app}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codebuild.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-${var.app}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codepipeline.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_policy" {
  count       = var.build_stage ? 1 : 0
  name        = "codebuild-${var.app}-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = element(concat(data.template_file.build_policy.*.rendered, [""]), 0)
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  count      = var.build_stage ? 1 : 0
  name       = "codebuild-${var.app}-policy-attachment"
  policy_arn = element(concat(aws_iam_policy.codebuild_policy.*.arn, [""]), 0)
  roles      = [element(concat(aws_iam_role.codebuild_role.*.id, [""]), 0)]
}

resource "aws_iam_policy" "codepipeline_policy" {
  name        = "codepipeline-${var.app}-policy"
  path        = "/service-role/"
  description = "Policy used in trust relationship with CodePipeline"

  policy = data.template_file.pipeline_policy.rendered
}

resource "aws_iam_policy_attachment" "codepipeline_policy_attachment" {
  name       = "codepipeline-${var.app}-policy-attachment"
  policy_arn = aws_iam_policy.codepipeline_policy.arn
  roles      = [aws_iam_role.codepipeline_role.id]
}
