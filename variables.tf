variable "container_name" {
  description = "Value of the name for the Docker container"
  type        = string
  default     = "kerginx"
}

variable "platform_image" {
  type = string
}

variable "platform_container_name" {
  type    = string
  default = "platform-training-app"
}

variable "platform_container_port" {
  type    = number
  default = 80
}
