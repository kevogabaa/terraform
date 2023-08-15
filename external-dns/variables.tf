variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
}

variable "resource_group_location" {
  description = "Azure Region"
  default     = "South Africa North"
}

variable "cluster_name" {
  description = "Name of the AKS Cluster"
}

variable "node_count" {
  description = "Initial number of nodes in the default node pool"
  default     = 3
}

variable "min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  default     = 5
}

# variable "log_analytics_workspace_id" {
#   description = "ID of the Log Analytics Workspace for AKS logging"
# }

variable "azure_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "azure_subscription_tenant_id" {
  description = "Azure subscription tenant ID."
  type        = string
}

variable "service_principal_appid" {
  description = "Service principal application ID."
  type        = string
}

variable "service_principal_password" {
  description = "Service principal password."
  type        = string
}

variable "static_ip_name" {
  description = "Name of the static public IP"
  default     = "myakspublicip"
}

variable "load_balancer_name" {
  description = "Name of the Azure Load Balancer"
  default     = "myaksloadbalancer"
}

variable "dns_zone_name" {
  description = "Name of the DNS zone"
}

variable "subdomain_name" {
  description = "Name of the subdomain"
}
