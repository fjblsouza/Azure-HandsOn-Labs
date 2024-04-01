terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.97.1"
    }
  }
}

provider "azurerm" {
 skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
 features {}
/*
  subscription_id   = "<azure_subscription_id>"
  tenant_id         = "<azure_subscription_tenant_id>"
  client_id         = "<service_principal_appid>"
  client_secret     = "<service_principal_password>"
*/
}

resource "azurerm_resource_group" "aks_demo_rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_virtual_network" "aksdemo-vnet" {
  name                = "aksdemovnet"
  location            = azurerm_resource_group.aks_demo_rg.location
  resource_group_name = azurerm_resource_group.aks_demo_rg.name
  address_space       = ["10.1.0.0/16"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.1.1.0/24"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "WinCluster"
  location            = azurerm_resource_group.aks_demo_rg.location
  resource_group_name = azurerm_resource_group.aks_demo_rg.name
  dns_prefix = "wincluster"

  default_node_pool {
    name           = "linux"
    node_count     = var.node_count_linux
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = element(tolist(azurerm_virtual_network.aksdemo-vnet.subnet),0).id
  }

  windows_profile {
    admin_username = "demouser"
    admin_password = "D3m0Us3R@!2024"
  }
  
  network_profile {
    network_plugin = "azure"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "win" {
  name                  = "wspool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2s_v3"
  node_count            = var.node_count_windows
  os_type               = "Windows"
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}