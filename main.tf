###########----------VPC---------###########
module "vpc" {
  source                = "./modules/vpc"
  env_name              = terraform.workspace
  project_name          = var.project_name
  tags                  = var.tags
  vpc_name              = var.vpc_name
  cidr_block            = var.cidr_block
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  availability_zones    = var.availability_zones
  region                = var.region
}

###########----------VPC-CLEANUP---------###########
module "vpc_cleanup" {
  source   = "./modules/vpc-cleanup"
  region   = var.region
  vpc_cidr = var.cidr_block
  
  depends_on = [module.vpc]
}

###########----------EC2-BASTION---------###########
module "ec2-bastion" {
  source              = "./modules/ec2-bastion"
  env_name            = terraform.workspace
  project_name        = var.project_name
  region              = var.region
  tags                = var.tags
  vpc_id              = module.vpc.vpc_id
  private_subnet      = module.vpc.private_subnet_ids[0]
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  instance_name       = var.instance_name
  bastion_ebs_size    = var.bastion_ebs_size
}

###########----------KMS FOR CLOUDWATCH LOGS---------###########
module "kms-cloudwatch-logs" {
  source       = "./modules/kms/cloudwatch_logs"
  env_name     = terraform.workspace
  project_name = var.project_name
  region       = var.region
  tags         = var.tags
}

###########----------REDIS---------###########
module "elastic-cache-redis" {
  source                = "./modules/elastic_cache"
  env_name              = terraform.workspace
  project_name          = var.project_name
  tags                  = var.tags
  vpc_id                = module.vpc.vpc_id
  vpc_cidr              = var.cidr_block
  private_subnet_ids    = module.vpc.private_subnet_ids
  node_type             = var.node_type
  engine_version        = var.engine_version
  engine_version_major  = var.engine_version_major
  redis__logs_retention = var.redis__logs_retention
  kms_key_id            = module.kms-cloudwatch-logs.kms_key_arn
  enable_cluster_mode   = var.enable_cluster_mode
  sns_topic_arn         = module.sns-backend.topic_arn

  depends_on = [
    module.kms-cloudwatch-logs
    ]
}

###########----------RDS---------###########
module "rds" {
  source                    = "./modules/rds"
  env_name                  = terraform.workspace
  project_name              = var.project_name
  tags                      = var.tags
  vpc_id                    = module.vpc.vpc_id
  vpc_cidr                  = var.cidr_block
  private_subnet_ids        = module.vpc.private_subnet_ids
  kms_key_id                = module.kms-cloudwatch-logs.kms_key_arn
  engine                    = var.rds_engine
  engine_version            = var.rds_engine_version
  engine_version_major      = var.rds_engine_version_major
  instance_class            = var.rds_instance_class
  instance_count            = var.rds_instance_count
  allocated_storage         = var.rds_allocated_storage
  max_allocated_storage     = var.rds_max_allocated_storage
  db_name                   = var.rds_db_name
  master_username           = var.rds_master_username
  master_password           = var.rds_master_password
  multi_az                  = var.rds_multi_az
  replica_count             = var.rds_replica_count
  replica_instance_class    = var.rds_replica_instance_class
  rds_logs_retention        = var.rds_logs_retention
  db_parameters             = var.rds_db_parameters
  sns_topic_arn             = module.sns-backend.topic_arn

  depends_on = [
    module.kms-cloudwatch-logs
  ]
}

# ###########----------RDS---------###########
# module "aurora-rds" {
#   source                    = "./modules/rds"
#   env_name                  = terraform.workspace
#   project_name              = "kulud-db"
#   tags                      = var.tags
#   vpc_id                    = module.vpc.vpc_id
#   vpc_cidr                  = var.cidr_block
#   private_subnet_ids        = module.vpc.private_subnet_ids
#   kms_key_id                = module.kms-cloudwatch-logs.kms_key_arn
#   engine                    = var.rds_engine
#   engine_version            = var.rds_engine_version
#   engine_version_major      = var.rds_engine_version_major
#   instance_class            = var.rds_instance_class
#   instance_count            = var.rds_instance_count
#   allocated_storage         = var.rds_allocated_storage
#   max_allocated_storage     = var.rds_max_allocated_storage
#   db_name                   = var.rds_db_name
#   master_username           = var.rds_master_username
#   master_password           = var.rds_master_password
#   multi_az                  = var.rds_multi_az
#   replica_count             = var.rds_replica_count
#   replica_instance_class    = var.rds_replica_instance_class
#   rds_logs_retention        = var.rds_logs_retention
#   db_parameters             = var.rds_db_parameters
#   sns_topic_arn             = module.sns-backend.topic_arn

