variable "project_name" { type = string }
variable "env_name" { type = string }
variable "tags" { type = map(string) }
variable "pipelines" { type = map(object({
  service_name = string
  port         = number
})) }