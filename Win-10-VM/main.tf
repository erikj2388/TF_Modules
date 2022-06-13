##########################################################
# Configure the Azure Provider
##########################################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.10.0"
    }
  }

  backend "azurerm" {
        resource_group_name  = "terraformfstate"
        storage_account_name = "tfstate821479423"
        container_name       = "tfstate-simple-ad"
        key                  = "win10-terraform.tfstate"
    }

}

provider "azurerm" {
  features {}
}

##########################################################
# Create base infrastructure for WIN10VM
##########################################################

# resource group
resource "azurerm_resource_group" "win10vm_rg" {
  name     = "${var.resource_prefix}-Win10-VM"
  location = var.node_location_win10vm
  tags = var.tags
}

# virtual network within the resource group
resource "azurerm_virtual_network" "win10vm_vnet" {
  name                = "${var.resource_prefix}-win10vm-vnet"
  resource_group_name = azurerm_resource_group.win10vm_rg.name
  location            = var.node_location_win10vm
  address_space       = var.node_address_space_win10vm
  tags = var.tags
}

# subnet within the virtual network
resource "azurerm_subnet" "win10vm_subnet" {
  name                 = "${var.resource_prefix}-win10vm-subnet"
  resource_group_name  = azurerm_resource_group.win10vm_rg.name
  virtual_network_name = azurerm_virtual_network.win10vm_vnet.name
  address_prefixes       = [var.node_address_prefix_win10vm]

}

# public ip - WIN10VM
resource "azurerm_public_ip" "win10vm_public_ip" {
  name = "${var.resource_prefix}-WIN10VM-PublicIP"
  location            = azurerm_resource_group.win10vm_rg.location
  resource_group_name = azurerm_resource_group.win10vm_rg.name
  allocation_method   = "Dynamic"
  tags = var.tags
}

# network interface - WIN10VM
resource "azurerm_network_interface" "win10vm_nic" {
  name = "${var.resource_prefix}-win10vm-NIC"
  location            = azurerm_resource_group.win10vm_rg.location
  resource_group_name = azurerm_resource_group.win10vm_rg.name
  tags = var.tags

  ip_configuration {
    name      = "internal"
    subnet_id = azurerm_subnet.win10vm_subnet.id
    #private_ip_address_allocation = "Dynamic"
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.node_address_prefix_win10vm, 10)
    public_ip_address_id          = azurerm_public_ip.win10vm_public_ip.id
  }
}

# NSG WIN10VM
resource "azurerm_network_security_group" "win10vm_nsg" {

  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.win10vm_rg.location
  resource_group_name = azurerm_resource_group.win10vm_rg.name

  # Security rule can also be defined with resource azurerm_network_security_rule, here just defining it inline.
  security_rule {
    name                       = "Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.tags

}

# Subnet and NSG association WIN10 VM
resource "azurerm_subnet_network_security_group_association" "win10vm_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.win10vm_subnet.id
  network_security_group_id = azurerm_network_security_group.win10vm_nsg.id

}
#VM object for the DC - contrary to the member server, this one is static so there will be only a single DC
resource "azurerm_windows_virtual_machine" "windows_vm_win10vm" {
  name  = "${var.resource_prefix}-win10vm"
  location              = azurerm_resource_group.win10vm_rg.location
  resource_group_name   = azurerm_resource_group.win10vm_rg.name
  network_interface_ids = [azurerm_network_interface.win10vm_nic.id]
  size                  = var.vmsize_win10vm
  admin_username        = var.adminuser
  admin_password        = var.adminpassword

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-pro-g2"
    version   = "latest"
  }

  tags = var.tags
}

# Promote VM to be a Domain Controller
# based on https://github.com/ghostinthewires/terraform-azurerm-promote-dc

locals { 
  disable_fw           = "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"
  set_timezone         = "Set-TimeZone -id '${var.timezone}'"
  exit_code_hack       = "exit 0"
  powershell_command_disable_fw   = "${local.disable_fw}; ${local.set_timezone}; ${local.exit_code_hack}"
}
resource "azurerm_virtual_machine_extension" "disable_fw_member" {
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm_win10vm.id
  name                 = "disable_fw"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command_disable_fw}\""
    }
SETTINGS
}