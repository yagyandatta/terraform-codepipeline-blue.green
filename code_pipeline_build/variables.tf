variable "build_stage" {
  default     = false
  type        = bool
  description = "Flag to enable creation of Build stage resources"
}
variable "deploy_stage" {
  default     = false
  type        = bool
  description = "Flag to enable creation of Deploy stage resources"
}

variable "approval_stage" {
  default     = false
  type        = bool
  description = "Flag to enable creation of Approval stage resources"
}

variable "app" {
  default     = ""
  type        = string
  description = "Application name for the CodeBuild and CodePipeline"
}

variable "build_image" {
  default     = ""
  type        = string
  description = "Image to use for build instance"
}

variable "tags" {
  default     = {}
  type        = map(any)
  description = "A mapping of tags to assign to all resources."
}
variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "ec2_tag_filter" {
  type = list(object({
    key   = string
    type  = string
    value = string
  }))
  default     = null
  description = <<-DOC
    A list of sets of tag filters. If multiple tag groups are specified, 
    any instance that matches to at least one tag filter of every tag group is selected.
    key:
      The key of the tag filter.
    type:
      The type of the tag filter, either `KEY_ONLY`, `VALUE_ONLY`, or `KEY_AND_VALUE`.
    value:
      The value of the tag filter.
  DOC
}

variable "codebuild_buildspec_file" {
  default     = ""
  type        = string
  description = "Filename of the buildspec file including the extension"
}

variable "iam_build_policy_file" {
  type        = string
  description = "Filename of the build iam policy file including the extension"
}

variable "privileged_mode" {
  default     = false
  type        = bool
  description = "If set to true, enables running the Docker daemon inside a Docker container"
}

variable "environment_variables" {
  type = list(object(
    {
      name  = string
      value = string
      type  = string
  }))

  default = [
    {
      name  = "NO_ADDITIONAL_BUILD_VARS"
      value = "TRUE"
      type  = "PLAINTEXT"
  }]

  description = "A list of maps, that contain both the key 'name' and the key 'value' to be used as additional environment variables for the build"
}

variable "target_account_id" {
  type        = string
  description = "Target Account ID"
}

variable "stages" {
  type = list(object(
    {
      name = string
      action = object(
        {
          name             = string
          category         = string
          owner            = string
          provider         = string
          input_artifacts  = list(string)
          output_artifacts = list(string)
          version          = string
          configuration    = map(any)
        }
      )
  }))

  default = [
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
          ProjectName = "frontend"
        }
      }
  }]
  description = "This list describes each stage of the build. Possible values are Approval, Build, Deploy, Invoke, Source and Test"
}

variable "name_prefix" {
  description = "The prefix name of the SNS topic to create"
  type        = string
  default     = null
}

# ----------------------------------- Approval SNS - Start -----------------------------------

# variable "display_name" {
#   description = "The display name for the SNS topic"
#   type        = string
#   default     = null
# }

# variable "policy" {
#   description = "The fully-formed AWS policy as JSON"
#   type        = string
#   default     = null
# }

# variable "delivery_policy" {
#   description = "The SNS delivery policy"
#   type        = string
#   default     = null
# }

# variable "application_success_feedback_role_arn" {
#   description = "The IAM role permitted to receive success feedback for this topic"
#   type        = string
#   default     = null
# }

# variable "application_success_feedback_sample_rate" {
#   description = "Percentage of success to sample"
#   type        = string
#   default     = null
# }

# variable "application_failure_feedback_role_arn" {
#   description = "IAM role for failure feedback"
#   type        = string
#   default     = null
# }

# variable "http_success_feedback_role_arn" {
#   description = "The IAM role permitted to receive success feedback for this topic"
#   type        = string
#   default     = null
# }

# variable "http_success_feedback_sample_rate" {
#   description = "Percentage of success to sample"
#   type        = string
#   default     = null
# }

# variable "http_failure_feedback_role_arn" {
#   description = "IAM role for failure feedback"
#   type        = string
#   default     = null
# }

# variable "lambda_success_feedback_role_arn" {
#   description = "The IAM role permitted to receive success feedback for this topic"
#   type        = string
#   default     = null
# }

# variable "lambda_success_feedback_sample_rate" {
#   description = "Percentage of success to sample"
#   type        = string
#   default     = null
# }

# variable "lambda_failure_feedback_role_arn" {
#   description = "IAM role for failure feedback"
#   type        = string
#   default     = null
# }

# variable "sqs_success_feedback_role_arn" {
#   description = "The IAM role permitted to receive success feedback for this topic"
#   type        = string
#   default     = null
# }

# variable "sqs_success_feedback_sample_rate" {
#   description = "Percentage of success to sample"
#   type        = string
#   default     = null
# }

# variable "sqs_failure_feedback_role_arn" {
#   description = "IAM role for failure feedback"
#   type        = string
#   default     = null
# }

# variable "kms_master_key_id" {
#   description = "The ID of an AWS-managed customer master key (CMK) for Amazon SNS or a custom CMK"
#   type        = string
#   default     = null
# }

# ----------------------------------- Approval SNS - End -----------------------------------


variable "vpc_id" {
  description = "VPC id"
  default     = null
}

variable "subnet_ids" {
  description = "VPC subnet ids"
  type        = list(any)
  default     = []
}

variable "security_group_ids" {
  description = "Security group ids"
  type        = list(any)
  default     = []
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket where to fetch the application revision packages"
  default     = ""
  type        = string
}

variable "service_role_arn" {
  description = "IAM role that is used by the deployment group"
}

variable "autoscaling_groups" {
  type        = list(string)
  description = "Autoscaling groups you want to attach to the deployment group"
  default     = []
}

variable "rollback_enabled" {
  description = "Whether to enable auto rollback"
  default     = false
}

variable "rollback_events" {
  description = "The event types that trigger a rollback"
  type        = list(string)
  default     = ["DEPLOYMENT_FAILURE"]
}

variable "trigger_events" {
  description = "events that can trigger the notifications"
  type        = list(string)
  default     = ["DeploymentStop", "DeploymentRollback", "DeploymentSuccess", "DeploymentFailure", "DeploymentStart"]
}

variable "trigger_target_arn" {
  description = "The ARN of the SNS topic through which notifications are sent"
  type        = string
  default     = null
}

variable "enable_bluegreen" {
  description = "Enable all bluegreen deployment options"
  type        = bool
  default     = false

}

variable "bluegreen_timeout_action" {
  description = "When to reroute traffic from an original environment to a replacement environment. Only relevant when `enable_bluegreen` is `true`"
  type        = string
  default     = "CONTINUE_DEPLOYMENT"
}

variable "blue_termination_behavior" {
  description = " The action to take on instances in the original environment after a successful deployment. Only relevant when `enable_bluegreen` is `true`"
  default     = "KEEP_ALIVE"
}

variable "green_provisioning" {
  description = "The method used to add instances to a replacement environment. Only relevant when `enable_bluegreen` is `true`"
  type        = string
  default     = "COPY_AUTO_SCALING_GROUP"
}

variable "alb_target_group" {
  description = "Name of the ALB target group to use, define it when traffic need to be blocked from ALB during deployment"
  default     = null
  type        = string
}
