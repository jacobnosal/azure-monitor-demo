# Args for terraform-acme-msftcerts
variable "registration_email" {
  description = "Email to register with ACME for this cert."
}

variable "domain_name" {
  description = "DNS name of the certificate subject."
}

variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_dns_resource_group" {}
variable "azure_subscription_id" {}
variable "azure_tenant_id" {}
variable "azure_dns_zone_name" {}

variable "location" {
  default = "eastus"
}

variable "tags" {
  default = {
    environment = "demo"
  }
}