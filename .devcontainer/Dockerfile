FROM mcr.microsoft.com/devcontainers/python:3.10

# Instalar ferramentas adicionais
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl \
    git \
    zsh \
    vim \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Configurar ZSH como shell padrão
RUN chsh -s $(which zsh)

# Instalar poesia para gerenciamento de dependências Python
RUN curl -sSL https://install.python-poetry.org | python3 -

# Copiar arquivos de configuração
COPY requirements.txt /tmp/pip-tmp/
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
    && rm -rf /tmp/pip-tmp