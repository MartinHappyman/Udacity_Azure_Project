variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "udacity_project_test"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "Switzerland North"
}

variable "Project" {
  description = "Tag indicating which project the resource belongs to"
  default = "udacity"
}

variable "packer_resource_group_name" {
   description = "Name of the resource group in which the Packer image will be created"
   default     = "Udacity-demo-rg"
}

variable "packer_image_name" {
   description = "Name of the Packer image"
   default     = "Ubuntu4_Image"
}

# variable "vm_count" {
  # description = "Number of Virtual Machines"
#}
