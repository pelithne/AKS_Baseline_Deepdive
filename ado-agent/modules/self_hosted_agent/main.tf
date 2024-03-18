resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = var.ip_configuration_name
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation_method
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.vm_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.image_version
  }

  storage_os_disk {
    name              = var.os_disk_name
    caching           = var.os_disk_caching
    create_option     = var.os_disk_create_option
  }

  os_profile {
    computer_name  = var.computer_name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
} 

resource "azurerm_virtual_machine_extension" "vm_extension" {
  name                 = var.vm_extension_name
  virtual_machine_id   = azurerm_virtual_machine.vm.id
  publisher            = var.vm_extension_publisher
  type                 = var.vm_extension_type
  type_handler_version = var.vm_extension_type_handler_version

  settings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/abengtss-max/private-aks-cluster-terraform-devops/main/agent/scripts/configure-self-hosted-agent.sh"],
        "commandToExecute": "sudo bash configure-self-hosted-agent.sh '${var.vm_user}' '${var.org_service_url}' '${var.personal_access_token}' '${var.azp_pool}'"       
    }
SETTINGS
}
