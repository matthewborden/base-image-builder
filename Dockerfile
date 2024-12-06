FROM docker.io/buildkite/hosted-agent-base:ubuntu-v1.0.1@sha256:f1378abd34fccb2b7b661aaf3b06394509a4f7b5bb8c2f8ad431e7eaa1cabc9c

# Add the GitHub CLI package repository and install `gh`
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Verify `gh` installation
RUN gh --version

# Authenticate using a token passed as a secret
RUN --mount=type=secret,id=github_token \
    gh auth login --with-token < /run/secrets/github_token
RUN echo /run/secrets/github_token | gh auth login --with-token

# Clone a GitHub repository or download specific assets
ARG REPO="matthewborden/test"
ARG RELEASE_ASSET="cache"
RUN gh release download --repo $REPO --pattern $RELEASE_ASSET && \
    unzip $RELEASE_ASSET -d /usr/local/bin && \
    chmod +x /usr/local/bin/cache

# Set default command (adjust based on the downloaded CLI or your requirements)
CMD ["cache", "--help"]

ENTRYPOINT ["./cache"]