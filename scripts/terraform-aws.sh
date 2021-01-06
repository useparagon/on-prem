#!/bin/sh

echo "⏱  Starting terraform aws..."

ROOT_DIR="$(cd "$(dirname "$0")" && cd ../ && pwd)"
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
  sh $ROOT_DIR/scripts/build.sh
  sh $ROOT_DIR/scripts/generate-key-pair.sh

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
fi

# Run terraform
# (cd $TF_DIR && terraform validate)
(cd $TF_DIR && terraform validate && terraform plan && terraform apply)

# get the application load balancers, s3, postgres and elasticache config + update the environment variables
sed -i "/^CERBERUS_PUBLIC_URL=/c\CERBERUS_PUBLIC_URL=http://$(cd .cache/aws && terraform output -json | jq -r '.albs.value.cerberus')" $CACHE_DIR/.env-docker
sed -i "/^HERCULES_PUBLIC_URL=/c\HERCULES_PUBLIC_URL=http://$(cd .cache/aws && terraform output -json | jq -r '.albs.value.hercules')" $CACHE_DIR/.env-docker
sed -i "/^HERMES_PUBLIC_URL=/c\HERMES_PUBLIC_URL=http://$(cd .cache/aws && terraform output -json | jq -r '.albs.value.hermes')" $CACHE_DIR/.env-docker
sed -i "/^REST_API_PUBLIC_URL=/c\REST_API_PUBLIC_URL=http://$(cd .cache/aws && terraform output -json | jq -r '.albs.value["rest-api"]')" $CACHE_DIR/.env-docker
sed -i "/^WEB_APP_PUBLIC_URL=/c\WEB_APP_PUBLIC_URL=http://$(cd .cache/aws && terraform output -json | jq -r '.albs.value["web-app"]')" $CACHE_DIR/.env-docker
sed -i "/^PASSPORT_PUBLIC_URL=/c\PASSPORT_PUBLIC_URL=http://$(cd .cache/aws && terraform output -json | jq -r '.albs.value.passport')" $CACHE_DIR/.env-docker

sed -i "/^REDIS_URL=/c\REDIS_URL=$(cd .cache/aws && terraform output -json | jq -r '.elasticache.value.host'):$(cd .cache/aws && terraform output -json | jq -r '.elasticache.value.port')" $CACHE_DIR/.env-docker

sed -i "/^POSTGRES_HOST=/c\POSTGRES_HOST=$(cd .cache/aws && terraform output -json | jq -r '.rds.value.host')" $CACHE_DIR/.env-docker
sed -i "/^POSTGRES_PORT=/c\POSTGRES_PORT=$(cd .cache/aws && terraform output -json | jq -r '.rds.value.port')" $CACHE_DIR/.env-docker
sed -i "/^POSTGRES_USERNAME=/c\POSTGRES_USERNAME=$(cd .cache/aws && terraform output -json | jq -r '.rds.value.user')" $CACHE_DIR/.env-docker
sed -i "/^POSTGRES_PASSWORD=/c\POSTGRES_PASSWORD=$(cd .cache/aws && terraform output -json | jq -r '.rds.value.password')" $CACHE_DIR/.env-docker
sed -i "/^POSTGRES_DATABASE=/c\POSTGRES_DATABASE=$(cd .cache/aws && terraform output -json | jq -r '.rds.value.database')" $CACHE_DIR/.env-docker

sed -i "/^S3_ACCESS_KEY_ID=/c\S3_ACCESS_KEY_ID=$(cd .cache/aws && terraform output -json | jq -r '.s3.value.accessKeyId')" $CACHE_DIR/.env-docker
sed -i "/^S3_SECRET_ACCESS_KEY=/c\S3_SECRET_ACCESS_KEY=$(cd .cache/aws && terraform output -json | jq -r '.s3.value.accessKeySecret')" $CACHE_DIR/.env-docker
sed -i "/^S3_BUCKET=/c\S3_BUCKET=$(cd .cache/aws && terraform output -json | jq -r '.s3.value.bucket')" $CACHE_DIR/.env-docker

# run terraform apply again to update the configuration
(cd $TF_DIR && terraform apply -auto-approve)

echo "✅ Completed terraform aws."