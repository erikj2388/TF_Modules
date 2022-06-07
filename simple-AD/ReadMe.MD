# Simple AD

This Module will spin up infrastructure for a single Domain Controller.

Creates Resource Group, VNet, Public IP, OS Disk, and NSG to allow RDP access.

Update variables as necessary in the .tfvars file.

## Contents

- main.tf
  - the main terraform config file (don't edit unless you know what u are doing)
- variables.tf
  - definition of all variables used in main.tf (you don't want to edit this too)
- terraform.tfvars
  - use this file to set the variables defined in variables.tf.

## Usage

The easiest way to use terraform in Azure is through azure cloud shell, since it already includes terraform and you don't have to create an extra security principal for terraform to interact with your tenant. This is a good thing, espescially since we are talking about directory security here - a secure service account is the one we never create ;-)

So open cloudshell from the azure portal and clone the repository.

```
git clone https://github.com/erikj2388/TF_Modules.git
cd ./TF_Modules/simple-AD/
```

Make sure you are okay with the defaults (Azure location, VM size, admin user and password...)

```
code ./terraform.tfvars
```

And when you're ready: initialize terraform and apply - thats it


## Default Settings
node_location_dc   = "eastus"
vmsize_dc = "Standard_D2s_v3"
active_directory_domain = "erikstestlab.com"
active_directory_netbios_name = "ERIKSTESTLAB"
domadminuser = "adminuser"
domadminpassword = "P@ssw0rd123!!!"
safemode_password = "P@ssw0rd123!!!"

adminuser = "adminuser"
adminpassword = "P@ssw0rd123!"
