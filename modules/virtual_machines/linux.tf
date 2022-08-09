resource "azurerm_network_interface" "linux_vm_nic" {
  name                = "example-nic"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "demo-vm-linux"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.linux_vm_nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = var.tags
}

# TODO: azure monitor agent extension
resource "azurerm_virtual_machine_extension" "azure_monitor_agent_extension" {
  name                       = "AzureMonitorAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.linux_vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.15"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  tags                       = var.tags
}

# TODO: azure monitor dependency agent extension
resource "azurerm_virtual_machine_extension" "azure_monitor_dependency_agent_extension" {
  name                       = "AzureMonitorDependencyAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.linux_vm.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  tags                       = var.tags
}

# Microsoft.EnterpriseCloud.Monitoring.OmsAgentForLinux
resource "azurerm_virtual_machine_extension" "oms_agent_linux_extension" {
  name                       = "OMSAgentForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.linux_vm.id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "OmsAgentForLinux"
  type_handler_version       = "1.14"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  tags                       = var.tags

  settings = <<-BASE_SETTINGS
  {
    "workspaceId" : "${data.azurerm_log_analytics_workspace.law.workspace_id}"
  }
  BASE_SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
  {
    "workspaceKey" : "${data.azurerm_log_analytics_workspace.law.primary_shared_key}"
  }
  PROTECTED_SETTINGS
}

# TODO: data collection rule
resource "azurerm_monitor_data_collection_rule" "linux_vm" {
  name                = "${azurerm_linux_virtual_machine.linux_vm.name}-dcr"
  resource_group_name = azurerm_resource_group.vm_rg.name
  location            = azurerm_resource_group.vm_rg.location
  kind                = "Linux"

  destinations {
    log_analytics {
      workspace_resource_id = data.azurerm_log_analytics_workspace.law.id
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
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["logs_dest"]
  }

  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["*"]
      name           = "source_syslog"
    }

    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 10
      counter_specifiers            = ["*"]
      name                          = "source_perfcounter"
    }
  }

  description = "data collection rule example"
  tags        = var.tags
  depends_on = [
    azurerm_log_analytics_solution.law_s
  ]
}

# TODO: data collection rule association
resource "azapi_resource" "example_dcr_association" {
  name      = "${azurerm_linux_virtual_machine.linux_vm.name}-dcr-assoc"
  parent_id = azurerm_linux_virtual_machine.linux_vm.id
  type      = "Microsoft.Insights/dataCollectionRuleAssociations@2021-04-01"
  body = jsonencode({
    properties = {
      dataCollectionRuleId = azurerm_monitor_data_collection_rule.linux_vm.id
    }
  })
}