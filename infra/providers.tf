provider "aws" {
  region = var.region

  # Every resource gets these tags. scripts/aws-leftovers.sh finds anything left behind by the Project tag.
  default_tags {
    tags = {
      Project   = "platform-lab"
      ManagedBy = "terraform"
      Owner     = var.owner
    }
  }
}
