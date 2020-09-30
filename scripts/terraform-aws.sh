#!/bin/sh

ROOT_DIR="$(cd "$(dirname "$0")" && cd ../ && pwd)"
CACHE_DIR=$ROOT_DIR/.cache
SECURE_DIR=$ROOT_DIR/.secure
TF_DIR=$CACHE_DIR/aws

# All files are copied into the `.cache` directory & executed from there

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -p|--preserve) PRESERVE="true" ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Copy AWS terraform files
if [[ "$PRESERVE" == "true" ]]; then
  echo "Preserving terraform config."
else
  sh $ROOT_DIR/scripts/generate-key-pair.sh

  cp $ROOT_DIR/.secure/id_rsa $CACHE_DIR/id_rsa
  cp $ROOT_DIR/.secure/id_rsa.pub $CACHE_DIR/id_rsa.pub

  rm -Rf $CACHE_DIR/aws
  cp -R $ROOT_DIR/aws $TF_DIR

  cp $ROOT_DIR/.env-aws $CACHE_DIR/.env-aws
  if [[ -f "$SECURE_DIR/.env-aws" ]]; then
    cp $SECURE_DIR/.env-aws $CACHE_DIR/.env-aws
  fi

  # Load variables
  TF_ORGANIZATION=$(grep TF_ORGANIZATION $CACHE_DIR/.env-aws | cut -d '=' -f2)
  TF_WORKSPACE=$(grep TF_WORKSPACE $CACHE_DIR/.env-aws | cut -d '=' -f2)
  AWS_ACCESS_KEY_ID=$(grep AWS_ACCESS_KEY_ID $CACHE_DIR/.env-aws | cut -d '=' -f2)
  AWS_SECRET_ACCESS_KEY=$(grep AWS_SECRET_ACCESS_KEY $CACHE_DIR/.env-aws | cut -d '=' -f2)
  AWS_REGION=$(grep AWS_REGION $CACHE_DIR/.env-aws | cut -d '=' -f2)
  SSL_DOMAIN=$(grep SSL_DOMAIN $CACHE_DIR/.env-aws | cut -d '=' -f2)
  PUBLIC_KEY=$(cat $SECURE_DIR/id_rsa.pub)
  PRIVATE_KEY=$(cat $SECURE_DIR/id_rsa)

  if [[ "$TF_ORGANIZATION" == "" ]]; then
    echo "TF_ORGANIZATION is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [[ "$TF_WORKSPACE" == "" ]]; then
    echo "TF_WORKSPACE is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [[ "$AWS_ACCESS_KEY_ID" == "" ]]; then
    echo "AWS_ACCESS_KEY_ID is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [[ "$AWS_SECRET_ACCESS_KEY" == "" ]]; then
    echo "AWS_SECRET_ACCESS_KEY is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [[ "$AWS_REGION" == "" ]]; then
    echo "AWS_REGION is empty. Please add it to your \".env-aws\" file"
    exit 1
  elif [[ "$SSL_DOMAIN" == "" ]]; then
    echo "⚠️  SSL_DOMAIN is empty. Please add it to your \".env-aws\" file to add SSL support."
  fi

  # Create or copy terraform variables file (vars.auto.tfvars)
  TF_VARS_FILE=$TF_DIR/vars.auto.tfvars
  if [[ -f "$ROOT_DIR/aws/vars.auto.tfvars" ]]; then
    cp $ROOT_DIR/aws/vars.auto.tfvars $TF_VARS_FILE
    echo "" >> $TF_VARS_FILE
  else
    touch $TF_VARS_FILE
  fi

  echo "aws_region=\"$AWS_REGION\"" >> $TF_VARS_FILE
  echo "aws_access_key_id=\"$AWS_ACCESS_KEY_ID\"" >> $TF_VARS_FILE
  echo "aws_secret_access_key=\"$AWS_SECRET_ACCESS_KEY\"" >> $TF_VARS_FILE
  echo "ssl_domain=\"$SSL_DOMAIN\"" >> $TF_VARS_FILE
  echo "public_key=<<EOF\n$PUBLIC_KEY\nEOF" >> $TF_VARS_FILE
  echo "private_key=<<EOF\n$PRIVATE_KEY\nEOF" >> $TF_VARS_FILE

  # Create `main.tf` file from `.env-aws` variables
  echo "⏱  Preparing \"main.tf\"..."
  cp $TF_DIR/templates/main.tpl.tf $TF_DIR/main.tf
  sed -i -e "s~__TF_ORGANIZATION__~$TF_ORGANIZATION~g" $TF_DIR/main.tf >> $CACHE_DIR/aws/main.tf
  sed -i -e "s~__TF_WORKSPACE__~$TF_WORKSPACE~g" $TF_DIR/main.tf >> $TF_DIR/main.tf
  rm $TF_DIR/main.tf-e
  echo "✅ Prepared \"main.tf\""


  (cd $TF_DIR && terraform init)
fi

# Run terraform
# (cd $TF_DIR && terraform init && terraform validate && terraform plan && terraform apply)
echo "⏱  Validating terraform..."
(cd $TF_DIR && terraform validate && terraform plan && terraform apply)