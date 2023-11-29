#################### CODECOMMIT ########################
variable "smartsense_service_repo_name" {
    description = "value"
    type = string
}

variable "smartsense_portal_repo_name" {
    description = "value"
    type = string
}

#################### TAGS ########################
variable "tags" {
  default     = {}
  type        = map(any)
  description = "A mapping of tags to assign to all resources."
}