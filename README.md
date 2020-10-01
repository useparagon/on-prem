<p align="center">
  <a href="https://www.useparagon.com/" target="blank"><img src="./assets/paragon-logo-dark.png" width="320" alt="Paragon Logo" /></a>
</p>

<p align="center">
  <b>
    Paragon lets you build production-ready integrations in minutes, not months.
  </b>
</p>

## Description

This repository is a set of tools to help you run Paragon on your own infrastructure. Paragon comes bundled in a <a href="https://hub.docker.com/repository/docker/useparagon/on-prem">docker image</a>, meaning you can run it on a laptop, linux server, AWS, GCP, Azure, or any other server or cloud that supports Docker and has internet connectivity.

We recommend using Docker Compose to get up and running quickly.

You will need a license to run the docker image. If you don't already have one, please contact [**sales@useparagon.com**](mailto:sales@useparagon.com), and we'll get you connected.

## Getting Started

#### Minimum requirements

1. a license from Paragon (contact [**sales@useparagon.com**](mailto:sales@useparagon.com) if you don't have one)
2. a server
3. a Postgres database
4. a Redis database
5. an AWS account and S3 bucket
6. a SendGrid account

#### Running Paragon

1. Download this repo using `git clone git@github.com:useparagon/on-prem.git`
2. Add your license, Postgres, Redis, AWS S3, and SendGrid connection info in the `.env-docker` file.
3. Run `sh scripts/start.sh` from a terminal.
4. Open `http://localhost:1704` in your browser to access Paragon.

#### Deploying to AWS Cloud

We have provided a series of scripts and [Terraform](https://www.terraform.io/) configuration for provisioning the necessary infrastructure.

1. Download this repo using `git clone git@github.com:useparagon/on-prem.git`
2. Download Terraform version `0.13.2`.
3. Add your license, Postgres, Redis, AWS S3, and SendGrid connection info in the `.env-docker` file.
4. Update the `.env-aws` file.
   1. Add your AWS keys.
   2. Add a bucket that you own to `TF_BUCKET`.
   3. Choose a random key to store your Terraform state and put it in `TF_STATE_KEY`.
5. Run `sh scripts/terraform-aws.sh`
6. Take the output from the ALBs generated in Terraform and update the values in your `.env-docker` with the corresponding values.
   1. Set the value of the `cerberus` alb to `CERBERUS_PUBLIC_URL`.
   2. Set the value of the `hercules` alb to `HERCULES_PUBLIC_URL`.
   3. Set the value of the `hermes` alb to `HERMES_PUBLIC_URL`.
   4. Set the value of the `rest-api` alb to `REST_API_PUBLIC_URL`.
   5. Set the value of the `web-app` alb to `WEB_APP_PUBLIC_URL`.
7. Run `sh scripts/terraform-aws.sh` again.
8. SSH into your newly provisioned EC2 instance.
   1. Retrieve the IP from your Terraform output set to `ec2.public_ip`.
   2. Run `ssh -v -i .secure/id_rsa ubuntu@IP_ADDRESS_GOES_HERE`
9. Once inside the server, run `sudo scripts/start.sh`.

Paragon should now be running live on your AWS infrastructure.

#### Questions? Comments?

Please contact [**support@useparagon.com**](mailto:support@useparagon.com), and we'll connect you with our enterprise team to help make your on-prem installation as frictionless as possible.
