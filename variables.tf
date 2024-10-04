variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}


variable "resource_group_name" {

  description = "ressource group"
  default     = "TestProxy"

}

variable "location" {
  description = "location"
  default     = "northeurope"
}


variable "packer_image_debian" {
  description = "image packer debian"
  default     = "Debian-client"
}

variable "packer_image_nginx" {
  description = "image packer nginx"
  default     = "Nginx"
}



