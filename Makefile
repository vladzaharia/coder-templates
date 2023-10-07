check:
	echo Checking $(template)...
	cd $(template) && terraform validate
	cd $(template) && terraform plan

push:
	echo Checking $(template)...
	cd $(template) && coder templates push $(template) -y