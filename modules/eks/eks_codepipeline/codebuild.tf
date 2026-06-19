#######################################
# AWS CodeBuild Project
#######################################

resource "aws_codebuild_project" "this" {
  name         = "${local.name_prefix}-${var.service_name}-codebuild"
  description  = "CodeBuild project for ${var.service_name}"
  service_role = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
    name = "build_output"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_LARGE" # 8 vCPUs, 16 GiB
    image           = "aws/codebuild/standard:6.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_ACCN_ID"
      value = var.aws_account_id
    }
    environment_variable {
      name  = "ECR_REGION"
      value = var.codebuild_region
    }
    environment_variable {
      name  = "ECR_URI"
      value = var.ecr_repository_url
    }
    environment_variable {
      name  = "ENV_NAME"
      value = var.env_name
    }
    environment_variable {
      name  = "ECR_NAME"
      value = var.ecr_repository_name
    }
    environment_variable {
      name  = "SVC_NAME"
      value = var.service_name
    }
    environment_variable {
      name  = "GITLAB_USER_EMAIL"
      value = var.gitlab_user_email
    }
    environment_variable {
      name  = "GITLAB_URL"
      value = var.gitlab_repo_url
    }
    environment_variable {
      name  = "GITLAB_USER"
      value = var.gitlab_user
    }
    environment_variable {
      name  = "GITLAB_PAT"
      value = var.gitlab_pat
    }
    environment_variable {
      name  = "SECRET_NAME"
      value = var.secret_name
    }
    environment_variable {
      name  = "NEW_RELIC_LICENSE_KEY"
      value = var.new_relic_license_key
    }
  }

  # Inline build commands (instead of buildspec.yml)
  source {
    type = "CODEPIPELINE"

    buildspec = <<EOF
version: 0.2

phases:

  pre_build:
    commands:
      - echo "Logging in to Amazon ECR..."
      - aws ecr get-login-password --region $ECR_REGION | docker login --username AWS --password-stdin $AWS_ACCN_ID.dkr.ecr.$ECR_REGION.amazonaws.com
      - if [ $? -ne 0 ]; then echo "ECR login failed"; exit 1; fi

  build:
    commands:
      - echo "Building Docker image for $SVC_NAME..."
      - export TAG="$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | head -c 4)"
      - docker build -t $ECR_URI:$SVC_NAME\_$TAG --build-arg node_env=$ENV_NAME --build-arg aws_secrets=$SECRET_NAME --build-arg new_relic_license_key=$NEW_RELIC_LICENSE_KEY --build-arg aws_default_region=$ECR_REGION .
      - if [ $? -ne 0 ]; then echo "Docker build failed"; exit 1; fi

  post_build:
    commands:
      - echo "Pushing Docker image to ECR..."
      - docker push $ECR_URI:$SVC_NAME\_$TAG
      - if [ $? -ne 0 ]; then echo "Docker push failed"; exit 1; fi

      - echo "Cloning GitLab repository..."
      - git clone -b $ENV_NAME https://$GITLAB_USER:$GITLAB_PAT@$GITLAB_URL
      - cd k8s-argocd-mainfest/

      - echo "Configuring Git..."
      - git config --global user.email $GITLAB_USER_EMAIL
      - git config --global user.name $GITLAB_USER

      - git checkout 
      - cd $SVC_NAME 

      - echo "Modifying deployment.yaml for $SVC_NAME..."
      - sed -i "s|\($AWS_ACCN_ID\.dkr\.ecr\.$ECR_REGION\.amazonaws\.com/$ECR_NAME:$SVC_NAME\)_.*|\1_$TAG|g" deployment.yaml

      - echo "Showing deployment.yaml contents..."
      - cat deployment.yaml

      - echo "Committing changes to Git..."
      - git add deployment.yaml
      - git commit -m "new image tag $TAG for $SVC_NAME"
      - git push origin -u $ENV_NAME
      - if [ $? -ne 0 ]; then echo "Git push failed"; exit 1; fi

artifacts:
  files:
    - '**/*'
EOF
  }

  tags = local.tags
}


