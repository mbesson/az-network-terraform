variable "subscription_id" {
  type     = string
  nullable = false
  description = "The id of the subscription you want to deply in."
}

variable "client_id" {
  type     = string
  nullable = false
  description = "The client id of the service principal used for Azure authentication."
}

variable "client_secret" {
  type     = string
  nullable = false
  description = "The client secret of the service principal used for Azure authentication."
}

variable "tenant_id" {
  type     = string
  nullable = false
  description = "The tenant id where your subscription lives in."
}

variable "resource_group_name_prefix" {
  default       = "rg"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default = "eastus"
  description   = "Location of the resource group."
}