output "codebuild_role_arn" {
  value = element(concat(aws_iam_role.codebuild_role.*.arn, [""]), 0)
}

# output "approve_sns_arn" {
#   description = "ARN of SNS topic"
#   value       = element(concat(aws_sns_topic.this.*.arn, [""]), 0)
# }

output "codedeploy_name" {
  value = aws_codedeploy_app.this.*.name
}

output "deployer_policy_id" {
  value = aws_iam_policy.this_deploy.*.id
}

output "deployer_policy_arn" {
  value = aws_iam_policy.this_deploy.*.arn
}

output "deployer_policy_name" {
  value = aws_iam_policy.this_deploy.*.name
}

output "bucket_id" {
  value = aws_s3_bucket.codedeploy_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.codedeploy_bucket.arn
}

output "codepipeline_name" {
  value = element(split(":", aws_codepipeline.project.arn), length(split(":", aws_codepipeline.project.arn)) - 1)
}