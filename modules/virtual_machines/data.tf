data "azurerm_log_analytics_workspace" "law" {
  resource_group_name = var.monitoring_resource_group_name
  name                = var.log_analytics_workspace_name
}

data "azurerm_virtual_network" "demo-network" {
  name                = var.demo_network_name
  resource_group_name = var.demo_resource_group_name
}