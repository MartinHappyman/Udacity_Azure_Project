variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default     = "East US"
}

variable "username" {
  description = "Username od admin"
}

variable "password" {
  description = "Password of admin"
}