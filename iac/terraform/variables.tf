variable "subscription_id" {
  type        = string
  description = "The Azure subscription ID."
}
variable "create_resource_group" {
  type        = bool
  description = "Specify if you want to create a resource group. Accepted values are true or false."
}
variable "location" {
  type        = string
  description = "The Azure region where the resource group should get created. e.g. East US, West US 2, Central US, etc."
}
variable "resource_group_name" {
  type        = string
  description = "The name of the resource group that would be used, it will be created if 'create_resource_group' is set as true."
}