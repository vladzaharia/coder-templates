set dotenv-load := true

alias v := validate
alias p := plan
alias build := plan
alias f := format
alias fmt := format
alias u := upgrade
alias up := upgrade

# Default template value
DEFAULT := '__DEFAULT__'

# Log levels
INFO := '__INFO__'
WARN := '__WARN__'
ERR := '__ERR__'
SUCCESS := '__SUCCESS__'

# Terminal colors and reset
GREY := '\033[1;90m'

[private]
default:
    @just --choose

# Initialize Terraform template(s) and download packages
init template=DEFAULT: (_ln-modules template) (_run template 'terraform init')

# Validate Terraform template(s) and common modules
validate template=DEFAULT: (init template) && (_run template 'terraform validate')

# Plan Terraform template(s)
plan template=DEFAULT: (init template) && (_run-no-modules template 'terraform plan')

# Format Terraform template(s) and common modules
format template=DEFAULT: (_run template 'terraform fmt')

# Upgrade Terraform template(s) and common modules
upgrade template=DEFAULT: (_run template 'terraform init -upgrade')

# Run Terraform command on template(s) and common modules
terraform command template=DEFAULT *FLAGS='':
    #!/bin/bash
    if [[ '{{FLAGS}}' == *'-nc'* ]]; then
        just _run-no-modules '{{template}}' '{{replace(command, '-nc', '')}} {{FLAGS}}'
    else
        just _run '{{template}}' '{{replace(command, '-nc', '')}} {{FLAGS}}'
    fi

# Deploy Coder template(s)
deploy template=DEFAULT: (_cp-modules template)
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Deploying all templates...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './_*/*' -not -path './.*/*' -not -name 'build' -not -name '_modules' -not -name '_deprecated' -printf '%f '`; do 
    		just _log '{{ INFO }}' "Deploying template {{ GREY }}$folder{{ NORMAL }}..."
    		if ! (coder templates push "$folder" --directory "./$folder" --yes --name="$CODER_TEMPLATE_VERSION" --message="$CODER_TEMPLATE_MESSAGE" --variable vault_role_id="$VAULT_ROLE_ID" --variable vault_secret_id="$VAULT_SECRET_ID"); then
                just _log '{{ ERR }}' "Failed deploying template {{ GREY }}$folder{{ NORMAL }}!"
                exit 1
            fi
    	done
    else
    	just _log '{{ INFO }}' 'Deploying template {{ GREY }}{{ template }}{{ NORMAL }}...'
        if ! (coder templates push "{{ template }}" --directory "./{{ template }}" --yes --name="$CODER_TEMPLATE_VERSION" --message="$CODER_TEMPLATE_MESSAGE" --variable vault_role_id="$VAULT_ROLE_ID" --variable vault_secret_id="$VAULT_SECRET_ID"); then
            just _log '{{ ERR }}' "Failed deploying template {{ GREY }}$folder{{ NORMAL }}!"
            exit 1
        fi
    fi
    just _log '{{ SUCCESS }}' "Successfully deployed template(s)!"


# Setup modules in template(s) using `ln -s`
[private]
_ln-modules template=DEFAULT: (_rm-modules template) (_run-no-modules template 'ln -s -T ../_modules ./_modules') (_run-no-modules template 'ln -s -T ../_modules/docker/build ./build')

# Setup modules in template(s) using `cp -R`
[private]
_cp-modules template=DEFAULT: (_rm-modules template) (_run-no-modules template 'cp -R ../_modules ./_modules') (_run-no-modules template 'cp -R ../_modules/docker/build ./build')

# Clean up per-template modules
[private]
_rm-modules template=DEFAULT: (_run-no-modules template 'rm -rf ./_modules ./build')

# Run a command across Terraform templates and common modules
_run template command:
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Running {{ GREY }}{{ command }}{{ NORMAL }} on all templates and modules...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './.*/*' -not -name 'build' -not -name '_modules' -not -name '_deprecated'`; do if ! (just _run-one $folder '{{ command }}'); then exit 1; fi; done
    else
    	if ! (just _run-one '{{ template }}' '{{ command }}'); then exit 1; fi
    fi
    just _log '{{ SUCCESS }}' 'Succesffully ran {{ GREY }}{{ command }}{{ NORMAL }} on templates and modules!'

# Run a command across Terraform templates
_run-no-modules template command:
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Running {{ GREY }}{{ command }}{{ NORMAL }} on all templates...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './.*/*' -not -name 'build' -not -name '_modules' -not -path './_*/*' -not -name '_deprecated'`; do if ! (just _run-one $folder '{{ command }}'); then exit 1; fi; done
    else
    	if ! (just _run-one '{{ template }}' '{{ command }}'); then exit 1; fi
    fi
    just _log '{{ SUCCESS }}' 'Succesffully ran {{ GREY }}{{ command }}{{ NORMAL }} on templates!'

# Run a command on a single folder
_run-one folder command: (_log INFO "Running " + GREY + command + NORMAL + " in " + GREY + folder + NORMAL)
    @cd {{ folder }} && {{ command }}

# Log to console
_log level message:
    #!/bin/sh
    if [ '{{ level }}' = '{{ INFO }}' ]; then
    	LEVEL='{{ BLUE }} [i]{{ NORMAL }}'
    elif [ '{{ level }}' = '{{ WARN }}' ]; then
    	LEVEL='{{ YELLOW }} [!]{{ NORMAL }}'
    elif [ '{{ level }}' = '{{ ERR }}' ]; then
    	LEVEL='{{ RED }} [✕]{{ NORMAL }}'
    elif [ '{{ level }}' = '{{ SUCCESS }}' ]; then
    	LEVEL='{{ GREEN }} [✓]{{ NORMAL }}'
    else
    	LEVEL='{{ GREY }} [?]{{ NORMAL }}'
    fi

    echo "$LEVEL {{ message }}"
