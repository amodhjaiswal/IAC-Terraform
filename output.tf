output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "rds_cluster_id" {
  value = module.rds.rds_cluster_id
}
