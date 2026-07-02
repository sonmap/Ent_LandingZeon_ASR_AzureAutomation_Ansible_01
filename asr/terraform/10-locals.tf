locals {
  tags = {
    Environment = var.environment
    Purpose     = "asr-dr-automation"
    Owner       = var.owner
  }
}
