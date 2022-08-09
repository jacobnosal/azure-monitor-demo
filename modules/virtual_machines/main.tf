resource "azurerm_log_analytics_solution" "law_s" {
  solution_name         = "VMInsights"
  location              = data.azurerm_log_analytics_workspace.law.location
  resource_group_name   = var.monitoring_resource_group_name
  workspace_resource_id = data.azurerm_log_analytics_workspace.law.id
  workspace_name        = data.azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }

  tags = var.tags
}

resource "azurerm_resource_group" "vm_rg" {
  name     = "demo-rg-vm"
  location = var.location

  tags = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "demo-vm"
  resource_group_name  = var.demo_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.demo-network.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "random_password" "windows_vm_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}