locals {
  codedeploy_service_role_name = "CodeDeployServiceRoleForEC2"
  codedeploy_service_role_desc = "Role used by CodeDeploy Deployment Group"

  pipeline_branch = terraform.workspace == "prod" ? "main" : terraform.workspace
  account_id = "idname"
}

resource "aws_iam_role" "codedeploy" {
  name               = local.codedeploy_service_role_name
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  path               = "/"
  description        = local.codedeploy_service_role_desc
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_policy_attach" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# REST API application for the backend service
# Using the replace function to remove any '.' from repo names. The SNS and Codebuild resources created in 
# Codepipeline module will fail because '.' is not allowed within naming convention.
module "service_pipeline" {
  source             = "./code_pipeline_build"
  app                = "${replace(var.service_repo_name, ".", "-")}-${terraform.workspace}"
  approval_stage     = true
  build_stage        = true
  deploy_stage       = true
  privileged_mode    = false
  target_account_id  = local.account_id
  environment        = terraform.workspace
  service_role_arn   = aws_iam_role.codedeploy.arn
  # autoscaling_groups = [module.service.asg_id]
  ec2_tag_filter = [
    {
      key   = "Application"
      type  = "KEY_AND_VALUE"
      value = "Backend Service"
    },
    {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = terraform.workspace
    }
  ]

  stages = [{
    name = "Source"
    action = {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      input_artifacts  = null
      output_artifacts = ["SourceArtifact"]
      configuration = {
        BranchName           = "Cognito-Init" #"Inital-Setup" # local.pipeline_branch
        OutputArtifactFormat = "CODE_ZIP"
        RepositoryName       = var.service_repo_name
        PollForSourceChanges = true
      }
    }
    },
    {
      name = "Build"
      action = {
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["SourceArtifact"]
        output_artifacts = ["BuildArtifact"]
        version          = "1"
        configuration = {
          ProjectName = "${replace(var.service_repo_name, ".", "-")}-${terraform.workspace}"
          EnvironmentVariables = jsonencode([
            {
              name  = "DB_USER"
              value = "/${terraform.workspace}/app/db/user"
              type  = "PARAMETER_STORE"
            },
            {
              name  = "DB_PW"
              value = "/${terraform.workspace}/app/db/password"
              type  = "PARAMETER_STORE"
            },
            {
              name  = "DB_URL"
              value = "/${terraform.workspace}/app/db/url"
              type  = "PARAMETER_STORE"
            }
          ])
        }
      }
    },
    {
      name = "Deploy"
      action = {
        name             = "Deploy"
        category         = "Deploy"
        owner            = "AWS"
        provider         = "CodeDeploy"
        input_artifacts  = ["BuildArtifact"]
        output_artifacts = []
        version          = "1"
        configuration = {
          ApplicationName     = "${replace(var.service_repo_name, ".", "-")}-${terraform.workspace}"
          DeploymentGroupName = "${replace(var.service_repo_name, ".", "-")}-${terraform.workspace}"
        }
      }
  }]
  build_image           = "aws/codebuild/standard:4.0"
  iam_build_policy_file = "app_testing.json"
  tags                  = merge(tomap({"Application" = "Backend Service"}), var.tags)
}

# Frontend portal CodePipeline 
module "portal_pipeline" {
  source             = "./code_pipeline_build"
  app                = "${replace(var.portal_repo_name, ".", "-")}-${terraform.workspace}"
  approval_stage     = true
  build_stage        = true
  deploy_stage       = true
  privileged_mode    = false
  target_account_id  = local.account_id
  environment        = terraform.workspace
  service_role_arn   = aws_iam_role.codedeploy.arn
  # autoscaling_groups = [module.portal.asg_id]
  ec2_tag_filter = [
    {
      key   = "Application"
      type  = "KEY_AND_VALUE"
      value = "Frontend Portal"
    },
    {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = terraform.workspace
    }
  ]

  stages = [{
    name = "Source"
    action = {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      input_artifacts  = null
      output_artifacts = ["SourceArtifact"]
      configuration = {
        BranchName           = "Cognito_INIT" #"Initial-Setup" # local.pipeline_branch
        OutputArtifactFormat = "CODE_ZIP"
        RepositoryName       = var.portal_repo_name
        PollForSourceChanges = true
      }
    }
    },
    {
      name = "Build"
      action = {
        name             = "Build"
        category         = "Build"
        owner            = "AWS"
        provider         = "CodeBuild"
        input_artifacts  = ["SourceArtifact"]
        output_artifacts = ["BuildArtifact"]
        version          = "1"
        configuration = {
          ProjectName = "${replace(var.portal_repo_name, ".", "-")}-${terraform.workspace}"
        }
      }
    },
    {
      name = "Deploy"
      action = {
        name             = "Deploy"
        category         = "Deploy"
        owner            = "AWS"
        provider         = "CodeDeploy"
        input_artifacts  = ["BuildArtifact"]
        output_artifacts = []
        version          = "1"
        configuration = {
          ApplicationName     = "${replace(var.portal_repo_name, ".", "-")}-${terraform.workspace}"
          DeploymentGroupName = "${replace(var.portal_repo_name, ".", "-")}-${terraform.workspace}"
        }
      }
  }]
  build_image           = "aws/codebuild/standard:4.0"
  iam_build_policy_file = "app_testing.json"
  tags                  = merge(tomap({"Application" = "Frontend Portal"}), var.tags)

}
