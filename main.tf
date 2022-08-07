# TODO: monitoring resource group
resource "azurerm_resource_group" "monitoring_rg" {
  name     = "demo-rg-monitoring"
  location = var.location

  tags = var.tags
}

# TODO: log analytics workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "demo-workspace"
  location            = azurerm_resource_group.monitoring_rg.location
  resource_group_name = azurerm_resource_group.monitoring_rg.name
  sku                 = "PerGB2018"

  tags = var.tags
}

# TODO: log analytics solution
resource "azurerm_log_analytics_solution" "law_s" {
  solution_name         = "VMInsights"
  location              = azurerm_resource_group.monitoring_rg.location
  resource_group_name   = azurerm_resource_group.monitoring_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }

  tags = var.tags
}

# TODO: virtual machine resource group
resource "azurerm_resource_group" "vm_rg" {
  name     = "demo-rg-vm"
  location = var.location

  tags = var.tags
}

# TODO: virtual machine
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  tags = var.tags
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.vm_rg.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]

  tags = var.tags
}

resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-machine"
  location            = azurerm_resource_group.vm_rg.location
  resource_group_name = azurerm_resource_group.vm_rg.name
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.example.id,
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
    sku       = "20.04-LTS"
    version   = "latest"
  }

  tags = var.tags
}

# TODO: azure monitor agent extension
resource "azurerm_virtual_machine_extension" "example" {
  name                 = "AzureMonitorAgent"
  virtual_machine_id   = azurerm_linux_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.15"
  tags                 = var.tags
}

# TODO: azure monitor dependency agent extension
resource "azurerm_virtual_machine_extension" "example" {
  name                       = "AzureMonitorDependencyAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.example.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  tags                       = var.tags
}

# TODO: data collection rule


# TODO: data collection rule association