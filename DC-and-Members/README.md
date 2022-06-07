Simple AD

This Module will spin up infrastructure for a single Domain Controller in a VNet with 2 member VMs in a separate VNet.
VNets are Peered and RDP access is enabled to all three.

Creates Resource Groups, VNets, Public IPs, OS Disks, and NSG to allow RDP access.

Update variables as necessary in the .tfvars file.

node_location_dc   = "eastus"
vmsize_dc = "Standard_D2s_v3"
active_directory_domain = "erikstestlab.com"
active_directory_netbios_name = "ERIKSTESTLAB"
domadminuser = "adminuser"
domadminpassword = "P@ssw0rd123!!!"
safemode_password = "P@ssw0rd123!!!"

node_location_member = "eastus"
vmsize_member = "Standard_D2s_v3"
node_count = 2
adminuser = "adminuser"
adminpassword = "P@ssw0rd123!"
