resource "aws_codedeploy_app" "this" {
  count = var.deploy_stage ? 1 : 0
  name  = var.app
}

resource "aws_iam_policy" "this_deploy" {
  count       = var.deploy_stage ? 1 : 0
  name        = "${var.app}-codedeploy-policy"
  description = "Policy to create a codedeploy application revision and to deploy it, for application ${aws_codedeploy_app.this[0].name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect" : "Allow",
      "Action" : [
        "codedeploy:CreateDeployment"
      ],
      "Resource" : [
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${aws_codedeploy_app.this[0].name}/*"
      ]
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource" : [
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
      ]
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "codedeploy:GetApplicationRevision"
      ],
      "Resource" : [
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:${aws_codedeploy_app.this[0].name}"
      ]
    },
    {
      "Effect" : "Allow",
      "Action" : [
        "codedeploy:RegisterApplicationRevision"
      ],
      "Resource" : [
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:${aws_codedeploy_app.this[0].name}"
      ]
    }
    ${element(formatlist(", { \"Effect\" : \"Allow\", \"Action\" : [ \"s3:PutObject*\", \"s3:ListBucket\" ], \"Resource\" : [ \"%s/*\", \"%s\" ] }, { \"Effect\" : \"Allow\", \"Action\" : [ \"s3:ListAllMyBuckets\" ], \"Resource\" : [ \"*\" ] }", compact([var.s3_bucket_arn, aws_s3_bucket.codedeploy_bucket.arn]), compact([var.s3_bucket_arn, aws_s3_bucket.codedeploy_bucket.arn])), 0)}
   ]
}
EOF
}

resource "aws_codedeploy_deployment_group" "this" {
  count                 = var.deploy_stage ? 1 : 0
  app_name              = aws_codedeploy_app.this[0].name
  deployment_group_name = var.app
  service_role_arn      = var.service_role_arn
  autoscaling_groups    = var.autoscaling_groups

  auto_rollback_configuration {
    enabled = var.rollback_enabled
    events  = var.rollback_events
  }

  deployment_style {
    deployment_option = var.alb_target_group == null ? "WITHOUT_TRAFFIC_CONTROL" : "WITH_TRAFFIC_CONTROL"
    deployment_type   = var.enable_bluegreen == false ? "IN_PLACE" : "BLUE_GREEN"
  }

  dynamic "blue_green_deployment_config" {
    for_each = var.enable_bluegreen == true ? [1] : []
    content {
      deployment_ready_option {
        action_on_timeout = var.bluegreen_timeout_action
      }

      terminate_blue_instances_on_deployment_success {
        action = var.blue_termination_behavior
      }
      green_fleet_provisioning_option {
        action = var.green_provisioning
      }
    }
  }

  dynamic "load_balancer_info" {
    for_each = var.alb_target_group == null ? [] : [var.alb_target_group]
    content {
      target_group_info {
        name = var.alb_target_group
      }
    }
  }

  dynamic "trigger_configuration" {
    for_each = var.trigger_target_arn == null ? [] : [var.trigger_target_arn]
    content {
      trigger_events     = var.trigger_events
      trigger_name       = "${var.app_name}-${var.environment}"
      trigger_target_arn = var.trigger_target_arn
    }
  }

  dynamic "ec2_tag_set" {
    for_each = var.ec2_tag_filter == null ? [] : var.ec2_tag_filter

    content {
      ec2_tag_filter {
        key   = lookup(ec2_tag_set.value, "key", null)
        type  = lookup(ec2_tag_set.value, "type", null)
        value = lookup(ec2_tag_set.value, "value", null)
      }
    }
  }
}
