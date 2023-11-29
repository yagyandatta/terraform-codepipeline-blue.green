## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| app | Application name for the CodeBuilg and CodePipeline | `string` | n/a | yes |
| codebuild\_buildspec\_file | Filename of the buildspec file including the enxtension | `string` | n/a | yes |
| github\_oauthtoken | GitHub OAuthToken from SSM with which codepipeline access the GitHub | `string` | n/a | yes |
| github\_owner | Github Account Owner for the sorce code | `string` | n/a | yes |
| iam\_build\_policy\_file | Filename of the build iam policy file including the enxtension | `string` | n/a | yes |
| project | GitHub repository name | `string` | n/a | yes |
| build\_image | n/a | `string` | `"ubuntu"` | no |
| environment\_variables | A list of maps, that contain both the key 'name' and the key 'value' to be used as additional environment variables for the build | <pre>list(object(<br>    {<br>      name  = string<br>      value = string<br>      type  = string<br>  }))<br></pre> | <pre>[<br>  {<br>    "name": "NO_ADDITIONAL_BUILD_VARS",<br>    "type": "PLAINTEXT",<br>    "value": "TRUE"<br>  }<br>]<br></pre> | no |
| privileged\_mode | If set to true, enables running the Docker daemon inside a Docker container | `bool` | `false` | no |
| tags | A mapping of tags to assign to all resources. | `map` | `{}` | no |

## Outputs

No output.

