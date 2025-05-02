SUBDIRS := $(wildcard */.)

check: init validate plan

init validate plan:
	cd $(template) && terraform $@

upgrade: $(SUBDIRS)
$(SUBDIRS):
	cd $@ && terraform init -upgrade

push:
	cd $(template) && coder templates push $(template) -y