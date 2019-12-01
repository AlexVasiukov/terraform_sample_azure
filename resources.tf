provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.36.0"
  skip_provider_registration = true

  subscription_id             = "6a29e3c2-50e1-48f1-bdda-a8301a5c72c1"
}
# Create a resource group
resource "azurerm_resource_group" "K8S" {
  name     = "K8S"
  location = "West US"
}