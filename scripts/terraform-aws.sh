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

  if [ -f "$SECURE_DIR/terraform.tfstate" ]; then
    cp $SECURE_DIR/terraform.tfstate $TF_DIR/terraform.tfstate
  fi

  # Load variables
  ORGANIZATION=$(grep ORGANIZATION $CACHE_DIR/.env-aws | cut -d '=' -f2)
  APP_NAME=$(grep APP_NAME $CACHE_DIR/.env-aws | cut -d '=' -f2)

  TF_BACKEND=$(grep TF_BACKEND $CACHE_DIR/.env-aws | cut -d '=' -f2)
  TF_TOKEN=$(grep TF_TOKEN $CACHE_DIR/.env-aws | cut -d '=' -f2)
  TF_ORG=$(grep TF_ORG $CACHE_DIR/.env-aws | cut -d '=' -f2)
  TF_WORKSPACE=$(grep TF_WORKSPACE $CACHE_DIR/.env-aws | cut -d '=' -f2)

  AWS_ACCESS_KEY_ID=$(grep AWS_ACCESS_KEY_ID $CACHE_DIR/.env-aws | cut -d '=' -f2)
  AWS_SECRET_ACCESS_KEY=$(grep AWS_SECRET_ACCESS_KEY $CACHE_DIR/.env-aws | cut -d '=' -f2)
  AWS_REGION=$(grep AWS_REGION $CACHE_DIR/.env-aws | cut -d '=' -f2)

  VPC_ID=$(grep VPC_ID $CACHE_DIR/.env-aws | cut -d '=' -f2)
  ELASTICACHE_NODE_TYPE=$(grep ELASTICACHE_NODE_TYPE $CACHE_DIR/.env-aws | cut -d '=' -f2)
  EC2_INSTANCE_TYPE=$(grep EC2_INSTANCE_TYPE $CACHE_DIR/.env-aws | cut -d '=' -f2)
  RDS_INSTANCE_CLASS=$(grep RDS_INSTANCE_CLASS $CACHE_DIR/.env-aws | cut -d '=' -f2)
  POSTGRES_ROOT_USERNAME=$(grep POSTGRES_ROOT_USERNAME $CACHE_DIR/.env-aws | cut -d '=' -f2)
  POSTGRES_ROOT_PASSWORD=$(grep POSTGRES_ROOT_PASSWORD $CACHE_DIR/.env-aws | cut -d '=' -f2)
  SSL_DOMAIN=$(grep SSL_DOMAIN $CACHE_DIR/.env-aws | cut -d '=' -f2)
  SSL_ONLY=$(grep SSL_ONLY $CACHE_DIR/.env-aws | cut -d '=' -f2)
  ACL_POLICY=$(grep ACL_POLICY $CACHE_DIR/.env-aws | cut -d '=' -f2)
  ACL_PUBLIC=$(grep ACL_PUBLIC $CACHE_DIR/.env-aws | cut -d '=' -f2)
  ACL_PUBLIC_IP_OVERRIDE=$(grep ACL_PUBLIC_IP_OVERRIDE $CACHE_DIR/.env-aws | cut -d '=' -f2)
  IP_WHITELIST=$(grep IP_WHITELIST $CACHE_DIR/.env-aws | cut -d '=' -f2)
  ALB_EXTERNAL_SECURITY_GROUPS=$(grep ALB_EXTERNAL_SECURITY_GROUPS $CACHE_DIR/.env-aws | cut -d '=' -f2)
  PUBLIC_KEY=$(cat $SECURE_DIR/id_rsa.pub)
  PRIVATE_KEY=$(cat $SECURE_DIR/id_rsa)

  # required variables
  if [ "$ORGANIZATION" == "" ]; then
    echo "ORGANIZATION is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [ "$AWS_ACCESS_KEY_ID" == "" ]; then
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

  # ensure SSL configuration properly set if provided
  CERBERUS_PUBLIC_URL=$(grep CERBERUS_PUBLIC_URL $CACHE_DIR/.env-docker | cut -d '=' -f2)
  HERCULES_PUBLIC_URL=$(grep HERCULES_PUBLIC_URL $CACHE_DIR/.env-docker | cut -d '=' -f2)
  HERMES_PUBLIC_URL=$(grep HERMES_PUBLIC_URL $CACHE_DIR/.env-docker | cut -d '=' -f2)
  REST_API_PUBLIC_URL=$(grep REST_API_PUBLIC_URL $CACHE_DIR/.env-docker | cut -d '=' -f2)
  WEB_APP_PUBLIC_URL=$(grep WEB_APP_PUBLIC_URL $CACHE_DIR/.env-docker | cut -d '=' -f2)
  PASSPORT_PUBLIC_URL=$(grep PASSPORT_PUBLIC_URL $CACHE_DIR/.env-docker | cut -d '=' -f2)
  if [ "$SSL_DOMAIN" == "" -a "$SSL_ONLY" == "true" ]; then
    echo "❌ `SSL_DOMAIN` is not configured but SSL_ONLY is set to true. You'll need to configure `SSL_DOMAIN` to force SSL."
    exit 1
  elif [ "$SSL_DOMAIN" != "" -a "$CERBERUS_PUBLIC_URL" == "" ]; then
    echo "❌ `SSL_DOMAIN` is configured but `CERBERUS_PUBLIC_URL` is empty. You'll need to configure `CERBERUS_PUBLIC_URL`."
    exit 1
  elif [ "$SSL_DOMAIN" != "" -a "$HERCULES_PUBLIC_URL" == "" ]; then
    echo "❌ `SSL_DOMAIN` is configured but `HERCULES_PUBLIC_URL` is empty. You'll need to configure `HERCULES_PUBLIC_URL`."
    exit 1
  elif [ "$SSL_DOMAIN" != "" -a "$HERMES_PUBLIC_URL" == "" ]; then
    echo "❌ `SSL_DOMAIN` is configured but `HERMES_PUBLIC_URL` is empty. You'll need to configure `HERMES_PUBLIC_URL`."
    exit 1
  elif [ "$SSL_DOMAIN" != "" -a "$REST_API_PUBLIC_URL" == "" ]; then
    echo "❌ `SSL_DOMAIN` is configured but `REST_API_PUBLIC_URL` is empty. You'll need to configure `REST_API_PUBLIC_URL`."
    exit 1
  elif [ "$SSL_DOMAIN" != "" -a "$WEB_APP_PUBLIC_URL" == "" ]; then
    echo "❌ `SSL_DOMAIN` is configured but `WEB_APP_PUBLIC_URL` is empty. You'll need to configure `WEB_APP_PUBLIC_URL`."
    exit 1
  elif [ "$SSL_DOMAIN" != "" -a "$PASSPORT_PUBLIC_URL" == "" ]; then
    echo "❌ `SSL_DOMAIN` is configured but `PASSPORT_PUBLIC_URL` is empty. You'll need to configure `PASSPORT_PUBLIC_URL`."
    exit 1
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

  echo "organization=\"$ORGANIZATION\"" >> $TF_VARS_FILE

  if [ "$APP_NAME" != "" ]; then
    echo "app_name=\"$APP_NAME\"" >> $TF_VARS_FILE
  fi

  echo "aws_access_key_id=\"$AWS_ACCESS_KEY_ID\"" >> $TF_VARS_FILE
  echo "aws_secret_access_key=\"$AWS_SECRET_ACCESS_KEY\"" >> $TF_VARS_FILE
  echo "aws_region=\"$AWS_REGION\"" >> $TF_VARS_FILE

  if [ "$VPC_ID" != "" ]; then
    echo "vpc_id=\"$VPC_ID\"" >> $TF_VARS_FILE
  fi

  echo "elasticache_node_type=\"$ELASTICACHE_NODE_TYPE\"" >> $TF_VARS_FILE
  echo "ec2_instance_type=\"$EC2_INSTANCE_TYPE\"" >> $TF_VARS_FILE
  echo "rds_instance_class=\"$RDS_INSTANCE_CLASS\"" >> $TF_VARS_FILE
  echo "postgres_root_username=\"$POSTGRES_ROOT_USERNAME\"" >> $TF_VARS_FILE
  echo "postgres_root_password=\"$POSTGRES_ROOT_PASSWORD\"" >> $TF_VARS_FILE
  echo "ssl_domain=\"$SSL_DOMAIN\"" >> $TF_VARS_FILE
  echo "ssl_only=$SSL_ONLY" >> $TF_VARS_FILE

  if [ "$ACL_POLICY" != "" ]; then
    echo "acl_policy=\"$ACL_POLICY\"" >> $TF_VARS_FILE
  fi

  if [ "$ACL_PUBLIC" != "" ]; then
    FORMATTED_ACL_PUBLIC=$(echo $ACL_PUBLIC | sed 's|,|","|g;s|.*|"&"|')
    echo "acl_public=[$FORMATTED_ACL_PUBLIC]" >> $TF_VARS_FILE
  fi

  if [ "$ACL_PUBLIC_IP_OVERRIDE" != "" ]; then
    FORMATTED_ACL_PUBLIC_IP_OVERRIDE=$(echo $ACL_PUBLIC_IP_OVERRIDE | sed 's|,|","|g;s|.*|"&"|')
    echo "acl_public_ip_override=[$FORMATTED_ACL_PUBLIC_IP_OVERRIDE]" >> $TF_VARS_FILE
  fi

  if [ "$IP_WHITELIST" != "" ]; then
    FORMATTED_IP_WHITELIST=$(echo $IP_WHITELIST | sed 's|,|","|g;s|.*|"&"|')
    echo "ip_whitelist=[$FORMATTED_IP_WHITELIST]" >> $TF_VARS_FILE
  fi

  if [ "$ALB_EXTERNAL_SECURITY_GROUPS" != "" ]; then
    FORMATTED_ALB_EXTERNAL_SECURITY_GROUPS=$(echo $ALB_EXTERNAL_SECURITY_GROUPS | sed 's|,|","|g;s|.*|"&"|')
    echo "alb_external_security_groups=\"$FORMATTED_ALB_EXTERNAL_SECURITY_GROUPS\"" >> $TF_VARS_FILE
  fi

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

  if [ "$TF_BACKEND" == "" ] || [ "$TF_BACKEND" == "local" ]; then
    echo "ℹ️  Preparing local terraform configuration."
    TF_CONFIG="backend \"local\" {\n"
    TF_CONFIG="$TF_CONFIG    path     = \"../../.secure/terraform.tfstate\"\n"
    TF_CONFIG="$TF_CONFIG  }"
    sed -i -e "s~__TF_CONFIG__ {}~$TF_CONFIG~g" $TF_DIR/main.tf >> $TF_DIR/main.tf
  elif [ "$TF_BACKEND" == "remote" ]; then
    echo "ℹ️  Preparing remote terraform configuration."
    TF_CONFIG="backend \"remote\" {\n"
    TF_CONFIG="$TF_CONFIG    hostname     = \"app.terraform.io\"\n"
    TF_CONFIG="$TF_CONFIG    organization = \"$TF_ORG\"\n"
    TF_CONFIG="$TF_CONFIG    token        = \"$TF_TOKEN\"\n\n"
    TF_CONFIG="$TF_CONFIG    workspaces {\n"
    TF_CONFIG="$TF_CONFIG      name       = \"$TF_WORKSPACE\"\n"
    TF_CONFIG="$TF_CONFIG    }\n"
    TF_CONFIG="$TF_CONFIG  }"
    sed -i -e "s~__TF_CONFIG__ {}~$TF_CONFIG~g" $TF_DIR/main.tf >> $TF_DIR/main.tf
  else
    echo "❌  Invalid value specified for `TF_CONFIG`. Valid values are `remote` and `local`."
    exit 1
  fi

  echo "✅ Prepared \"main.tf\""

  (cd $TF_DIR && terraform init)

  if [ -f "$SECURE_DIR/terraform.tfstate" -a "$TF_CONFIG" == "remote" ]; then
    mv $SECURE_DIR/terraform.tfstate $SECURE_DIR/terraform-migrated.tfstate

    if [ -f "$TF_DIR/terraform.tfstate" ]; then
      rm $TF_DIR/terraform.tfstate
    fi
  fi
}

