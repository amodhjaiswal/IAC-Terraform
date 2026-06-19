###########----------GLOBAL VARIABLE---------#############
env_name      = "production"
project_name  =  "test"
region        = "ap-south-1"
pipeline_region = "us-east-1"
aws_account_id = "652821469277"
create_manifests = true
domain = "test.app"
certificate_arn = "arn:aws:acm:ap-south-1:652821469277:certificate/7205200f-9877-4d29-9b4e-c6a4e8ce0640"
front_end_certificate_arn = "arn:aws:acm:us-east-1:652821469277:certificate/7cfe503b-1287-42bc-8437-21ab4da2b97b"
waf_logs_retention = 365

###########----------VPC---------###########

cidr_block = "10.1.0.0/16"
public_subnet_cidrs = ["10.1.0.0/20", "10.1.16.0/20", "10.1.32.0/20"]
private_subnet_cidrs = ["10.1.64.0/20", "10.1.80.0/20", "10.1.96.0/20"]
availability_zones = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

###########----------Bastion-ec2---------###########
ami_id   = "ami-0a14f53a6fe4dfcd1"  #ubuntu ami 
instance_type = "t3.small"
instance_name = "bastion"
bastion_ebs_size = 40

###########----------ELASTIC-CACHE-REDIS---------###########

node_type = "cache.t3.medium"
engine_version = 7.1
engine_version_major = 7
enable_cluster_mode = false
redis__logs_retention = 365  #1years

###########----------frontend-s3-cf---------###########
frontend_bucket_name= "admin"

###########----------media-s3-cf---------###########
media_bucket_name = "media"

###########----------eks---------###########
cluster_version = 1.34
node_instance_type = "c5.xlarge"
node_min_size = 0
node_desired_size = 0
node_max_size = 1
eks_logs_retention = 365
eks_access_arns = [
  "arn:aws:iam::652821469277:role/service-role/codepiplile-role",
  "arn:aws:iam::652821469277:role/kulud-ssm-instance-profile"
]

###########----------codepipeline-backend-eks---------###########
codebuild_logs_retention = 365
gitlab_repo_url          = "gitlab.appinvent.in/kulud/devops/k8s-argocd-mainfest.git"
gitlab_user_email        = "XXXXXXXXXXXXXXXXX"
gitlab_user              = "XXXXXXXXXXXXXXXXXXX"
gitlab_pat               = "XXXXXXXXXXXXXXXXXXXXXXXXXX"
new_relic_license_key    = "XXXXXXXXXXXXXXXXXx"

eks_service_name_1 = "auth"
eks_service_port_1 = 3004
eks_service_name_2 = "admin"
eks_service_port_2 = 3005
eks_service_name_3 = "user"
eks_service_port_3 = 3006
eks_service_name_4 = "notif"
eks_service_port_4 = 3007
eks_service_name_5 = "cms"
eks_service_port_5 = 3008
eks_service_name_6 = "product"
eks_service_port_6 = 3009
eks_service_name_7 = "order"
eks_service_port_7 = 3010
eks_service_name_8 = "scheduler"
eks_service_port_8 = 3011
eks_service_name_9 = "productcore"
eks_service_port_9 = 3012

###########----------MONITORING---------############
create_monitoring = true
grafana_admin_password = "DRzpuM1Xa4wx12"
loki_storage_size = "20Gi"
prometheus_storage_size = "20Gi"
grafana_storage_size = "20Gi"
promtail_storage_size = "20Gi"
loki_retention_period = "8760h"

# SNS Configuration
sns_backend_name = "backend"
sns_backend_emails = []

sns_frontend_name = "frontend"
sns_frontend_emails = []

###########----------RDS---------############
# Aurora PostgreSQL Configuration
rds_engine = "aurora-postgresql"
rds_engine_version = "17.4"
rds_engine_version_major = "17"
rds_instance_class = "db.r6g.xlarge"
rds_instance_count = 1 #primary for write 
rds_db_name = "proddb"
rds_master_username = "rds_master"
rds_master_password = "XXXXXXXXXXXXXXX"
rds_replica_count = 2  #seconday for read
rds_replica_instance_class = "db.r6g.xlarge"
rds_logs_retention = 365
rds_allocated_storage = 50
rds_max_allocated_storage = 100
rds_multi_az = true
rds_db_parameters = []

# Alternative MySQL Configuration (comment above and uncomment below)
# rds_engine = "mysql"
# rds_engine_version = "8.0.39"
# rds_engine_version_major = "8.0"
# rds_instance_class = "db.t3.micro"
# rds_instance_count = 1
# rds_db_name = "kuluddb"
# rds_master_username = "admin"
# rds_master_password = "SecurePassword123!"
# rds_replica_count = 1
# rds_replica_instance_class = "db.t3.micro"
# rds_logs_retention = 365
# rds_allocated_storage = 20
# rds_max_allocated_storage = 100
# rds_multi_az = true
# rds_db_parameters = [
#   {
#     name  = "innodb_buffer_pool_size"
#     value = "{DBInstanceClassMemory*3/4}"
#   }
# ]

# Alternative Aurora MySQL Configuration
# rds_engine = "aurora-mysql"
# rds_engine_version = "8.0.mysql_aurora.3.07.1"
# rds_engine_version_major = "8.0"
# rds_instance_class = "db.r6g.large"
# rds_instance_count = 1
# rds_db_name = "kuluddb"
# rds_master_username = "admin"
# rds_master_password = "SecurePassword123!"
# rds_replica_count = 1
# rds_replica_instance_class = "db.r6g.large"
# rds_logs_retention = 365
# rds_allocated_storage = 20
# rds_max_allocated_storage = 100
# rds_multi_az = false
# rds_db_parameters = []


###########----------codepipeline-backend-ecs---------###########
ecs_service_name_1 = "admin"
ecs_service_port_1 = 3000
ecs_service_name_2 = "auth"
ecs_service_port_2 = 3000
ecs_cpu = "512"
ecs_memory = "1024"
ecs_task_count = 2



