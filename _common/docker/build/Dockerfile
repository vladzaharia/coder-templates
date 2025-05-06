ARG IMAGE
FROM ${IMAGE}

# Install base dependencies
RUN apt-get update \
	&& apt-get install -y \
	curl \
	direnv \
	fzf \
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

ARG DE=xfce
RUN if [ "${DE}" = "xfce" ]; then \
	apt-get install -y --no-install-recommends --no-install-suggests dbus-x11 libdatetime-perl openssl ssl-cert xfce4 xfce4-goodies; \
fi

# Install Starship
RUN curl -O https://starship.rs/install.sh && chmod +x install.sh && ./install.sh -y && rm -rf install.sh

# Install just
RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Install Nodejs for Claude Code
RUN (curl -fsSL https://deb.nodesource.com/setup_23.x | sh) && apt-get install -y nodejs && chmod -R 777 /usr/bin /usr/lib/node_modules

# Install Docker Engine
RUN curl -fsSL https://get.docker.com | sh

# Install Hashicorp repository
RUN wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

RUN apt-get update \
	&& apt-get install -y \
	terraform \
	vault

# Install code-server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Clean up
RUN (rm -rf /run/reboot-required* /var/lib/apt/lists/*) || true

# Add user
ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/zsh ${USER}; \
	echo '${USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${USER}; \
	echo 'LANG=en_US.UTF-8' >> /etc/default/locale; \
	echo 'export GNOME_SHELL_SESSION_MODE=ubuntu' > /home/${USER}/.xsessionrc; \
	echo 'export XDG_CURRENT_DESKTOP=${DE}' >> /home/${USER}/.xsessionrc; \
	echo 'export XDG_SESSION_TYPE=x11' >> /home/${USER}/.xsessionrc;

USER ${USER}
WORKDIR /home/${USER}

# pre-install VS Code extensions
RUN code-server --install-extension eamodio.gitlens
RUN code-server --install-extension ms-azuretools.vscode-containers
RUN code-server --install-extension github.vscode-github-actions
RUN code-server --install-extension BeardedBear.beardedtheme
RUN code-server --install-extension EditorConfig.EditorConfig
RUN code-server --install-extension skellock.just
RUN code-server --install-extension esbenp.prettier-vscode
