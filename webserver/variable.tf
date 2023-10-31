variable "instance_type" {
  default = {
    "prod" = "t2.micro"
    "test" = "t2.micro"
    "dev"  = "t2.micro"
  }
  description = "Type of instance"
  type        = map(string)
}

variable "default_tags" {
  default = {
    Owner = "sanah",
    App   = "Web"
  }
  type        = map(any)
  description = "Default tags for all AWS resources"
}

variable "prefix" {
  default     = "sanah"
  type        = string
  description = "Name prefix"
}

variable "env" {
  default     = "dev"
  type        = string
  description = "Deployment Environment"
}