#   depends_on = [
#     module.kms-cloudwatch-logs
#   ]
# }

###########----------Frontend-S3-WITH-CF---------###########
module "frontend-s3-cf" {
  source                   = "./modules/frontend_s3_cf"
  env_name                 = terraform.workspace
  project_name             = var.project_name
  tags                     = var.tags
  frontend_bucket_name     = var.frontend_bucket_name
  domain                   = var.domain
  certificate_arn          = var.front_end_certificate_arn
  web_acl_arn              = module.frontend-waf.web_acl_arn

  depends_on = [module.frontend-waf]
}

###########----------Media-S3-WITH-CF---------###########
module "media-s3-cf" {
  source               = "./modules/media_s3_cf"
  env_name             = terraform.workspace
  project_name         = var.project_name
  tags                 = var.tags
  media_bucket_name    = var.media_bucket_name
  domain               = var.domain
  certificate_arn      = var.front_end_certificate_arn
  web_acl_arn          = module.frontend-waf.web_acl_arn

  depends_on = [module.frontend-waf]
}

###########----------SECRET-MANAGER---------###########

module "secret-manager" {
  source        = "./modules/secret_manager"
  env_name      = terraform.workspace
  project_name  = var.project_name
  tags          = var.tags

}


###########----------ECR---------###########

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  env_name     = var.env_name
  tags         = var.tags
  pipelines    = local.pipelines
}



###########----------EKS---------###########

module "eks" {
  source                  = "./modules/eks/eks_cluster"
  env_name                = terraform.workspace
  project_name            = var.project_name
  tags                    = var.tags
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  cluster_version         = var.cluster_version
  node_instance_type      = var.node_instance_type
  node_min_size           = var.node_min_size
  node_desired_size       = var.node_desired_size
  node_max_size           = var.node_max_size
  codebuild_role_arn      = module.codepipeline-global.codebuild_role_arn
  bastion_ssm_role_arn    = module.ec2-bastion.bastion_ssm_role_arn
  bastion_sg_id           = module.ec2-bastion.bastion_sg_id
  region                  = var.region
  secret_arn              = module.secret-manager.secret_arn
  bucket_name             = module.media-s3-cf.bucket_name
  eks_logs_retention      = var.eks_logs_retention
  kms_key_id              = module.kms-cloudwatch-logs.kms_key_arn
  eks_access_arns         = var.eks_access_arns


  depends_on = [
    module.kms-cloudwatch-logs,
    module.secret-manager,
    module.media-s3-cf

  ]
  

}

###########----------EKS-SERVICEACCOUNT---------###########

module "eks_serviceaccount" {
  source = "./modules/eks/eks_serviceaccount"
  count  = var.create_manifests ? 1 : 0
  cluster_name         = module.eks.cluster_name
  region              = var.region
  namespace           = terraform.workspace
  service_account_name = "${var.project_name}-${terraform.workspace}-service-account"
  role_arn            = module.eks.pod_identity_role_arn
  project_name        = var.project_name
  environment         = terraform.workspace

  providers = {
    kubernetes = kubernetes
    aws        = aws
  }

  depends_on = [module.eks]
}

###########----------EKS-AWS-INGRESS-CONTROLLER---------###########

