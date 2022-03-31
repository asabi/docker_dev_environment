FROM gitpod/openvscode-server:latest

USER root
RUN apt-get update -y
RUN apt-get install curl build-essential git net-tools nano sudo wget ssh unzip -y

USER openvscode-server
#RUN mkdir -p /home/workspace

# Set up serverless
RUN mkdir -p /home/workspace/nvm
ENV NVM_DIR /home/workspace/nvm
ENV NODE_VERSION 14.8.0

RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.39.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install v$NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default
    
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH      $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
RUN npm i -g serverless

RUN echo "alias ll='ls -alF'" >> /home/workspace/.profile
# Set up AWS VAULT
RUN arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="amd64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="arm64"; \
    fi && \
    sudo curl -L -o /usr/local/bin/aws-vault https://github.com/99designs/aws-vault/releases/download/v6.2.0/aws-vault-linux-${arch} && \
    sudo chmod +x /usr/local/bin/aws-vault && \
    echo 'export AWS_VAULT_BACKEND=file' >> /home/workspace/.profile && \
    mkdir -p /home/workspace/.aws && \
    echo '[default]' >> /home/workspace/.aws/credentials

# Install AWS cli
RUN arch=$(uname -m) && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -Rf awscliv2.zip  && \
    rm -Rf aws/

# Install Ruby
COPY debug /usr/local/bin/debug
RUN sudo chmod +x /usr/local/bin/debug

RUN sudo apt-get remove ruby -y && \
    curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash - && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    sudo apt-get install -y git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn && \
    git clone https://github.com/rbenv/rbenv.git /home/workspace/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/workspace/.profile && \
    echo 'eval "$(rbenv init -)"' >> /home/workspace/.profile && \
    exec $SHELL  && \
    git clone https://github.com/rbenv/ruby-build.git /home/workspace/.rbenv/plugins/ruby-build && \
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> /home/workspace/.profile && \
    exec $SHELL
RUN /home/workspace/.rbenv/bin/rbenv install 2.7.4 && \
    /home/workspace/.rbenv/bin/rbenv global 2.7.4 && \
    /home/workspace/.rbenv/shims/gem install ruby-debug-ide && \
    /home/workspace/.rbenv/shims/gem install debase && \
    /home/workspace/.rbenv/shims/gem install rubocop && \
    /home/workspace/.rbenv/shims/gem install solargraph

# Install python
USER root
ENV TZ=America/Vancouver
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
USER openvscode-server
RUN sudo apt-get install -y make build-essential zlib1g-dev libbz2-dev \
    python3-dev python3-setuptools python3-wheel \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev libssl-dev && \
    curl https://pyenv.run | bash && \
    echo 'alias pip=pip3' >> /home/workspace/.profile && \
    echo 'export PATH="/home/workspace/.pyenv/bin:$PATH"' >>/home/workspace/.profile && \
    echo 'export PATH="/home/workspace/.pyenv/shims:$PATH"' >>/home/workspace/.profile && \
    echo 'export PATH="/usr/local/bin:${PATH}"' >> /home/workspace/.profile && \
    echo 'eval "$(pyenv init -)"' >>/home/workspace/.profile && \
    echo 'eval "$(pyenv virtualenv-init -)"' >>/home/workspace/.profile && \
    . /home/workspace/.profile && \
    sudo ldconfig && \
    #CONFIGURE_OPTS=--enable-shared /home/workspace/.pyenv/bin/pyenv install 3.7.9 && \
    /home/workspace/.pyenv/bin/pyenv install 3.8.12 && \
    /home/workspace/.pyenv/bin/pyenv global 3.8.12
RUN /home/workspace/.pyenv/shims/pip install pipenv && \
    mkdir -p /home/workspace/venv && \
    echo 'export WORKON_HOME=/home/workspace/venv' >> /home/workspace/.profile && \
    /home/workspace/.pyenv/shims/pip install -U pipenv
RUN sudo ln -s /home/workspace/.pyenv/shims/pipenv /usr/local/bin/pipenv

# Install docker
RUN sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release -y && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="amd64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="arm64"; \
    elif [ "${arch}" = "armv7l" ]; then \
        arch="armhf"; \
    fi && \
    echo "deb [arch=${arch} signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null &&\
    sudo apt-get update && \
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y && \
    sudo usermod -a -G docker openvscode-server && \
    echo 'alias docker="sudo chmod 777 /var/run/docker.sock && docker"' >> /home/workspace/.profile
    
# Prompt
RUN echo "PS1='\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /home/workspace/.profile 

# aws-creds
USER root
RUN arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="amd64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="arm64"; \
    fi && \
    
    wget https://github.com/sabi-ai/aws-creds/releases/download/V1.0/aws-creds-${arch}.tar.gz && \
    tar -xzf aws-creds-${arch}.tar.gz && \
    mv -f aws-creds /usr/local/bin && \
    rm -f aws-creds-${arch}.tar.gz
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN chmod +x /usr/local/bin/aws-creds
USER openvscode-server

# Add Initial Setup script
COPY vscode_settings.json /home/workspace/.openvscode-server/data/Machine/settings.json
COPY extras /home/workspace/src/extras
RUN sudo chown -R openvscode-server:openvscode-server /home/workspace/src/extras/ && \
    sudo chmod +x /home/workspace/src/extras/clone && \
    sudo chmod +x /home/workspace/src/extras/setup && \
    sudo chmod +x /home/workspace/src/extras/tunnel.off && \
    sudo chmod +x /home/workspace/src/extras/tunnel.on    
RUN echo 'export PATH="/home/workspace/src/extras:$PATH"' >>/home/workspace/.profile
RUN sudo chown -R openvscode-server:openvscode-server /home/workspace/.openvscode-server
RUN echo 'export PATH="${OPENVSCODE_SERVER_ROOT}/bin:$PATH"' >> /home/workspace/.profile

ARG name
ARG email
ARG code_location=/home/workspace/src
ARG sls_key

RUN mkdir -p $code_location && \
    sudo chown -R openvscode-server:openvscode-server $code_location && \
    echo "export SERVERLESS_ACCESS_KEY=$sls_key" >>/home/workspace/.profile

# Set up GIT 
COPY gitignore_global /home/workspace/.gitignore_global 
RUN mkdir /home/workspace/.ssh && \
    ssh-keyscan -t rsa github.com >> /home/workspace/.ssh/known_hosts
COPY git.pem /home/workspace/.ssh/git
COPY ssh_config /home/workspace/.ssh/config
RUN sudo chown openvscode-server:openvscode-server /home/workspace/.ssh/git && \
    sudo chown openvscode-server:openvscode-server /home/workspace/.ssh/config && \
    chmod 600 /home/workspace/.ssh/git && \
    chmod 600 /home/workspace/.ssh/config && \
    git config --global core.excludesfile /home/workspace/.gitignore_global && \
    git config --global user.name "$name" && \
    git config --global user.email "$email"
RUN ln -s /home/workspace/.ssh /home/openvscode-server/.ssh

    
WORKDIR $code_location
