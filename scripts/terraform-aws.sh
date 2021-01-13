#!/bin/bash

echo "⏱  Starting terraform aws..."

prepareTerraform() {
  bash $ROOT_DIR/scripts/build.sh
  bash $ROOT_DIR/scripts/generate-key-pair.sh

  cp $ROOT_DIR/.secure/id_rsa $CACHE_DIR/id_rsa
  cp $ROOT_DIR/.secure/id_rsa.pub $CACHE_DIR/id_rsa.pub

  rm -Rf $CACHE_DIR/aws
  cp -R $ROOT_DIR/aws $TF_DIR

  cp $ROOT_DIR/.env-aws $CACHE_DIR/.env-aws
  if [ -f "$SECURE_DIR/.env-aws" ]; then
    cp $SECURE_DIR/.env-aws $CACHE_DIR/.env-aws
  fi

  # Load variables
  AWS_ACCESS_KEY_ID=$(grep AWS_ACCESS_KEY_ID $CACHE_DIR/.env-aws | cut -d '=' -f2)
  AWS_SECRET_ACCESS_KEY=$(grep AWS_SECRET_ACCESS_KEY $CACHE_DIR/.env-aws | cut -d '=' -f2)
  AWS_REGION=$(grep AWS_REGION $CACHE_DIR/.env-aws | cut -d '=' -f2)
  ELASTICACHE_NODE_TYPE=$(grep ELASTICACHE_NODE_TYPE $CACHE_DIR/.env-aws | cut -d '=' -f2)
  EC2_INSTANCE_TYPE=$(grep EC2_INSTANCE_TYPE $CACHE_DIR/.env-aws | cut -d '=' -f2)
  RDS_INSTANCE_CLASS=$(grep RDS_INSTANCE_CLASS $CACHE_DIR/.env-aws | cut -d '=' -f2)
  POSTGRES_ROOT_USERNAME=$(grep POSTGRES_ROOT_USERNAME $CACHE_DIR/.env-aws | cut -d '=' -f2)
  POSTGRES_ROOT_PASSWORD=$(grep POSTGRES_ROOT_PASSWORD $CACHE_DIR/.env-aws | cut -d '=' -f2)
  SSL_DOMAIN=$(grep SSL_DOMAIN $CACHE_DIR/.env-aws | cut -d '=' -f2)
  PUBLIC_KEY=$(cat $SECURE_DIR/id_rsa.pub)
  PRIVATE_KEY=$(cat $SECURE_DIR/id_rsa)

  # required variables
  if [ "$AWS_ACCESS_KEY_ID" == "" ]; then
    echo "AWS_ACCESS_KEY_ID is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [ "$AWS_SECRET_ACCESS_KEY" == "" ]; then
    echo "AWS_SECRET_ACCESS_KEY is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [ "$AWS_REGION" == "" ]; then
    echo "AWS_REGION is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [ "$POSTGRES_ROOT_USERNAME" == "" ]; then
    echo "POSTGRES_ROOT_USERNAME is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [ "$POSTGRES_ROOT_PASSWORD" == "" ]; then
    echo "POSTGRES_ROOT_PASSWORD is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [ "$SSL_DOMAIN" == "" ]; then
    echo "⚠️  SSL_DOMAIN is empty. Please add it to your \".env-aws\" file to add SSL support."
  fi

  # optional variables
  if [ "$ELASTICACHE_NODE_TYPE" == "" ]; then
    RDS_INSTANCE_CLASS = "cache.r4.xlarge"
  fi

  if [ "$EC2_INSTANCE_TYPE" == "" ]; then
    EC2_INSTANCE_TYPE = "t3.xlarge"
  fi

  if [ "$RDS_INSTANCE_CLASS" == "" ]; then
    RDS_INSTANCE_CLASS = "db.t3.small"
  fi

  # Create or copy terraform variables file (vars.auto.tfvars)
  TF_VARS_FILE=$TF_DIR/vars.auto.tfvars
  if [ -f "$ROOT_DIR/aws/vars.auto.tfvars" ]; then
    cp $ROOT_DIR/aws/vars.auto.tfvars $TF_VARS_FILE
    echo "" >> $TF_VARS_FILE
  else
    touch $TF_VARS_FILE
  fi

  echo "aws_access_key_id=\"$AWS_ACCESS_KEY_ID\"" >> $TF_VARS_FILE
  echo "aws_secret_access_key=\"$AWS_SECRET_ACCESS_KEY\"" >> $TF_VARS_FILE
  echo "aws_region=\"$AWS_REGION\"" >> $TF_VARS_FILE
  echo "elasticache_node_type=\"$ELASTICACHE_NODE_TYPE\"" >> $TF_VARS_FILE
  echo "ec2_instance_type=\"$EC2_INSTANCE_TYPE\"" >> $TF_VARS_FILE
  echo "rds_instance_class=\"$RDS_INSTANCE_CLASS\"" >> $TF_VARS_FILE
  echo "postgres_root_username=\"$POSTGRES_ROOT_USERNAME\"" >> $TF_VARS_FILE
  echo "postgres_root_password=\"$POSTGRES_ROOT_PASSWORD\"" >> $TF_VARS_FILE
  echo "ssl_domain=\"$SSL_DOMAIN\"" >> $TF_VARS_FILE

  echo "public_key=<<EOF" >> $TF_VARS_FILE
  echo "$PUBLIC_KEY" >> $TF_VARS_FILE
  echo "EOF" >> $TF_VARS_FILE

  echo "private_key=<<EOF" >> $TF_VARS_FILE
  echo "$PRIVATE_KEY" >> $TF_VARS_FILE
  echo "EOF" >> $TF_VARS_FILE

  # Create `main.tf` file from `.env-aws` variables
  echo "⏱  Preparing \"main.tf\"..."
  cp $TF_DIR/templates/main.tpl.tf $TF_DIR/main.tf
  sed -i -e "s~__AWS_REGION__~$AWS_REGION~g" $TF_DIR/main.tf >> $TF_DIR/main.tf
  echo "✅ Prepared \"main.tf\""

  (cd $TF_DIR && terraform init)
}

