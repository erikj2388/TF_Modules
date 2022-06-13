## General stuff
# prefix for your lab, this will be prepended to all resources

variable "resource_prefix" {
  type = string
}

# tags to apply to all resources

variable "tags" {
  description = "Tags to apply on resource"
  type        = map(string)
}

## Variables for DC
# azure location for dc

variable "node_location_win10vm" {
  type = string
}

# vnet address space

variable "node_address_space_win10vm" {
  default = ["10.100.0.0/16"]
}

# subnet range

variable "node_address_prefix_win10vm" {
  default = "10.100.100.0/24"
}

variable "vmsize_win10vm" {
  type = string
}

# local admin credentials

variable "adminpassword" {
  type = string
}

variable "adminuser" {
  type = string
}

#Time zone for VMs
variable "timezone" {
  type = string
}