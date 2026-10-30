# terraform-codepipeline-blue.green

Terraform that provisions an AWS CodePipeline for blue/green deployments to EC2 with CodeDeploy, one pipeline per Terraform workspace (for example `dev`, `prod`).

## What it creates

- CodePipeline with source, build, approval and deploy stages
- CodeBuild project and its IAM policy
- CodeDeploy application and deployment group (EC2 tag filters)
- SNS topic for the manual approval stage
- S3 artifact bucket
- IAM service role for CodeDeploy

The reusable pipeline is in [`code_pipeline_build`](code_pipeline_build); the root module wires it up per application.

## Usage

```bash
terraform init
terraform workspace new dev        # or select an existing one
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

The `prod` workspace builds from the `main` branch; any other workspace builds from the branch with the same name. Set `service_repo_name`, `portal_repo_name` and the account variables in your own `tfvars`; the GitHub token is read from SSM Parameter Store and is never stored in the repo.

## Requirements

- Terraform 1.x, AWS provider
- An AWS account with permission to create the resources above
- GitHub OAuth token stored in SSM Parameter Store
