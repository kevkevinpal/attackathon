# Use Ubuntu 24.04 as base image
FROM ubuntu:24.04

# Install required utilities
RUN apt-get update && apt-get install -y wget vim curl

# Download and install neovim
RUN apt-get install -y neovim

# Download Bitcoin Core
RUN wget https://bitcoincore.org/bin/bitcoin-core-26.1/bitcoin-26.1-aarch64-linux-gnu.tar.gz

# Extract Bitcoin Core
RUN tar -xvf bitcoin-26.1-aarch64-linux-gnu.tar.gz

# Move bitcoin-cli binary to /bin
RUN mv bitcoin-26.1/bin/bitcoin-cli /bin

# Clean up
RUN rm -rf bitcoin-26.1-aarch64-linux-gnu.tar.gz bitcoin-26.1

# Create bitcoin conf so that bitcoin-cli just works.
RUN mkdir -p ~/.bitcoin && \
    echo "rpcconnect=bitcoind.warnet-armada" >> ~/.bitcoin/bitcoin.conf && \
    echo "rpcuser=warnet_user" >> ~/.bitcoin/bitcoin.conf && \
    echo "rpcpassword=2themoon" >> ~/.bitcoin/bitcoin.conf && \
    echo "regtest=1" >> ~/.bitcoin/bitcoin.conf

# Download lncli binary from Lightning Labs GitHub
RUN wget https://github.com/lightningnetwork/lnd/releases/download/v0.17.4-beta/lnd-linux-arm64-v0.17.4-beta.tar.gz && \
    tar -xvf lnd-linux-arm64-v0.17.4-beta.tar.gz && \
    mv lnd-linux-arm64-v0.17.4-beta/lncli /bin && \
    rm -rf lnd-linux-arm64-v0.17.4-beta.tar.gz lnd-linux-arm64-v0.17.4-beta

# Copy in run script that is a placeholder for attacker code.
COPY run.sh /run.sh
RUN chmod +x run.sh

# Set entrypoint to just sleep indefinitely - attackers will run their own scripts.
ENTRYPOINT ["bash", "-c", "while true; do sleep 30; done;"]
