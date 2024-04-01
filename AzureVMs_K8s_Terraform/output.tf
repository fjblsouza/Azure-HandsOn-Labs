#############################################
## Azure Linux VMs - Output ##
#############################################

output "resource_group_name" {
  value = azurerm_resource_group.k8s_lab.name
}

output "control_public_ip_address" {
  value = azurerm_public_ip.control.ip_address
}

output "worker1_public_ip_address" {
  value = azurerm_public_ip.worker1.ip_address
}

output "worker2_public_ip_address" {
  value = azurerm_public_ip.worker2.ip_address
}
