ARG IMAGE
FROM ${IMAGE}

# Install base dependencies
RUN apt-get update \
	&& apt-get install -y \
	curl \
	direnv \
	git \
	gpg \
	golang \
	jq \
	lsb-release \
	make \
	screen \
	sudo \
	vim \
	wget \
	zsh

# Install Starship
RUN curl -O https://starship.rs/install.sh && chmod +x install.sh && ./install.sh -y && rm -rf install.sh

# Install just
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Install Nodejs for Claude Code
RUN (curl -fsSL https://deb.nodesource.com/setup_23.x | sh) && apt-get install -y nodejs;

# Install Docker Engine
ARG ENABLE_DIND=false
RUN if [ "${ENABLE_DIND}" = "true" ]; then \
	curl -fsSL https://get.docker.com | sh; \
fi

# Install Hashicorp repository
RUN wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

RUN apt-get update \
	&& apt-get install -y \
	terraform \
	vault

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Clean up apt
RUN rm -rf /var/lib/apt/lists/*

# Add user
ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/zsh ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}
USER ${USER}
WORKDIR /home/${USER}

# pre-install VS Code extensions
RUN code-server --install-extension eamodio.gitlens 
