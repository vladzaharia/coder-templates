check: init validate plan
	echo Checking $(template)...

init:
	echo Initializing $(template)...
	cd $(template) && terraform init

validate:
	echo Validating $(template)...
	cd $(template) && terraform validate

plan:
	echo Planning $(template)...
	cd $(template) && terraform plan

push:
	echo Checking $(template)...
	cd $(template) && coder templates push $(template) -y