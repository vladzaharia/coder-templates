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
	zsh \
	&& rm -rf /var/lib/apt/lists/*

# Install Starship
RUN curl -O https://starship.rs/install.sh && chmod +x install.sh && ./install.sh -y && rm -rf install.sh

# Install Docker Engine
ARG ENABLE_DIND=false
RUN if [ "${ENABLE_DIND}" = "true" ]; then \
	curl -fsSL https://get.docker.com | sh; \
fi

# Add user
ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/zsh ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}
USER ${USER}
WORKDIR /home/${USER}
