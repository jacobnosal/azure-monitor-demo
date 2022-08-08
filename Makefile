default: docs

.PHONY: docs
docs: 
	cat README.md

build:
	set -o errexit; set -o allexport; source .env; set +o allexport; \
	terraform plan -out main.tfplan -var-file demo.tfvars; \
	terraform apply main.tfplan

destroy:
	set -o errexit; set -o allexport; source .env; set +o allexport; \
	terraform plan -destroy -out main.destroy.tfplan -var-file demo.tfvars; \
	terraform apply main.destroy.tfplan