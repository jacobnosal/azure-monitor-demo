output "windows_vm_admin_password" {
  sensitive   = true
  description = "Randomly generated password for use with the Windows VM admin user."
  value       = random_password.windows_vm_admin_password.result
}