module "eks_aws_lb_controller" {
  source = "./modules/eks/eks_aws_lb_controller"
  create_manifests  = var.create_manifests
  project_name      = var.project_name
  env_name          = terraform.workspace
  cluster_name      = module.eks.cluster_name
  vpc_id            = module.vpc.vpc_id
  region            = var.region
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_url          = module.eks.oidc_url
  tags              = var.tags
  depends_on = [
    module.eks
  ]
}

###########----------EKS-ARGOCD---------###########

module "eks_argocd" {
  source = "./modules/eks/eks_argocd"
  create_manifests = var.create_manifests
  eks_cluster_name = module.eks.cluster_name
  providers = {
    helm = helm
    kubernetes = kubernetes
  }
  depends_on = [
    module.eks,
    module.eks_aws_lb_controller
  ]
}

###########----------EKS-ALB-MONITORING---------###########

module "eks_alb_monitoring" {
  source       = "./modules/eks/eks_alb_monitoring"
  env_name     = terraform.workspace
  project_name = var.project_name
  tags         = var.tags
}

###########----------KUBERNETES-MANIFESTS---------###########

module "eks_manifest" {
  source = "./modules/eks/eks_manifest"

  eks_cluster_name    = module.eks.cluster_name
  public_subnet_ids   = module.vpc.public_subnet_ids
  aws_lb_controller   = module.eks_aws_lb_controller
  argocd_deployment   = module.eks_argocd
  vpc_id              = module.vpc.vpc_id
  region              = var.region
  create_manifests    = var.create_manifests
  project_name        = var.project_name
  env_name            = var.env_name
  domain              = var.domain
  certificate_arn     = var.certificate_arn
  alb_logs_bucket_name = module.eks_alb_monitoring.alb_logs_bucket_name
  web_acl_arn         = module.waf.web_acl_arn

  providers = {
    kubernetes = kubernetes
  }

  depends_on = [
    module.eks,
    module.eks_aws_lb_controller,
    module.eks_argocd,
    module.eks_alb_monitoring,
    module.waf
    
  ]
}

###########----------MONITORING-GRAFANA---------###########

module "eks_grafana" {
  source = "./modules/eks/eks_grafana"

  create_monitoring        = var.create_monitoring
  project_name            = var.project_name
  env_name                = terraform.workspace
  cluster_name            = module.eks.cluster_name
  region                  = var.region
  account_id              = var.aws_account_id
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_provider_url       = module.eks.oidc_url
  grafana_admin_password  = var.grafana_admin_password
  loki_retention_period   = var.loki_retention_period
  loki_storage_size       = var.loki_storage_size
  prometheus_storage_size = var.prometheus_storage_size
  grafana_storage_size    = var.grafana_storage_size
  promtail_storage_size   = var.promtail_storage_size
  enable_metrics_server   = var.enable_metrics_server
  metrics_server_chart_version = var.metrics_server_chart_version
  eks_cluster_endpoint    = module.eks.cluster_endpoint

  providers = {
    aws        = aws
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [
    module.eks,
    module.eks_aws_lb_controller
  ]
}
###########----------SNS---------###########
module "sns-backend" {
  source        = "./modules/sns"
  project_name  = var.project_name
  env_name      = terraform.workspace
  resource_name = var.sns_backend_name
  emails        = var.sns_backend_emails
}

###########----------SNS---------###########
module "sns-frontend" {
  source        = "./modules/sns"
  project_name  = var.project_name
  env_name      = terraform.workspace
  resource_name = var.sns_frontend_name
  emails        = var.sns_frontend_emails
}

###########----------SNS---------###########
module "sns-backend-codepipeline" {
  source        = "./modules/sns"
    providers = {
    aws = aws.pipeline
  }
  project_name  = var.project_name
  env_name      = terraform.workspace
  resource_name = var.sns_backend_name
  emails        = var.sns_backend_emails
}

###########----------SNS---------###########
module "sns-frontend-codepipeline" {
  source        = "./modules/sns"
    providers = {
    aws = aws.pipeline
  }
  project_name  = var.project_name
  env_name      = terraform.workspace
  resource_name = var.sns_frontend_name
  emails        = var.sns_frontend_emails
}

###########----------KMS FOR CLOUDWATCH LOGS---------###########
module "kms-cloudwatch-logs-codepipeline" {
  source       = "./modules/kms/cloudwatch_logs"
  providers = {
    aws = aws.pipeline
  }
  env_name     = terraform.workspace
  project_name = var.project_name
  region       = var.pipeline_region
  tags         = var.tags
}

###########----------CODEPIPELINE-GLOBAL---------###########

module "codepipeline-global" {
  source            = "./modules/codepipeline_global"
  providers = {
    aws = aws.pipeline
  }
  env_name          = terraform.workspace
  project_name      = var.project_name
  region            = var.pipeline_region
  tags              = var.tags
  admin_bucket_name = module.frontend-s3-cf.bucket_name

