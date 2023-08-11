variable "resource_group_location" {
  type        = string
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  description = "The Test Resource Group."
}

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

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}
variable "system_node_count" {
  type        = number
  description = "Number of AKS worker nodes"
}
variable "acr_name" {
  type        = string
  description = "ACR name"
}

variable "cluster_name" {
  type        = string
  description = "AKS cluster name"
}


# export ARM_SUBSCRIPTION_ID="82702432-2525-4259-bd45-ea9bda10908a"
# export ARM_TENANT_ID="5d5285d8-d9dc-4837-971e-ef69a2036432"
# export ARM_CLIENT_ID="0abbf17c-7485-42c4-b779-345f2ad9f9cf"
# export ARM_CLIENT_SECRET="7LB8Q~HZxRze~osXi8GLub8vO9dGc1jmmb-ozb_U"

# 5d5285d8-d9dc-4837-971e-ef69a2036432  
# 0abbf17c-7485-42c4-b779-345f2ad9f9cf
# 