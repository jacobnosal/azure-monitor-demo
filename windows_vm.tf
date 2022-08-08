resource "azurerm_network_interface" "windows_vm_nic" {
  name                = "windows_vm_nic"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "windows_vm_internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "windows-vm"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.windows_vm_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

# TODO: azure monitor agent extension
resource "azurerm_virtual_machine_extension" "azure_monitor_agent_windows_extension" {
  name                       = "AzureMonitorAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.2"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  tags                       = var.tags
}

# TODO: azure monitor dependency agent extension
resource "azurerm_virtual_machine_extension" "azure_monitor_windows_dependency_agent_extension" {
  name                       = "AzureMonitorDependencyAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.10"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  tags                       = var.tags
}

# Microsoft.EnterpriseCloud.Monitoring.OmsAgentForLinux
resource "azurerm_virtual_machine_extension" "oms_agent_Windows_extension" {
  name                       = "Windows_MMA"
  virtual_machine_id         = azurerm_windows_virtual_machine.example.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  tags                       = var.tags

  settings = <<-BASE_SETTINGS
  {
    "workspaceId" : "${azurerm_log_analytics_workspace.law.workspace_id}"
  }
  BASE_SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
  {
    "workspaceKey" : "${azurerm_log_analytics_workspace.law.primary_shared_key}"
  }
  PROTECTED_SETTINGS
}

# # TODO: data collection rule
resource "azurerm_monitor_data_collection_rule" "windows_vm" {
  name                = "${azurerm_windows_virtual_machine.example.name}-dcr"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "logs_dest"
    }

    azure_monitor_metrics {
      name = "metrics_dest"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["metrics_dest"]
  }

  data_flow {
    streams      = ["Microsoft-Event"]
    destinations = ["logs_dest"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 10
      counter_specifiers            = ["*"]
      name                          = "perfcounter"
    }

    windows_event_log {
      streams = ["Microsoft-Event"]
      x_path_queries = [
        "Application!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=5)]]",
        "Security!*[System[(band(Keywords,13510798882111488))]]",
        "System!*[System[(Level=1 or Level=2 or Level=3 or Level=4 or Level=5)]]"
      ]
      name = "wineventlog"
    }
  }

  description = "Windows data collection rule example."
  tags        = var.tags
  depends_on = [
    azurerm_log_analytics_solution.law_s
  ]
}

resource "azapi_resource" "windows_example_dcr_association" {
  name      = "${azurerm_windows_virtual_machine.example.name}-dcr-assoc"
  parent_id = azurerm_windows_virtual_machine.example.id
  type      = "Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01"
  body = jsonencode({
    properties = {
      dataCollectionRuleId = azurerm_monitor_data_collection_rule.windows_vm.id
    }
  })
}