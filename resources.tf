provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.36.0"
  skip_provider_registration = true

  subscription_id             = "6a29e3c2-50e1-48f1-bdda-a8301a5c72c1"
}
# Create a resource group
resource "azurerm_resource_group" "K8S" {
  name     = "K8S"
  location = "${var.location}"
}
resource "azurerm_availability_set" "avset_k8snodes" {
  name                = "avset_k8snodes"
  location = "${var.location}"
  managed = "true"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
  platform_fault_domain_count = 2
  platform_update_domain_count = 5
}
resource "azurerm_network_security_group" "sgroup_main" {
  name                = "sgroup_main"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
}
resource "azurerm_virtual_network" "vnet_main" {
  name                = "vnet_main"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["8.8.8.8", "8.8.4.4"]
  depends_on = [
		azurerm_network_security_group.sgroup_main
	]
}
resource "azurerm_subnet" "subnet_k8s" {
  name                 = "k8s"
  resource_group_name  = "${azurerm_resource_group.K8S.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet_main.name}"
  address_prefix       = "10.0.1.0/24"
  depends_on = [
		azurerm_virtual_network.vnet_main,
		azurerm_network_security_group.sgroup_main
	]
}
resource "azurerm_public_ip" "k8s-node-1-public" {
  name                = "k8s-node-1-public"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
  allocation_method   = "Dynamic"

}
resource "azurerm_public_ip" "k8s-master-1-public" {
  name                = "k8s-master-1-public"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
  allocation_method   = "Dynamic"

}
resource "azurerm_network_interface" "k8s-node-1" {
  name                = "k8s-node-1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet_k8s.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.k8s-node-1-public.id}"
  }
  depends_on = [
		azurerm_virtual_network.vnet_main,
		azurerm_network_security_group.sgroup_main,
    azurerm_public_ip.k8s-node-1-public
    ]
}
resource "azurerm_network_interface" "k8s-master-1" {
  name                = "k8s-master-1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "${azurerm_subnet.subnet_k8s.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = "${azurerm_public_ip.k8s-master-1-public.id}"
  }
  depends_on = [
		azurerm_virtual_network.vnet_main,
		azurerm_network_security_group.sgroup_main,
    azurerm_public_ip.k8s-master-1-public
    ]
}
resource "azurerm_virtual_machine" "k8s-node-1" {
  name                  = "k8s-node-1"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.K8S.name}"
  network_interface_ids = ["${azurerm_network_interface.k8s-node-1.id}"]
  vm_size               = "Standard_D2"
  availability_set_id = "${azurerm_availability_set.avset_k8snodes.id}"
  storage_image_reference {
    publisher = "credativ"
    offer     = "Debian"
    sku       = "9-backports"
    version   = "latest"
  }
  storage_os_disk {
    name              = "k8s-node-1-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb = "32"
  }
  os_profile {
    computer_name  = "k8s-node-1"
    admin_username = "k8sroot"
    admin_password = "${var.vm_password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  depends_on = [
		azurerm_network_interface.k8s-node-1,
		azurerm_virtual_network.vnet_main,
		azurerm_network_security_group.sgroup_main,
		azurerm_availability_set.avset_k8snodes
	]
}
resource "azurerm_virtual_machine" "k8s-master-1" {
  name = "k8s-master-1"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.K8S.name}"
  network_interface_ids = ["${azurerm_network_interface.k8s-master-1.id}"]
  vm_size               = "Standard_D2"
  storage_image_reference {
    publisher = "credativ"
    offer     = "Debian"
    sku       = "9-backports"
    version   = "latest"
  }
  storage_os_disk {
    name              = "k8s-master-1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb = "32"
  }
  os_profile {
    computer_name  = "k8s-master-1"
    admin_username = "k8sroot"
    admin_password = "${var.vm_password}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  depends_on = [
		azurerm_network_interface.k8s-master-1,
		azurerm_virtual_network.vnet_main,
		azurerm_network_security_group.sgroup_main,
		azurerm_availability_set.avset_k8snodes
	]
}