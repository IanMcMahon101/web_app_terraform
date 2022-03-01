# assume to be using /.aws credentials file to avoid hardcoding of creds

provider "aws" {
  region = var.region

assume_role {
    role_arn     = var.assume_role_arn
    session_name = var.session_name
  }
}