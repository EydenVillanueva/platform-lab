variable "region" {
  description = "AWS region for every resource in this lab."
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Your name, added as a tag to every resource."
  type        = string
  default     = "eyden"
}

# L06 and L07: add your own variables below (for example the VPC CIDR and the GitHub repository).
