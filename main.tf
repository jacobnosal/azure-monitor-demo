resource "azurerm_resource_group" "monitoring_rg" {
  name     = "demo-rg-monitoring"
  location = var.location

  tags = var.tags
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "demo-workspace"
  location            = azurerm_resource_group.monitoring_rg.location
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  sku                 = "PerGB2018"

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "log_analytics_workspace_diagnostic_setting" {
  name                           = "${azurerm_log_analytics_workspace.workspace.name}-diagnostic-setting"
  target_resource_id             = azurerm_log_analytics_workspace.workspace.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.workspace.id
  log_analytics_destination_type = "Dedicated"

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.log_analytics_workspace_diagnostic_catgeories.logs
    content {
      category = log.value
      enabled  = true
      retention_policy {
        enabled = true
        days    = var.log_retention_in_days
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.log_analytics_workspace_diagnostic_catgeories.metrics
    content {
      category = metric.value
      enabled  = true
      retention_policy {
        enabled = true
        days    = var.metric_retention_in_days
      }
    }
  }
}

resource "azurerm_resource_group" "demo_rg" {
  name     = "demo-rg"
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "network" {
  name                = "demo-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.demo_rg.location
  resource_group_name = azurerm_resource_group.demo_rg.name

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "network_diagnostic_setting" {
  name                           = "${azurerm_virtual_network.network.name}-diagnostic-setting"
  target_resource_id             = azurerm_virtual_network.network.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.workspace.id
  log_analytics_destination_type = "Dedicated"

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.demo_network_diagnostic_catgeories.logs
    content {
      category = log.value
      enabled  = true
      retention_policy {
        enabled = true
        days    = var.log_retention_in_days
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.demo_network_diagnostic_catgeories.metrics
    content {
      category = metric.value
      enabled  = true
      retention_policy {
        enabled = true
        days    = var.metric_retention_in_days
      }
    }
  }
}

module "virtual_machines" {
  source                         = "./modules/virtual_machines"
  location                       = var.location
  tags                           = var.tags
  monitoring_resource_group_name = azurerm_resource_group.monitoring_rg.name
  demo_resource_group_name       = azurerm_resource_group.demo_rg.name
  demo_network_name              = azurerm_virtual_network.network.name
  log_analytics_workspace_name   = azurerm_log_analytics_workspace.workspace.name

  depends_on = [
    azurerm_log_analytics_workspace.workspace,
    azurerm_virtual_network.network,
    azurerm_resource_group.monitoring_rg,
    azurerm_resource_group.demo_rg
  ]

  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
}