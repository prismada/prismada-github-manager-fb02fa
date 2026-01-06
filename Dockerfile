FROM node:20-slim

# Install Chromium and dependencies for browser automation
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-sandbox \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    fonts-thai-tlwg \
    fonts-kacst \
    fonts-symbola \
    fonts-noto-color-emoji \
    git \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# ==========================================================================
# SECURITY RISK: GitHub MCP Server Binary
# ==========================================================================
# This binary grants GitHub API access. Permissions depend on the
# GITHUB_PERSONAL_ACCESS_TOKEN environment variable.
#
# MITIGATIONS:
# - Pinned to specific version (v0.27.0) - no supply chain attacks
# - Fine-grained PAT scoped to prismada org only
# - Monitor GitHub audit logs for unexpected API calls
# ==========================================================================
RUN apt-get update && apt-get install -y curl ca-certificates --no-install-recommends \
    && curl -fsSL -o /tmp/github-mcp-server.tar.gz \
       "https://github.com/github/github-mcp-server/releases/download/v0.27.0/github-mcp-server_Linux_x86_64.tar.gz" \
    && tar -xzf /tmp/github-mcp-server.tar.gz -C /usr/local/bin github-mcp-server \
    && chmod +x /usr/local/bin/github-mcp-server \
    && rm /tmp/github-mcp-server.tar.gz \
    && rm -rf /var/lib/apt/lists/*

# Set Chrome path for the agent
ENV CHROME_PATH=/usr/bin/chromium

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

RUN npm prune --omit=dev

# Symlink binary MCPs to /app for stdio access
RUN ln -s /usr/local/bin/github-mcp-server /app/github-mcp-server

EXPOSE 3002

CMD ["node", "dist/server.js"]
