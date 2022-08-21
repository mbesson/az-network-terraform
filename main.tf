# Creating ressource group for main ressources of the project
resource "azurerm_resource_group" "main-rg" {
  name      = "lo3-we-lovelace-rg-001"
  location  = var.resource_group_location

  tags = {
    "environment" = "UAT"
    "project" = "Lovelace"
    "module" = "Main"
  }
}

# Creating ressource group for Databricks nodes
resource "azurerm_resource_group" "databricks-managed-rg" {
  name      = "lo3-we-lovelace-rg-002"
  location  = var.resource_group_location

  tags = {
    "environment" = "UAT"
    "project" = "Lovelace"
    "module" = "Databricks"
  }
}

# Creating ressource group for devops ressources
resource "azurerm_resource_group" "devops-rg" {
  name      = "lo3-we-devops-rg-001"
  location  = var.resource_group_location

  tags = {
    "environment" = "UAT"
    "project" = "Lovelace"
    "module" = "Devops"
  }
}

# Creating ressource group for network resources
resource "azurerm_resource_group" "network-rg" {
  name      = "lo3-we-network-rg-001"
  location  = var.resource_group_location

  tags = {
    "environment" = "UAT"
    "project" = "Lovelace"
    "module" = "Network"
  }
}

# Creating network ressources

# First we create the nsg rule
resource "azurerm_network_security_group" "nsg-001" {
  name                = "lo3-we-lovelace-nsg-001"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.network-rg.name

  tags = {
    "environment" = "UAT"
    "project" = "Lovelace"
    "module" = "Network"
  }
}

# Route table
resource "azurerm_route_table" "route-001" {
  name                          = "lo3-we-nrf-palo-peering-001"
  location                      = var.resource_group_location
  resource_group_name           = azurerm_resource_group.network-rg.name
  disable_bgp_route_propagation = false

  route {
    name           = "hubvNetPalo"
    address_prefix = "10.230.0.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.230.0.38"
  }

  route {
    name           = "InternetPalo"
    address_prefix = "10.1.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.230.0.38"
  }

  route {
    name           = "ManagementNone"
    address_prefix = "10.230.0.0/28"
    next_hop_type  = "None"
  }

  tags = {
    "environment" = "UAT"
    "project" = "Lovelace"
    "module" = "Network"
  }
}

# The main vnet
resource "azurerm_virtual_network" "main-vnet" {
  name                = "lo3-we-lovelace-vnet-001"
  address_space       = ["10.230.5.0/24"]
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.network-rg.name
}

# The main subnet
resource "azurerm_subnet" "main-subnet" {
  name                 = "lo3-we-lovelace-sub-001"
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.230.5.0/25"]
}

# The public subnet for Databricks
resource "azurerm_subnet" "pub-subnet" {
  name                 = "lo3-we-lovelace-sub-pub-001"
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.230.5.128/26"]
}

resource "azurerm_subnet_network_security_group_association" "pub-nsg-association" {
  subnet_id                 = azurerm_subnet.pub-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-001.id
}

# The private subnet for Databricls
resource "azurerm_subnet" "prv-subnet" {
  name                 = "lo3-we-lovelace-sub-prv-001"
  resource_group_name  = azurerm_resource_group.network-rg.name
  virtual_network_name = azurerm_virtual_network.main-vnet.name
  address_prefixes     = ["10.230.5.192/26"]
}

resource "azurerm_subnet_network_security_group_association" "prv-nsg-association" {
  subnet_id                 = azurerm_subnet.prv-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-001.id
}

# Create storage account
resource "azurerm_storage_account" "datalake" {
  name                     = "lo3westsav2001"
  resource_group_name      = azurerm_resource_group.main-rg.name
  location                 = var.resource_group_location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind = "StorageV2"
  shared_access_key_enabled = true

  tags = {
    "environment" = "UAT"
    "project" = "Lovelace"
    "module" = "Main"
  }
}

# Key vault for datalake usage
resource "azurerm_key_vault" "kv-datalake" {
  name                        = "lo3-we-kv-dlk-001"
  location                    = var.resource_group_location
  resource_group_name         = azurerm_resource_group.main-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"
}

# Key vault for devops usage in current projects
resource "azurerm_key_vault" "kv-devops" {
  name                        = "lo3-we-kv-devops-002"
  location                    = var.resource_group_location
  resource_group_name         = azurerm_resource_group.devops-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

  sku_name = "standard"
}

# Datafactory
resource "azurerm_data_factory" "adf" {
  name                = "lo3-we-adf-001-main"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.main-rg.name
}