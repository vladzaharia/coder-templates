ARG IMAGE
FROM ${IMAGE}

# Install base dependencies
RUN apt-get update \
	&& apt-get install -y \
	curl \
	direnv \
	git \
	golang \
	jq \
	sudo \
	vim \
	wget \
	zsh

# Install Starship
RUN curl -O https://starship.rs/install.sh && chmod +x install.sh && ./install.sh -y && rm -rf install.sh

# Install Docker Engine
ARG ENABLE_DIND=false
RUN if [ "${ENABLE_DIND}" = "true" ]; then \
	curl -fsSL https://get.docker.com | sh; \
fi

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | \
	gpg --dearmor | \
	sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
	https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
	sudo tee /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install -y terraform 

# Clean up apt
RUN rm -rf /var/lib/apt/lists/*

# Add user
ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/zsh ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}
USER ${USER}
WORKDIR /home/${USER}
