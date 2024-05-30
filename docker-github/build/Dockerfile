ARG IMAGE
FROM ${IMAGE}

# Install MPR repository
RUN wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
RUN echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list

# Install Hashicorp repository
RUN wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install base dependencies
RUN apt-get update \
	&& apt-get install -y \
	curl \
	direnv \
	git \
	gpg \
	golang \
	jq \
	just \
	lsb-release \
	make \
	sudo \
	terraform \
	vault \
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

# Clean up apt
RUN rm -rf /var/lib/apt/lists/*

# Add user
ARG USER=coder
RUN useradd --groups sudo --no-create-home --shell /bin/zsh ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER}
USER ${USER}
WORKDIR /home/${USER}
