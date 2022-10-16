.PHONY: test build clean check_aws_env
SHELL := /usr/bin/env bash

deployment_name ?= vpc-a

check_env:
ifndef deployment_name
$(error deployment_name needs to be set - deployment_name=my-deployment make build)
endif
ifndef email
$(error email needs to be set - email=myemail@mail.com make build)
endif
ifndef hostname
$(error hostname needs to be set - hostname=myservice.myr53domain.com make build)
endif
ifndef AWS_PROFILE
$(error AWS_PROFILE is undefined)
endif

test: build

export TF_VAR_name=$(deployment_name)
export TF_VAR_zone_id=$(zone_id)
export TF_VAR_contact=$(email)
export TF_VAR_hostname=$(hostname)

plan: check_env
	@echo "terraform plan"; \
	pushd ./examples/basic; \
	terraform init; \
	terraform plan;
	popd;

build: check_env
	@echo "building the kong perf test env"; \
	pushd ./examples/basic; \
	terraform init; \
	terraform apply -auto-approve; \
	popd;

clean: check_env
	@echo "destroy the kong perf test env"; \
	pushd ./examples/basic; \
	terraform destroy -auto-approve; \
	popd;
