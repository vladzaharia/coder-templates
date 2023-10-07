check: init validate plan

init:
	cd $(template) && terraform init

validate:
	cd $(template) && terraform validate

plan:
	cd $(template) && terraform plan

push:
	cd $(template) && coder templates push $(template) -y