  depends_on = [
    module.frontend-s3-cf
  ]
}

###########----------CODEPIPELINE-BACKEND-EKS---------###########

module "codepipeline-backend-eks" {
  source                   = "./modules/eks/eks_codepipeline"
  providers = {
    aws = aws.pipeline
  }
  env_name                 = terraform.workspace
  project_name             = var.project_name
  region                   = var.pipeline_region
  codebuild_region         = var.region
  tags                     = var.tags
  eks_cluster_name         = module.eks.cluster_name
  aws_account_id           = var.aws_account_id
  for_each                 = local.pipelines
  service_name             = each.value.service_name
  artifact_bucket_name     = module.codepipeline-global.artifact_bucket_name
  codepipeline_role_arn    = module.codepipeline-global.codepipeline_role_arn
  codebuild_role_arn       = module.codepipeline-global.codebuild_role_arn
  kms_key_id               = module.kms-cloudwatch-logs-codepipeline.kms_key_arn
  codebuild_logs_retention = var.codebuild_logs_retention
  ecr_repository_url       = module.ecr.ecr_repository_url
  ecr_repository_name      = module.ecr.ecr_repository_name
  gitlab_repo_url          = var.gitlab_repo_url
  gitlab_user_email        = var.gitlab_user_email
  gitlab_user              = var.gitlab_user
  gitlab_pat               = var.gitlab_pat
  sns_topic_arn            = module.sns-backend-codepipeline.topic_arn
  secret_name              = module.secret-manager.secret_name
  new_relic_license_key    = var.new_relic_license_key

  depends_on = [
    module.kms-cloudwatch-logs-codepipeline,
    module.ecr,
    module.codepipeline-global,
    module.secret-manager
    ]
}

module "codepipeline-frontend" {
  source                   = "./modules/frontend_codepipeline"
  providers = {
    aws = aws.pipeline
  }
  env_name                 = terraform.workspace
  project_name             = var.project_name
  region                   = var.pipeline_region
  tags                     = var.tags
  artifact_bucket_name     = module.codepipeline-global.artifact_bucket_name
  codepipeline_role_arn    = module.codepipeline-global.codepipeline_role_arn
  codebuild_role_arn       = module.codepipeline-global.codebuild_role_arn
  kms_key_id               = module.kms-cloudwatch-logs-codepipeline.kms_key_arn
  codebuild_logs_retention = var.codebuild_logs_retention
  bucket_name              = module.frontend-s3-cf.bucket_name
  cloudfront_distribution_id = module.frontend-s3-cf.cloudfront_distribution_id
  frontend_bucket_name     = var.frontend_bucket_name
  sns_topic_arn            = module.sns-frontend-codepipeline.topic_arn

