locals {
  prefix      = "${var.prefix}-api"
  common_tags = merge(var.common_tags, {
    module = "Terraform AWS Lambda API"
  })
}
