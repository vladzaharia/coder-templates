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
init template=DEFAULT: (_run template 'init')

# Validate Terraform template(s) and common modules
validate template=DEFAULT: (init template) && (_run template 'validate')

# Plan Terraform template(s)
plan template=DEFAULT: (init template) && (_run_nc template 'plan')

# Format Terraform template(s) and common modules
format template=DEFAULT: (_run template 'fmt')

# Upgrade Terraform template(s) and common modules
upgrade template=DEFAULT: (_run template 'init -upgrade')

# Run Terraform command on template(s) and common modules
terraform command template=DEFAULT *FLAGS='':
    #!/bin/bash
    if [[ '{{FLAGS}}' == *'-nc'* ]]; then
        just _run_nc '{{template}}' '{{replace(command, '-nc', '')}} {{FLAGS}}'
    else
        just _run '{{template}}' '{{replace(command, '-nc', '')}} {{FLAGS}}'
    fi

# Deploy Coder template(s)
deploy template=DEFAULT: (plan template) (ln-modules template)
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Deploying all templates...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './_modules/*' -not -path './.*/*' -not -name 'build' -not -name '_modules' -printf '%f '`; do 
    		just _log '{{ INFO }}' "Deploying template {{ GREY }}$folder{{ NORMAL }}..."
    		if ! (coder templates push "$folder" --directory "./$folder" --yes --name="$CODER_TEMPLATE_VERSION" --message="$CODER_TEMPLATE_MESSAGE" --variable vault_role_id="$VAULT_ROLE_ID" --variable vault_secret_id="$VAULT_SECRET_ID"); then
                just _log '{{ ERR }}' "Failed deploying template {{ GREY }}$folder{{ NORMAL }}!"
            fi
    	done
    else
    	just _log '{{ INFO }}' 'Deploying template {{ GREY }}{{ template }}{{ NORMAL }}...'
        if ! (coder templates push "{{ template }}" --directory "./{{ template }}" --yes --name="$CODER_TEMPLATE_VERSION" --message="$CODER_TEMPLATE_MESSAGE" --variable vault_role_id="$VAULT_ROLE_ID" --variable vault_secret_id="$VAULT_SECRET_ID"); then
            just _log '{{ ERR }}' "Failed deploying template {{ GREY }}$folder{{ NORMAL }}!"
        fi
    fi
    just _log '{{ SUCCESS }}' "Successfully deployed template(s)!"

ln-modules template=DEFAULT: (clean-modules template)
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Setting up all templates...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './_modules/*' -not -path './.*/*' -not -name 'build' -not -name '_modules' -printf '%f '`; do 
    		just _log '{{ INFO }}' "Setting up template {{ GREY }}$folder{{ NORMAL }}..."
            cd "./$folder"
            ln -s -T ../_modules ./_modules
            cd ../
    	done
    else
    	just _log '{{ INFO }}' 'Setting up template {{ GREY }}{{ template }}{{ NORMAL }}...'
        cd {{ template }}
        ln -s -T ../_modules ./_modules
        cd ../
    fi
    just _log '{{ SUCCESS }}' "Successfully set up template(s)!"

clean-modules template=DEFAULT: 
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Cleaning up all templates...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './_modules/*' -not -path './.*/*' -not -name 'build' -not -name '_modules' -printf '%f '`; do 
    		just _log '{{ INFO }}' "Cleaning up template modules {{ GREY }}$folder{{ NORMAL }}..."
            cd "./$folder"
            rm -rf ./_modules
            cd ../
    	done
    else
    	just _log '{{ INFO }}' 'Cleaning up template modules {{ GREY }}{{ template }}{{ NORMAL }}...'
        cd {{ template }}
        rm -rf ./_modules
        cd ../
    fi
    just _log '{{ SUCCESS }}' "Successfully cleaned up template(s)!"


# Run a command across Terraform templates and common modules
_run template command:
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Running {{ GREY }}{{ command }}{{ NORMAL }} on all templates and modules...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './.*/*' -not -name 'build' -not -name '_modules'`; do just _run-one $folder '{{ command }}'; done
    else
    	just _run-one '{{ template }}' '{{ command }}'
    fi
    just _log '{{ SUCCESS }}' 'Succesffully ran {{ GREY }}{{ command }}{{ NORMAL }} on templates and modules!'

# Run a command across Terraform templates
_run_nc template command:
    #!/bin/sh
    if [ '{{ template }}' = '{{ DEFAULT }}' ]; then
    	just _log '{{ INFO }}' 'Running {{ GREY }}{{ command }}{{ NORMAL }} on all templates...'
    	for folder in `find . -maxdepth 2 -mindepth 1 -type d -not -name '.*' -not -path './.*/*' -not -name 'build' -not -name '_modules' -not -path './_modules/*'`; do just _run-one $folder '{{ command }}'; done
    else
    	just _run-one '{{ template }}' '{{ command }}'
    fi
    just _log '{{ SUCCESS }}' 'Succesffully ran {{ GREY }}{{ command }}{{ NORMAL }} on templates!'

# Run a command on a single folder
_run-one folder command: (_log INFO "Running " + GREY + "terraform " + command + NORMAL + " in " + BLACK + folder + NORMAL)
    @cd {{ folder }} && terraform {{ command }}

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
