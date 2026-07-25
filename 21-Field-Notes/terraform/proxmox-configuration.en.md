---
description: "Full Terraform configuration for end-to-end VM provisioning on Proxmox: telmate/proxmox provider, providers.tf, variables, and VM resource definitions."
tags:
  - Field Notes
  - Terraform
  - IaC
  - Kubernetes
  - Template
---
# Terraform — Proxmox Full Configuration

> 🗒️ **Field note** — raw command/config dump. Preserved as-is; adapt it to your own environment.

```hcl
# =====================================================
# COMPLETE TERRAFORM CONFIGURATION FOR PROXMOX
# =====================================================

# -----------------------------------------------------
# providers.tf
# -----------------------------------------------------
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
  pm_parallel     = 1
  pm_timeout      = 600
}

# -----------------------------------------------------
# variables.tf
# -----------------------------------------------------
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://your-proxmox-ip:8006/api2/json"
}

variable "proxmox_user" {
  description = "Proxmox user"
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "template_name" {
  description = "VM template name"
  type        = string
  default     = "ubuntu-22.04-template"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "storage_pool" {
  description = "Storage pool"
  type        = string
  default     = "local-lvm"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  default     = "ssh-rsa YOUR_SSH_PUBLIC_KEY_HERE"
}

variable "base_ip" {
  description = "Base IP address (192.168.1)"
  type        = string
  default     = "192.168.1"
}

variable "gateway" {
  description = "Gateway IP"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = string
  default     = "8.8.8.8,8.8.4.4"
}

# -----------------------------------------------------
# locals.tf
# -----------------------------------------------------
locals {
  # VM Configurations
  master_nodes = [
    {
      name   = "k8s-master-1"
      ip     = "${var.base_ip}.10"
      cpu    = 8
      memory = 16384
      disk   = "100G"
      vmid   = 100
    },
    {
      name   = "k8s-master-2"
      ip     = "${var.base_ip}.11"
      cpu    = 8
      memory = 16384
      disk   = "100G"
      vmid   = 101
    },
    {
      name   = "k8s-master-3"
      ip     = "${var.base_ip}.12"
      cpu    = 8
      memory = 16384
      disk   = "100G"
      vmid   = 102
    }
  ]

  worker_nodes = [
    {
      name   = "k8s-worker-1"
      ip     = "${var.base_ip}.20"
      cpu    = 16
      memory = 65536  # 64GB
      disk   = "500G"
      vmid   = 110
      role   = "applications"
    },
    {
      name   = "k8s-worker-2"
      ip     = "${var.base_ip}.21"
      cpu    = 16
      memory = 65536
      disk   = "500G"
      vmid   = 111
      role   = "applications"
    },
    {
      name   = "k8s-worker-3"
      ip     = "${var.base_ip}.22"
      cpu    = 16
      memory = 65536
      disk   = "500G"
      vmid   = 112
      role   = "applications"
    }
  ]

  infra_nodes = [
    {
      name   = "k8s-infra-1"
      ip     = "${var.base_ip}.25"
      cpu    = 12
      memory = 49152  # 48GB
      disk   = "300G"
      vmid   = 120
      role   = "elk"
    },
    {
      name   = "k8s-infra-2"
      ip     = "${var.base_ip}.26"
      cpu    = 12
      memory = 49152
      disk   = "300G"
      vmid   = 121
      role   = "monitoring"
    },
    {
      name   = "k8s-infra-3"
      ip     = "${var.base_ip}.27"
      cpu    = 12
      memory = 49152
      disk   = "300G"
      vmid   = 122
      role   = "cicd"
    },
    {
      name   = "k8s-infra-4"
      ip     = "${var.base_ip}.28"
      cpu    = 12
      memory = 49152
      disk   = "300G"
      vmid   = 123
      role   = "ingress"
    }
  ]

  load_balancer_nodes = [
    {
      name   = "k8s-lb-1"
      ip     = "${var.base_ip}.100"
      cpu    = 4
      memory = 8192
      disk   = "50G"
      vmid   = 130
    },
    {
      name   = "k8s-lb-2"
      ip     = "${var.base_ip}.101"
      cpu    = 4
      memory = 8192
      disk   = "50G"
      vmid   = 131
    }
  ]

  storage_nodes = [
    {
      name   = "k8s-storage"
      ip     = "${var.base_ip}.110"
      cpu    = 8
      memory = 32768  # 32GB
      disk   = "1000G"  # 1TB
      vmid   = 140
    }
  ]
}

# -----------------------------------------------------
# main.tf - Master Nodes
# -----------------------------------------------------
resource "proxmox_vm_qemu" "k8s_masters" {
  count = length(local.master_nodes)
  
  name        = local.master_nodes[count.index].name
  vmid        = local.master_nodes[count.index].vmid
  target_node = var.proxmox_node
  
  # VM Configuration
  cores    = local.master_nodes[count.index].cpu
  memory   = local.master_nodes[count.index].memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent    = 1
  
  # Disk Configuration
  disk {
    slot     = 0
    size     = local.master_nodes[count.index].disk
    type     = "scsi"
    storage  = var.storage_pool
    iothread = 1
    ssd      = 1
    format   = "raw"
  }
  
  # Network Configuration
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  # Cloud-init Configuration
  os_type      = "cloud-init"
  clone        = var.template_name
  full_clone   = true
  
  # IP Configuration
  ipconfig0 = "ip=${local.master_nodes[count.index].ip}/24,gw=${var.gateway}"
  nameserver = var.dns_servers
  
  # SSH Configuration
  sshkeys = var.ssh_public_key
  
  # Cloud-init settings
  ciuser  = "ubuntu"
  cipassword = "<CI_PASSWORD>"
  
  # Tags
  tags = "kubernetes,master,production"
  
  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
  
  # Wait for VM to be ready
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = local.master_nodes[count.index].ip
    timeout     = "2m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo hostnamectl set-hostname ${local.master_nodes[count.index].name}",
      "echo '${local.master_nodes[count.index].ip} ${local.master_nodes[count.index].name}' | sudo tee -a /etc/hosts"
    ]
  }
}

# -----------------------------------------------------
# Worker Nodes
# -----------------------------------------------------
resource "proxmox_vm_qemu" "k8s_workers" {
  count = length(local.worker_nodes)
  
  name        = local.worker_nodes[count.index].name
  vmid        = local.worker_nodes[count.index].vmid
  target_node = var.proxmox_node
  
  cores    = local.worker_nodes[count.index].cpu
  memory   = local.worker_nodes[count.index].memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent    = 1
  
  disk {
    slot     = 0
    size     = local.worker_nodes[count.index].disk
    type     = "scsi"
    storage  = var.storage_pool
    iothread = 1
    ssd      = 1
    format   = "raw"
  }
  
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  os_type      = "cloud-init"
  clone        = var.template_name
  full_clone   = true
  
  ipconfig0 = "ip=${local.worker_nodes[count.index].ip}/24,gw=${var.gateway}"
  nameserver = var.dns_servers
  
  sshkeys = var.ssh_public_key
  ciuser  = "ubuntu"
  cipassword = "<CI_PASSWORD>"
  
  tags = "kubernetes,worker,${local.worker_nodes[count.index].role}"
  
  lifecycle {
    ignore_changes = [network]
  }
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = local.worker_nodes[count.index].ip
    timeout     = "2m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo hostnamectl set-hostname ${local.worker_nodes[count.index].name}",
      "echo '${local.worker_nodes[count.index].ip} ${local.worker_nodes[count.index].name}' | sudo tee -a /etc/hosts"
    ]
  }
}

# -----------------------------------------------------
# Infrastructure Nodes
# -----------------------------------------------------
resource "proxmox_vm_qemu" "k8s_infra" {
  count = length(local.infra_nodes)
  
  name        = local.infra_nodes[count.index].name
  vmid        = local.infra_nodes[count.index].vmid
  target_node = var.proxmox_node
  
  cores    = local.infra_nodes[count.index].cpu
  memory   = local.infra_nodes[count.index].memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent    = 1
  
  disk {
    slot     = 0
    size     = local.infra_nodes[count.index].disk
    type     = "scsi"
    storage  = var.storage_pool
    iothread = 1
    ssd      = 1
    format   = "raw"
  }
  
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  os_type      = "cloud-init"
  clone        = var.template_name
  full_clone   = true
  
  ipconfig0 = "ip=${local.infra_nodes[count.index].ip}/24,gw=${var.gateway}"
  nameserver = var.dns_servers
  
  sshkeys = var.ssh_public_key
  ciuser  = "ubuntu"
  cipassword = "<CI_PASSWORD>"
  
  tags = "kubernetes,infrastructure,${local.infra_nodes[count.index].role}"
  
  lifecycle {
    ignore_changes = [network]
  }
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = local.infra_nodes[count.index].ip
    timeout     = "2m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo hostnamectl set-hostname ${local.infra_nodes[count.index].name}",
      "echo '${local.infra_nodes[count.index].ip} ${local.infra_nodes[count.index].name}' | sudo tee -a /etc/hosts"
    ]
  }
}

# -----------------------------------------------------
# Load Balancer Nodes
# -----------------------------------------------------
resource "proxmox_vm_qemu" "k8s_lb" {
  count = length(local.load_balancer_nodes)
  
  name        = local.load_balancer_nodes[count.index].name
  vmid        = local.load_balancer_nodes[count.index].vmid
  target_node = var.proxmox_node
  
  cores    = local.load_balancer_nodes[count.index].cpu
  memory   = local.load_balancer_nodes[count.index].memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent    = 1
  
  disk {
    slot     = 0
    size     = local.load_balancer_nodes[count.index].disk
    type     = "scsi"
    storage  = var.storage_pool
    iothread = 1
    ssd      = 1
    format   = "raw"
  }
  
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  os_type      = "cloud-init"
  clone        = var.template_name
  full_clone   = true
  
  ipconfig0 = "ip=${local.load_balancer_nodes[count.index].ip}/24,gw=${var.gateway}"
  nameserver = var.dns_servers
  
  sshkeys = var.ssh_public_key
  ciuser  = "ubuntu"
  cipassword = "<CI_PASSWORD>"
  
  tags = "loadbalancer,haproxy"
  
  lifecycle {
    ignore_changes = [network]
  }
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = local.load_balancer_nodes[count.index].ip
    timeout     = "2m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo hostnamectl set-hostname ${local.load_balancer_nodes[count.index].name}",
      "echo '${local.load_balancer_nodes[count.index].ip} ${local.load_balancer_nodes[count.index].name}' | sudo tee -a /etc/hosts"
    ]
  }
}

# -----------------------------------------------------
# Storage Node
# -----------------------------------------------------
resource "proxmox_vm_qemu" "k8s_storage" {
  count = length(local.storage_nodes)
  
  name        = local.storage_nodes[count.index].name
  vmid        = local.storage_nodes[count.index].vmid
  target_node = var.proxmox_node
  
  cores    = local.storage_nodes[count.index].cpu
  memory   = local.storage_nodes[count.index].memory
  scsihw   = "virtio-scsi-pci"
  bootdisk = "scsi0"
  agent    = 1
  
  disk {
    slot     = 0
    size     = local.storage_nodes[count.index].disk
    type     = "scsi"
    storage  = var.storage_pool
    iothread = 1
    ssd      = 1
    format   = "raw"
  }
  
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
  
  os_type      = "cloud-init"
  clone        = var.template_name
  full_clone   = true
  
  ipconfig0 = "ip=${local.storage_nodes[count.index].ip}/24,gw=${var.gateway}"
  nameserver = var.dns_servers
  
  sshkeys = var.ssh_public_key
  ciuser  = "ubuntu"
  cipassword = "<CI_PASSWORD>"
  
  tags = "storage,nfs"
  
  lifecycle {
    ignore_changes = [network]
  }
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = local.storage_nodes[count.index].ip
    timeout     = "2m"
  }
  
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo hostnamectl set-hostname ${local.storage_nodes[count.index].name}",
      "echo '${local.storage_nodes[count.index].ip} ${local.storage_nodes[count.index].name}' | sudo tee -a /etc/hosts"
    ]
  }
}

# -----------------------------------------------------
# outputs.tf
# -----------------------------------------------------
output "master_nodes" {
  description = "Master node information"
  value = [
    for i, vm in proxmox_vm_qemu.k8s_masters : {
      name = vm.name
      ip   = local.master_nodes[i].ip
      vmid = vm.vmid
    }
  ]
}

output "worker_nodes" {
  description = "Worker node information"
  value = [
    for i, vm in proxmox_vm_qemu.k8s_workers : {
      name = vm.name
      ip   = local.worker_nodes[i].ip
      vmid = vm.vmid
      role = local.worker_nodes[i].role
    }
  ]
}

output "infrastructure_nodes" {
  description = "Infrastructure node information"
  value = [
    for i, vm in proxmox_vm_qemu.k8s_infra : {
      name = vm.name
      ip   = local.infra_nodes[i].ip
      vmid = vm.vmid
      role = local.infra_nodes[i].role
    }
  ]
}

output "load_balancer_nodes" {
  description = "Load balancer node information"
  value = [
    for i, vm in proxmox_vm_qemu.k8s_lb : {
      name = vm.name
      ip   = local.load_balancer_nodes[i].ip
      vmid = vm.vmid
    }
  ]
}

output "storage_nodes" {
  description = "Storage node information"
  value = [
    for i, vm in proxmox_vm_qemu.k8s_storage : {
      name = vm.name
      ip   = local.storage_nodes[i].ip
      vmid = vm.vmid
    }
  ]
}

output "cluster_summary" {
  description = "Complete cluster summary"
  value = {
    total_vms = length(local.master_nodes) + length(local.worker_nodes) + length(local.infra_nodes) + length(local.load_balancer_nodes) + length(local.storage_nodes)
    masters   = length(local.master_nodes)
    workers   = length(local.worker_nodes)
    infra     = length(local.infra_nodes)
    lb        = length(local.load_balancer_nodes)
    storage   = length(local.storage_nodes)
    
    total_cpu = (
      sum([for node in local.master_nodes : node.cpu]) +
      sum([for node in local.worker_nodes : node.cpu]) +
      sum([for node in local.infra_nodes : node.cpu]) +
      sum([for node in local.load_balancer_nodes : node.cpu]) +
      sum([for node in local.storage_nodes : node.cpu])
    )
    
    total_memory_gb = (
      sum([for node in local.master_nodes : node.memory]) +
      sum([for node in local.worker_nodes : node.memory]) +
      sum([for node in local.infra_nodes : node.memory]) +
      sum([for node in local.load_balancer_nodes : node.memory]) +
      sum([for node in local.storage_nodes : node.memory])
    ) / 1024
  }
}

# -----------------------------------------------------
# terraform.tfvars.example
# -----------------------------------------------------
# proxmox_api_url = "https://192.168.1.100:8006/api2/json"
# proxmox_user = "terraform@pve"
# proxmox_password = "<PROXMOX_PASSWORD>"
# proxmox_node = "pve"
# template_name = "ubuntu-22.04-template"
# network_bridge = "vmbr0"
# storage_pool = "local-lvm"
# ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
# base_ip = "192.168.1"
# gateway = "192.168.1.1"
# dns_servers = "8.8.8.8,8.8.4.4"
```
