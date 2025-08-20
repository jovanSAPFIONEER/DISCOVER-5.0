# Simple Dockerfile to reproduce the rewire pipeline non-interactively
FROM python:3.10-slim

# System deps (git, build tools)
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

# Create app dir
WORKDIR /app

# Clone upstream
RUN git clone https://github.com/jovanSAPFIONEER/Orion orion_src

# Install deps
RUN python -m pip install --upgrade pip && \
    python -m pip install -r orion_src/requirements.txt

# Copy helper scripts
COPY scripts/bootstrap_repro.sh /app/bootstrap_repro.sh
RUN chmod +x /app/bootstrap_repro.sh

# Default command runs the full pipeline and leaves outputs in /app/orion_src/runs and /app/outputs
CMD ["/bin/bash", "/app/bootstrap_repro.sh"]
