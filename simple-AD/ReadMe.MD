Simple AD

This Module will spin up infrastructure for a single Domain Controller.

Creates Resource Group, VNet, Public IP, OS Disk, and NSG to allow RDP access.

Update variables as necessary in the .tfvars file.

node_location_dc   = "eastus"
vmsize_dc = "Standard_D2s_v3"
active_directory_domain = "erikstestlab.com"
active_directory_netbios_name = "ERIKSTESTLAB"
domadminuser = "adminuser"
domadminpassword = "P@ssw0rd123!!!"
safemode_password = "P@ssw0rd123!!!"

adminuser = "adminuser"
adminpassword = "P@ssw0rd123!"
