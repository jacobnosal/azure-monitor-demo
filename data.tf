data "azurerm_client_config" "current" {}

data "azurerm_monitor_diagnostic_categories" "demo_network_diagnostic_catgeories" {
  resource_id = azurerm_virtual_network.network.id
}

data "azurerm_monitor_diagnostic_categories" "log_analytics_workspace_diagnostic_catgeories" {
  resource_id = azurerm_log_analytics_workspace.workspace.id
}