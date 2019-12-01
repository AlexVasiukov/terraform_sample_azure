variable "location" {
  type = "string"
}
variable "vm_password" {
  type = "string"
}
variable "ssh_key_home" {
  type = "string"
}
#data "azurerm_public_ip" "k8s-node-1-public" {
#  name                = "k8s-node-1-public"
#  resource_group_name = "${azurerm_resource_group.K8S.name}"
#}
#data "azurerm_public_ip" "k8s-master-1-public" {
#  name                = "k8s-master-1-public"
#  resource_group_name = "${azurerm_resource_group.K8S.name}"
#}
