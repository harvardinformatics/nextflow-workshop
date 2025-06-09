#──────────────────────────────────────────────────────────────────────────────
# 1) Base image & non-interactive APT
#──────────────────────────────────────────────────────────────────────────────
FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

#──────────────────────────────────────────────────────────────────────────────
# 2) Install system deps
#──────────────────────────────────────────────────────────────────────────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      sudo \
      python3 \
      python3-pip \
      python3-dev \
      build-essential \
      dos2unix \
      zip \
      unzip \
      less nano vim-tiny man-db manpages \
      wget openssh-client net-tools htop tree \
      lsof strace mlocate tmux screen \
      bzip2 xz-utils \
      locales \
 && sed -i 's/# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

#──────────────────────────────────────────────────────────────────────────────
# 3) Create non-root vscode user
#──────────────────────────────────────────────────────────────────────────────
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

RUN groupadd --gid $USER_GID $USERNAME \
 && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
 && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" \
     > /etc/sudoers.d/$USERNAME \
 && chmod 0440 /etc/sudoers.d/$USERNAME

#──────────────────────────────────────────────────────────────────────────────
# 4) Switch to vscode and install SDKMAN + Java 17.0.10-tem
#──────────────────────────────────────────────────────────────────────────────
USER $USERNAME
ENV SDKMAN_DIR=/home/${USERNAME}/.sdkman
ENV PATH=${SDKMAN_DIR}/candidates/java/current/bin:${PATH}

RUN curl -s https://get.sdkman.io | bash \
 && bash -lc "source ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install java 17.0.10-tem" \
 && echo 'export SDKMAN_DIR="$HOME/.sdkman"'    >> /home/${USERNAME}/.bashrc \
 && echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' \
      >> /home/${USERNAME}/.bashrc

# quick sanity check (optional):
RUN bash -lc "java -version"

#──────────────────────────────────────────────────────────────────────────────
# 5) Switch back to root to install Nextflow & Python tools
#──────────────────────────────────────────────────────────────────────────────
USER root

# 5a) Nextflow installer (guarantees proper #!/usr/bin/env bash)
RUN curl -fsSL https://get.nextflow.io | bash \
 && mv nextflow /usr/local/bin/nextflow \
 && chmod +x /usr/local/bin/nextflow \
 && dos2unix /usr/local/bin/nextflow

# 5b) nf-core, MkDocs + Material theme
RUN pip3 install --no-cache-dir \
      nf-core \
      mkdocs \
      mkdocs-material

#──────────────────────────────────────────────────────────────────────────────
# 6) Final defaults
#──────────────────────────────────────────────────────────────────────────────
USER $USERNAME
WORKDIR /home/${USERNAME}/workspace
EXPOSE 8000
ENTRYPOINT [ "bash" ]