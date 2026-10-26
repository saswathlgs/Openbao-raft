remote_state {
  backend = "s3"   # or "http" pointing at GitLab-managed Terraform state
  config = {
    bucket         = "lingaasys-tofu-state"
    key            = "openbao-poc/terraform.tfstate"
    region         = "auto"
    encrypt        = true
    # Credentials from env — never in file
  }
}