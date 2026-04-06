# ── Dobby MuleSoft Elf — Docker Image ──────────────────────────────────────
# Base: node:20-slim gives us Node + npm for the Claude Code CLI.
# Python 3 is added via apt for dobby_server.py.
FROM node:20-slim

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        bash \
        git \
        jq \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create a non-root user so the Claude CLI and files aren't owned by root
RUN useradd -m -s /bin/bash dobby
USER dobby
WORKDIR /home/dobby/app

# Copy application files (owned by dobby)
COPY --chown=dobby:dobby \
    dobby_server.py \
    dobby_loop.sh \
    dobby_banner.sh \
    dobby_setup.sh \
    dobby_monitor.sh \
    ./

COPY --chown=dobby:dobby ui/        ./ui/
COPY --chown=dobby:dobby templates/ ./templates/

RUN chmod +x dobby_loop.sh dobby_banner.sh dobby_setup.sh dobby_monitor.sh

# Workspace volume — mount your MuleSoft project here
VOLUME ["/workspace"]

# Web UI port
EXPOSE 3131

# Bind to 0.0.0.0 inside the container so the mapped host port works.
# The host-side binding stays on 127.0.0.1 via docker-compose port mapping.
ENTRYPOINT ["python3", "dobby_server.py", "3131", "--host", "0.0.0.0"]
