variable "project_name" {
  type = string
}

variable "env_name" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}


variable "admin_bucket_name" {
  type = string
}
