provider "azurerm" {
  features {}
}

module "resource_group" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
}

module "virtual_network" {
  source              = "./modules/virtual_network"
  resource_group_name = module.resource_group.name
  location            = var.location
  virtual_network_name = var.virtual_network_name
  vnet_address_space  = [var.vnet_address_space]
  subnet_name         = var.subnet_name
  subnet_address_prefixes = [var.subnet_address_prefixes]
}

module "self_hosted_agent" {
  source              = "./modules/self_hosted_agent"
  resource_group_name = module.resource_group.name
  location            = var.location
  subnet_id           = module.virtual_network.subnet_id.id
  script_path         = "${path.module}/script/configure-self-hosted-agent.sh"
  admin_password      = var.admin_password
  org_service_url     = var.org_service_url
  personal_access_token = var.personal_access_token
  azp_pool            = var.azp_pool
  vm_extension_name   = var.vm_extension_name
  computer_name       = var.computer_name
}
