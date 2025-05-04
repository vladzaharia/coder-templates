set dotenv-load

# init validate plan fmt upgrade (init -upgrade)

[private]
alias v := validate
[private]
alias p := plan
alias build := plan
[private]
alias f := format
alias fmt := format
[private]
alias u := upgrade
alias up := upgrade

# @just --choose
[private]
default:
  @just --choose

default := '_ALL_'

# Initialize Terraform template(s) and download packages
init template=default: (_run template 'init')

# Validate Terraform template(s)
validate template=default: (init template) (_run template 'validate')

# Plan Terraform template(s)
plan template=default: (init template) (_run template 'plan')

# Format Terraform template(s)
format template=default: (init template) (_run template 'fmt')

# Upgrade Terraform template(s)
upgrade template=default: (_run template 'init -upgrade')

_run template command:
	#!/bin/sh
	if [ '{{template}}' = '{{default}}' ]; then
		for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './.*/*' -not -name 'build' -not -name '_common'`; do just _run-one $folder '{{command}}'; done
	else
		just _run-one '{{template}}' '{{command}}'
	fi

_run-one template command:
	@cd {{template}} && terraform {{command}}