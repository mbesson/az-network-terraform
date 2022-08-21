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

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
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

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "prv-nsg-association" {
  subnet_id                 = azurerm_subnet.prv-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg-001.id
}