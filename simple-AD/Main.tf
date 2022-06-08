##########################################################
# Configure the Azure Provider
##########################################################
provider "azurerm" {
  features {}
}

##########################################################
# Create base infrastructure for DC
##########################################################

# resource group
resource "azurerm_resource_group" "dc_rg" {
  name     = "${var.resource_prefix}-DC-RG"
  location = var.node_location_dc
  tags = var.tags
}

# virtual network within the resource group
resource "azurerm_virtual_network" "dc_vnet" {
  name                = "${var.resource_prefix}-dc-vnet"
  resource_group_name = azurerm_resource_group.dc_rg.name
  location            = var.node_location_dc
  address_space       = var.node_address_space_dc
  dns_servers         = [cidrhost(var.node_address_prefix_dc, 10)]
  tags = var.tags
}

# subnet within the virtual network
resource "azurerm_subnet" "dc_subnet" {
  name                 = "${var.resource_prefix}-dc-subnet"
  resource_group_name  = azurerm_resource_group.dc_rg.name
  virtual_network_name = azurerm_virtual_network.dc_vnet.name
  address_prefixes       = [var.node_address_prefix_dc]

}

# public ip - dc
resource "azurerm_public_ip" "dc_public_ip" {
  name = "${var.resource_prefix}-DC-PublicIP"
  location            = azurerm_resource_group.dc_rg.location
  resource_group_name = azurerm_resource_group.dc_rg.name
  allocation_method   = "Dynamic"
  tags = var.tags
}

# network interface - dc
resource "azurerm_network_interface" "dc_nic" {
  name = "${var.resource_prefix}-DC-NIC"
  location            = azurerm_resource_group.dc_rg.location
  resource_group_name = azurerm_resource_group.dc_rg.name
  tags = var.tags

  ip_configuration {
    name      = "internal"
    subnet_id = azurerm_subnet.dc_subnet.id
    #private_ip_address_allocation = "Dynamic"
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.node_address_prefix_dc, 10)
    public_ip_address_id          = azurerm_public_ip.dc_public_ip.id
  }
}

# NSG DC
resource "azurerm_network_security_group" "dc_nsg" {

  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.dc_rg.location
  resource_group_name = azurerm_resource_group.dc_rg.name

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

# Subnet and NSG association DC
resource "azurerm_subnet_network_security_group_association" "dc_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.dc_subnet.id
  network_security_group_id = azurerm_network_security_group.dc_nsg.id

}
#VM object for the DC - contrary to the member server, this one is static so there will be only a single DC
resource "azurerm_windows_virtual_machine" "windows_vm_domaincontroller" {
  name  = "${var.resource_prefix}-dc"
  location              = azurerm_resource_group.dc_rg.location
  resource_group_name   = azurerm_resource_group.dc_rg.name
  network_interface_ids = [azurerm_network_interface.dc_nic.id]
  size                  = var.vmsize_dc
  admin_username        = var.domadminuser
  admin_password        = var.domadminpassword

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}

##########################################################
## Define VM extensions to install ADDS and join member
##########################################################

# Promote VM to be a Domain Controller
# based on https://github.com/ghostinthewires/terraform-azurerm-promote-dc

locals { 
  import_command       = "Import-Module ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString ${var.safemode_password} -AsPlainText -Force"
  install_ad_command   = "Add-WindowsFeature -name ad-domain-services -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command     = "shutdown -r -t 10"
  disable_fw           = "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"
  set_timezone         = "Set-TimeZone -id '${var.timezone}'"
  exit_code_hack       = "exit 0"
  powershell_command   = "${local.disable_fw}; ${local.set_timezone}; ${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"

}

resource "azurerm_virtual_machine_extension" "create-active-directory-forest" {
  name                 = "create-active-directory-forest"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_vm_domaincontroller.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}