  depends_on = [
    module.kms-cloudwatch-logs-codepipeline,
    module.codepipeline-global,
    module.frontend-s3-cf
    ]
}

###########----------WAF---------###########

module "waf" {
  source       = "./modules/waf/backend_waf"
  env_name     = terraform.workspace
  project_name = var.project_name
  region       = var.region
  tags         = var.tags
  kms_key_id   = module.kms-cloudwatch-logs.kms_key_arn
  waf_logs_retention = var.waf_logs_retention
  scope        = "REGIONAL"
  rate_limit   = 10000
  blocked_countries = ["CN", "RU", "KP", "IR"]
   whitelist_ips = [
  "34.18.84.75/32",
    "34.18.109.30/32",
    "34.18.99.174/32",
    "34.18.93.74/32",
    "130.110.116.205/32",
    "172.64.0.0/13",
    "188.114.96.0/20",
    "104.16.0.0/13",
    "141.101.64.0/18",
    "103.21.244.0/22",
    "198.41.128.0/17",
    "108.162.192.0/18",
    "197.234.240.0/22",
    "103.31.4.0/22",
    "131.0.72.0/22",
    "190.93.240.0/20",
    "103.22.200.0/22",
    "104.24.0.0/14",
    "20.173.74.0/32",
    "162.158.0.0/15",
    "173.245.48.0/20"
  ]
  blacklist_ips = []

  depends_on = [module.kms-cloudwatch-logs]
}

###########----------FRONTEND-WAF---------###########

module "frontend-waf" {
  source       = "./modules/waf/frontend_waf"
  providers = {
    aws = aws.pipeline
  }
  env_name     = terraform.workspace
  project_name = var.project_name
  region       = var.pipeline_region
  tags         = var.tags
  kms_key_id   = module.kms-cloudwatch-logs-codepipeline.kms_key_arn
  waf_logs_retention = var.waf_logs_retention
  rate_limit   = 10000
  blocked_countries = ["CN", "RU", "KP", "IR"]
  allowlist_ips = []
  blocklist_ips = []

  depends_on = [module.kms-cloudwatch-logs-codepipeline]
}

###########----------ECS-CLUSTER---------###########

# module "ecs" {
#   source        = "./modules/ecs/ecs_cluster"
#   env_name      = terraform.workspace
#   project_name  = var.project_name
#   tags          = var.tags
# }

# ################-----ECS-Load-Balancer-----################

# module "ecs-loadbalancer" {
# source         = "./modules/ecs/ecs_loadbalancer"
# project_name   = var.project_name
# env_name       = var.env_name
# tags           = var.tags
# vpc_id         = module.vpc.vpc_id
# public_subnets = module.vpc.public_subnet_ids
# for_each       = local.ecs_pipelines
# port           = each.value.port
# service_name   = each.value.service_name
# }


# ################----ECS-Task-Service--------################

# module "ecs_task_service" {
# source             = "./modules/ecs/ecs_task"
# project_name       = var.project_name
# env_name           = var.env_name
# region             = var.region
# tags               = var.tags
# ecs_cluster_id     = module.ecs.ecs_cluster_id
# execution_role_arn = module.ecs.ecs_task_execution_role_arn
# task_role_arn      = module.ecs.ecs_task_role_arn
# vpc_id             = module.vpc.vpc_id
# alb_sg_id          = module.ecs-loadbalancer[each.key].alb_sg_id
# private_subnets    = module.vpc.private_subnet_ids
# ecr_repository_url = module.ecr.ecr_repository_url
# target_group_arn   = module.ecs-loadbalancer[each.key].target_group_arn
# for_each           = local.ecs_pipelines
# port               = each.value.port
# service_name       = each.value.service_name
# ecs_cpu            = var.ecs_cpu
# ecs_memory         = var.ecs_memory
# ecs_task_count     = var.ecs_task_count

# }

# ################---------ECS-CODEPIPELINE------################

# module "codepipeline-ecs" {
#   source = "./modules/ecs/ecs_codepipeline"
#   env_name              = terraform.workspace
#   project_name          = var.project_name
#   region                = var.region
#   tags                  = var.tags
#   aws_account_id        = var.aws_account_id
#   for_each              = local.ecs_pipelines
#   service_name          = each.value.service_name
#   port                  = each.value.port
#   artifact_bucket_name  = module.codepipeline-global.artifact_bucket_name
#   codepipeline_role_arn = module.codepipeline-global.codepipeline_role_arn
#   codebuild_role_arn    = module.codepipeline-global.codebuild_role_arn
#   ecr_repository_url    = module.ecr.ecr_repository_url
# }
