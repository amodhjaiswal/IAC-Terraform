locals {
  pipelines = {
    app1 = {
      service_name = var.eks_service_name_1
      port         = var.eks_service_port_1
    }
    app2 = {
      service_name = var.eks_service_name_2
      port         = var.eks_service_port_2
    }
    app3 = {
      service_name = var.eks_service_name_3
      port         = var.eks_service_port_3
    }
    app4 = {
      service_name = var.eks_service_name_4
      port         = var.eks_service_port_4
    }
    app5 = {
      service_name = var.eks_service_name_5
      port         = var.eks_service_port_5
    }
    app6 = {
      service_name = var.eks_service_name_6
      port         = var.eks_service_port_6
    }
    app7 = {
      service_name = var.eks_service_name_7
      port         = var.eks_service_port_7
    }
    app8 = {
      service_name = var.eks_service_name_8
      port         = var.eks_service_port_8
    }
    app9 = {
      service_name = var.eks_service_name_9
      port         = var.eks_service_port_9
    }
  }
}

variable "eks_service_name_1" {
  type = string
}

variable "eks_service_port_1" {
  type = number
}

variable "eks_service_name_2" {
  type = string
}
variable "eks_service_port_2" {
  type = number
}

variable "eks_service_name_3" {
  type = string
}
variable "eks_service_port_3" {
  type = number
}

variable "eks_service_name_4" {
  type = string
}
variable "eks_service_port_4" {
  type = number
}
variable "eks_service_name_5" {
  type = string
}
variable "eks_service_port_5" {
  type = number
}
variable "eks_service_name_6" {
  type = string
}
variable "eks_service_port_6" {
  type = number
}
variable "eks_service_name_7" {
  type = string
}
variable "eks_service_port_7" {
  type = number
}

variable "eks_service_name_8" {
  type = string
}
variable "eks_service_port_8" {
  type = number
}

variable "eks_service_name_9" {
  type = string
}
variable "eks_service_port_9" {
  type = number
}





