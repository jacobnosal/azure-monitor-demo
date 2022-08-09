variable "location" {
  description = "Region for resources to be provisioned in."
  type        = string
}

variable "monitoring_resource_group_name" {
  description = "Name of the resource group for monitoring infrastructure."
  type        = string
}

variable "demo_resource_group_name" {
  description = "Name of the resource group for demo resources."
  type        = string
}

variable "demo_network_name" {
  description = "Name of the vitrual network for demo resources."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the log analytics workspace."
  type        = string
}

variable "tags" {
  description = "Tags for all resources."
}