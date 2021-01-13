TERRAFORM_APPLY?=true

build:
	docker build \
		--tag useparagon/on-prem-scripts \
		-f scripts/Dockerfile \
		.

inspect:
	docker run \
		-it \
		--rm useparagon/on-prem-scripts:latest \
		bash -c "terraform --version"

generate-key-pair:
	docker run \
		-it \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/on-prem-scripts:latest \
		bash -c "sh scripts/generate-key-pair.sh"

terraform-aws:
	docker run \
		-it \
		--env TERRAFORM_APPLY=${TERRAFORM_APPLY} \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/on-prem-scripts:latest \
		bash -c "sh scripts/terraform-aws.sh"