updateDockerVariables() {
  # get the application load balancers, s3, postgres and elasticache config + update the environment variables
  TERRAFORM_OUTPUT=$(cd $TF_DIR && terraform output -json)

  # if the user provies a custom domain, we don't want to override their public url settings
  if [ "$SSL_DOMAIN" == "" ]; then
    sed -i "/^CERBERUS_PUBLIC_URL=/c\CERBERUS_PUBLIC_URL=http://$(echo $TERRAFORM_OUTPUT | jq -r '.albs.value.cerberus')" $1
    sed -i "/^HERCULES_PUBLIC_URL=/c\HERCULES_PUBLIC_URL=http://$(echo $TERRAFORM_OUTPUT | jq -r '.albs.value.hercules')" $1
    sed -i "/^HERMES_PUBLIC_URL=/c\HERMES_PUBLIC_URL=http://$(echo $TERRAFORM_OUTPUT | jq -r '.albs.value.hermes')" $1
    sed -i "/^REST_API_PUBLIC_URL=/c\REST_API_PUBLIC_URL=http://$(echo $TERRAFORM_OUTPUT | jq -r '.albs.value["rest-api"]')" $1
    sed -i "/^WEB_APP_PUBLIC_URL=/c\WEB_APP_PUBLIC_URL=http://$(echo $TERRAFORM_OUTPUT | jq -r '.albs.value["web-app"]')" $1
    sed -i "/^PASSPORT_PUBLIC_URL=/c\PASSPORT_PUBLIC_URL=http://$(echo $TERRAFORM_OUTPUT | jq -r '.albs.value.passport')" $1
  fi

  sed -i "/^REDIS_URL=/c\REDIS_URL=$(echo $TERRAFORM_OUTPUT | jq -r '.elasticache.value.host'):$(echo $TERRAFORM_OUTPUT | jq -r '.elasticache.value.port')" $1

  sed -i "/^POSTGRES_HOST=/c\POSTGRES_HOST=$(echo $TERRAFORM_OUTPUT | jq -r '.rds.value.host')" $1
  sed -i "/^POSTGRES_PORT=/c\POSTGRES_PORT=$(echo $TERRAFORM_OUTPUT | jq -r '.rds.value.port')" $1
  sed -i "/^POSTGRES_USERNAME=/c\POSTGRES_USERNAME=$(echo $TERRAFORM_OUTPUT | jq -r '.rds.value.user')" $1
  sed -i "/^POSTGRES_PASSWORD=/c\POSTGRES_PASSWORD=$(echo $TERRAFORM_OUTPUT | jq -r '.rds.value.password')" $1
  sed -i "/^POSTGRES_DATABASE=/c\POSTGRES_DATABASE=$(echo $TERRAFORM_OUTPUT | jq -r '.rds.value.database')" $1

  sed -i "/^S3_ACCESS_KEY_ID=/c\S3_ACCESS_KEY_ID=$(echo $TERRAFORM_OUTPUT | jq -r '.s3.value.accessKeyId')" $1
  sed -i "/^S3_SECRET_ACCESS_KEY=/c\S3_SECRET_ACCESS_KEY=$(echo $TERRAFORM_OUTPUT | jq -r '.s3.value.accessKeySecret')" $1
  sed -i "/^S3_BUCKET=/c\S3_BUCKET=$(echo $TERRAFORM_OUTPUT | jq -r '.s3.value.bucket')" $1
}

wrappedUpdateDockerVariables() {
  updateDockerVariables $CACHE_DIR/.env-docker
  if [ -f "$SECURE_DIR/.env-aws" ]; then
    updateDockerVariables $SECURE_DIR/.env-docker
  fi
}

TERRAFORM_APPLY=${TERRAFORM_APPLY:-true}
CWD="$(cd "$(dirname "$0")" && pwd)"
source $CWD/vars.sh || exit 1

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