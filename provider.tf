provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "this" {
  count      = var.create_manifests ? 1 : 0
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  count      = var.create_manifests ? 1 : 0
  name       = module.eks.cluster_name
  depends_on = [module.eks, data.aws_eks_cluster.this]
}

provider "kubernetes" {
  host                   = var.create_manifests ? data.aws_eks_cluster.this[0].endpoint : null
  cluster_ca_certificate = var.create_manifests ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : null
  token                  = var.create_manifests ? data.aws_eks_cluster_auth.this[0].token : null
}

provider "helm" {
  kubernetes = {
    host                   = var.create_manifests ? data.aws_eks_cluster.this[0].endpoint : ""
    cluster_ca_certificate = var.create_manifests ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : ""
    token                  = var.create_manifests ? data.aws_eks_cluster_auth.this[0].token : ""
  }
}
