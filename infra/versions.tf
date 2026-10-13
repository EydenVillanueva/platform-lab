terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Week 2 stretch: move the state to S3 with native locking.
  # backend "s3" {
  #   bucket       = "<your-state-bucket>"
  #   key          = "platform-lab/terraform.tfstate"
  #   region       = "us-east-1"
  #   use_lockfile = true
  # }
}
