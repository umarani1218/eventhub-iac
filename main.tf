provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "test-resource-group"
  location = "East US"
}

# Define the namespace and event hub configurations
variable "namespaces" {
  default = [
    {
      name                = "namespacea"
      location            = "East US"
      sku                 = "Standard"
      capacity            = 1
      eventhubs = [
        {
          name                = "eventhuba"
          partition_count     = 2
          message_retention   = 1
        },
        {
          name                = "eventhubb"
          partition_count     = 4
          message_retention   = 1
        }
      ]
    },
    {
      name                = "namespaceb"
      location            = "East US"
      sku                 = "Basic"
      capacity            = 1
      eventhubs = [
        {
          name                = "eventhubc"
          partition_count     = 3
          message_retention   = 1
        },
        {
          name                = "eventhubd"
          partition_count     = 2
          message_retention   = 1
        }
      ]
    }
  ]
}

# Create namespaces dynamically
resource "azurerm_eventhub_namespace" "namespace" {
  count               = length(var.namespaces)

  name                = var.namespaces[count.index].name
  resource_group_name = azurerm_resource_group.example.name
  location            = var.namespaces[count.index].location
  sku                 = var.namespaces[count.index].sku
  capacity            = var.namespaces[count.index].capacity
}

# Flatten event hubs for easier iteration
locals {
  flattened_eventhubs = flatten([for ns in var.namespaces : [for eh in ns.eventhubs : { namespace_name = ns.name, eventhub = eh }]])
}

# Create event hubs
resource "azurerm_eventhub" "eventhub" {
  count = length(local.flattened_eventhubs)

  name                = local.flattened_eventhubs[count.index].eventhub.name
  namespace_name      = local.flattened_eventhubs[count.index].namespace_name
  partition_count     = local.flattened_eventhubs[count.index].eventhub.partition_count
  message_retention   = local.flattened_eventhubs[count.index].eventhub.message_retention
  resource_group_name = azurerm_resource_group.example.name
  depends_on = [ resource.azurerm_eventhub_namespace.namespace ]
}