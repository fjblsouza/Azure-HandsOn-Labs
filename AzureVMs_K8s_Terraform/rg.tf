resource "azurerm_resource_group" "k8s_lab" {
  name     = "1-42b7e251-playground-sandbox" # Change to your existing rg
  location = "South Central US"  # Change to your desired location
}