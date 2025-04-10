FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Python 3.13
RUN apt-get update && \
    apt-get install -y software-properties-common curl && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.13 python3.13-dev python3.13-venv python3-pip && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.13 1 && \
    ln -sf /usr/bin/python3.13 /usr/bin/python

# Install Poetry
ENV POETRY_VERSION=1.8.2
RUN curl -sSL https://install.python-poetry.org | python && \
    ln -s /home/vscode/.local/bin/poetry /usr/local/bin/poetry
