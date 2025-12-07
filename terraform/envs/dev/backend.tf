# ------------------------------------------------------------------------------
# Terraform backend
#
# Demo setup:
#   - uses the default local backend (terraform.tfstate in this folder)
#
# Production:
#   - migrate to S3 + DynamoDB (remote state + state locking)
#   - backend config is typically kept out of VCS or templated per environment
# ------------------------------------------------------------------------------
