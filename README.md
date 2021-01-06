<p align="center">
  <a href="https://www.useparagon.com/" target="blank"><img src="./assets/paragon-logo-dark.png" width="320" alt="Paragon Logo" /></a>
</p>

<p align="center">
  <b>
    Paragon lets you build production-ready integrations in minutes, not months.
  </b>
</p>

## Description

This repository is a set of tools to help you run Paragon on your own infrastructure. Paragon comes bundled in a <a target="_blank" href="https://hub.docker.com/repository/docker/useparagon/on-prem">docker image</a>, meaning you can run it on AWS, GCP, Azure, or any other server or cloud that supports Docker and has internet connectivity.

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
2. Add your configuration & access keys to the `.env-docker` file.
   1. Add your licence to the `LICENSE` environment variable.
   2. Create a username for your postgres database and add it to the `POSTGRES_USERNAME` environment variable.
   3. Provide a password for your postgres database and add it to the `POSTGRES_PASSWORD` environment variable.
   4. Provide a database for your postgres database and add it to the `POSTGRES_DATABASE` environment variable, e.g. `postgres`.
   5. Provide a Sendgrid API key and add it to the `SENDGRID_API_KEY` environment variable.
   6. Provide a Sendgrid sender email and add it to the `SENDGRID_FROM_ADDRESS` environment variable.
3. Update the `.env-aws` file with your AWS keys.
4. Run `make terraform-aws`

Paragon should now be running live on your AWS infrastructure.

#### Questions?

Please contact [**support@useparagon.com**](mailto:support@useparagon.com), and we'll connect you with our enterprise team to help make your on-prem installation as frictionless as possible.
