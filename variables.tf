variable "azure_client_id" {}
variable "azure_client_secret" {}
variable "azure_subscription_id" {}
variable "azure_tenant_id" {}

variable "location" {
  description = "(Optional) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  default     = "eastus"
  type        = string
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the resource."
  default = {
    environment = "demo"
  }
  type = map(any)
}

variable "log_retention_in_days" {
  default     = 10
  description = "(Optional) The number of days for which this Retention Policy should apply. Values may range 0 (Indefinite retention) to 730 days, inclusive."
  type        = number
}

variable "metric_retention_in_days" {
  default     = 10
  description = "(Optional) The number of days for which this Retention Policy should apply. Values may range 0 (Indefinite retention) to 730 days, inclusive."
  type        = number
}

variable "admin_ssh_key_file" {
  description = "Filepath for admin ssh key."
  type        = string
}