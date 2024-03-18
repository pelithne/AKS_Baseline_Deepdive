variable "nic_name" {
  description = "The name of the network interface card"
  default     = "agent-nic"
  type        = string
}

variable "location" {
  description = "The location/region of the resource"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "ip_configuration_name" {
  description = "The name of the IP configuration"
  default = "agent-ip-configuration"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet"
  type        = string
}

variable "private_ip_address_allocation_method" {
  description = "the private IP address allocation method"
  default     = "Dynamic"
  type        = string
}

variable "vm_name" {
  description = "The name of the virtual machine"
  default     = "agent-vm"
  type        = string
}

variable "vm_size" {
  description = "The size of the virtual machine"
  default     = "Standard_D2s_v3"
  type        = string
}

variable "os_disk_name" {
  description = "The name of the OS disk"
  default     = "osdisk"
  type        = string
}

variable "os_disk_caching" {
  description = "The caching of the OS disk"
  default     = "ReadWrite"
  type        = string
}

variable "os_disk_create_option" {
  description = "The create option of the OS disk"
  default     = "FromImage"
  type        = string
}

variable "publisher" {
  description = "The publisher of the image"
  default     = "Canonical"
  type        = string
}

variable "offer" {
  description = "The offer of the image"
  default     = "0001-com-ubuntu-server-jammy"
  type        = string
}

variable "sku" {
  description = "The SKU of the image"
  default     = "22_04-lts-gen2"
  type        = string
}

variable "image_version" {
  description = "The version of the image"
  default     = "latest"
  type        = string
}

variable "computer_name" {
  description = "The name of the computer"
  type        = string
}


variable "admin_password" {
  description = "The password of the admin"
  type        = string
}
variable "admin_username" {
  description = "The username of the admin"
  default     = "azureuser"
  type        = string
}

variable "script_path" {
  description = "The path to the script file"
  type        = string
  default     = "/script/configure-self-hosted-agent.sh"
}

variable "vm_user" {
  description = "The username of the virtual machine"
  default     = "azureuser"
  type        = string
}

variable "org_service_url" {
  description = "The Azure DevOps organization URL"
}

variable "personal_access_token" {
  description = "The personal access token for Azure DevOps"
}

variable "azp_pool" {
  description = "The pool of the Azure DevOps organization"
  type        = string
}

variable "vm_extension_name" {
  description = "The name of the extension"
  type        = string
}

variable "vm_extension_publisher" {
  description = "The publisher of the extension"
  default     = "Microsoft.Azure.Extensions"
  type        = string
}

variable "vm_extension_type" {
  description = "The type of the extension"
  default     = "CustomScript"
  type        = string
}

variable "vm_extension_version" {
  description = "The version of the extension"
  default     = "2.0"
  type        = string
}

variable "vm_extension_type_handler_version" {
  description = "The type handler version of the extension"
  default     = "2.0"
  type        = string
}