updateDockerVariables() {
  # get the application load balancers, s3, postgres and elasticache config + update the environment variables
  sed -i "/^CERBERUS_PUBLIC_URL=/c\CERBERUS_PUBLIC_URL=http://$(cd $TF_DIR && terraform output -json | jq -r '.albs.value.cerberus')" $1
  sed -i "/^HERCULES_PUBLIC_URL=/c\HERCULES_PUBLIC_URL=http://$(cd $TF_DIR && terraform output -json | jq -r '.albs.value.hercules')" $1
  sed -i "/^HERMES_PUBLIC_URL=/c\HERMES_PUBLIC_URL=http://$(cd $TF_DIR && terraform output -json | jq -r '.albs.value.hermes')" $1
  sed -i "/^REST_API_PUBLIC_URL=/c\REST_API_PUBLIC_URL=http://$(cd $TF_DIR && terraform output -json | jq -r '.albs.value["rest-api"]')" $1
  sed -i "/^WEB_APP_PUBLIC_URL=/c\WEB_APP_PUBLIC_URL=http://$(cd $TF_DIR && terraform output -json | jq -r '.albs.value["web-app"]')" $1
  sed -i "/^PASSPORT_PUBLIC_URL=/c\PASSPORT_PUBLIC_URL=http://$(cd $TF_DIR && terraform output -json | jq -r '.albs.value.passport')" $1

  sed -i "/^REDIS_URL=/c\REDIS_URL=$(cd $TF_DIR && terraform output -json | jq -r '.elasticache.value.host'):$(cd $TF_DIR && terraform output -json | jq -r '.elasticache.value.port')" $1

  sed -i "/^POSTGRES_HOST=/c\POSTGRES_HOST=$(cd $TF_DIR && terraform output -json | jq -r '.rds.value.host')" $1
  sed -i "/^POSTGRES_PORT=/c\POSTGRES_PORT=$(cd $TF_DIR && terraform output -json | jq -r '.rds.value.port')" $1
  sed -i "/^POSTGRES_USERNAME=/c\POSTGRES_USERNAME=$(cd $TF_DIR && terraform output -json | jq -r '.rds.value.user')" $1
  sed -i "/^POSTGRES_PASSWORD=/c\POSTGRES_PASSWORD=$(cd $TF_DIR && terraform output -json | jq -r '.rds.value.password')" $1
  sed -i "/^POSTGRES_DATABASE=/c\POSTGRES_DATABASE=$(cd $TF_DIR && terraform output -json | jq -r '.rds.value.database')" $1

  sed -i "/^S3_ACCESS_KEY_ID=/c\S3_ACCESS_KEY_ID=$(cd $TF_DIR && terraform output -json | jq -r '.s3.value.accessKeyId')" $1
  sed -i "/^S3_SECRET_ACCESS_KEY=/c\S3_SECRET_ACCESS_KEY=$(cd $TF_DIR && terraform output -json | jq -r '.s3.value.accessKeySecret')" $1
  sed -i "/^S3_BUCKET=/c\S3_BUCKET=$(cd $TF_DIR && terraform output -json | jq -r '.s3.value.bucket')" $1
}

wrappedUpdateDockerVariables() {
  updateDockerVariables $CACHE_DIR/.env-docker
  if [ -f "$SECURE_DIR/.env-aws" ]; then
    updateDockerVariables $SECURE_DIR/.env-docker
  fi
}

TERRAFORM_APPLY=${TERRAFORM_APPLY:-true}
ROOT_DIR="$(cd "$(dirname "$0")" && cd ../ && pwd -P)"
CACHE_DIR=$ROOT_DIR/.cache
SECURE_DIR=$ROOT_DIR/.secure
TF_DIR=$CACHE_DIR/aws

echo "ℹ️  ROOT_DIR: $ROOT_DIR"
echo "ℹ️  CACHE_DIR: $CACHE_DIR"
echo "ℹ️  SECURE_DIR: $SECURE_DIR"
echo "ℹ️  TF_DIR: $TF_DIR"

# All files are copied into the `.cache` directory & executed from there
while [ "$#" -gt 0 ]; do
    case $1 in
        -p|--preserve) PRESERVE="true" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Copy AWS terraform files
if [ "$PRESERVE" == "true" ]; then
  echo "Preserving terraform config."
else
  prepareTerraform
fi

# Run terraform
if [ "$TERRAFORM_APPLY" == "true" ]; then
  # this is all done as one command so if any step fails the downstream commands don't execute
  (cd $TF_DIR && terraform validate && terraform apply && wrappedUpdateDockerVariables && terraform apply -auto-approve)
else
  (cd $TF_DIR && terraform validate && terraform plan)
fi

echo "✅ Completed provisioning aws via Terraform."