build:
	docker build \
		--tag useparagon/on-prem-scripts \
		-f scripts/Dockerfile \
		.

inspect:
	docker run \
		-it \
		--rm useparagon/on-prem-scripts:latest \
		sh -c "terraform --version"

generate-key-pair:
	docker run \
		-it \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/on-prem-scripts:latest \
		sh -c "sh scripts/generate-key-pair.sh"

terraform-aws:
	docker run \
		-it \
		--mount source="$(shell pwd)",target=/usr/src/app,type=bind \
		--rm useparagon/on-prem-scripts:latest \
		sh -c "sh scripts/terraform-aws.sh"