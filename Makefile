check: init validate plan

init validate plan:
	cd $(template) && terraform $@

push:
	cd $(template) && coder templates push $(template) -y