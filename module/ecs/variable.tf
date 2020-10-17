variable "account_id" {
  default = "0"
}

variable "ecs_name" {
  default = "temp"
}

variable "cpu" {
  default = "512"
}

variable "memory" {
  default = "1024"
}

variable "desired_count" {
  default = "1"
}

variable "load_balancer" {
}

variable "vpc_main" {
}

variable "vpc_private_main_subnet" {
}

variable "vpc_private_sub_subnet" {
}