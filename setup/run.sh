#!/bin/bash

# Check if the 'credentials' directory does not exist
if [ ! -d "credentials" ]; then
    echo "LND credentials not found in image"
	exit 1
fi

# These are the paths to the certs/macaroons you'll need to talk to LND.
lnd_0_rpcserver="lightning-0.warnet-armada"
lnd_0_cert="/credentials/lnd0-tls.cert"
lnd_0_macaroon="/credentials/lnd0-admin.macaroon"

lnd_1_rpcserver="lightning-1.warnet-armada"
lnd_1_cert="/credentials/lnd1-tls.cert"
lnd_1_macaroon="/credentials/lnd1-admin.macaroon"

lnd_2_rpcserver="lightning-2.warnet-armada"
lnd_2_cert="/credentials/lnd2-tls.cert"
lnd_2_macaroon="/credentials/lnd2-admin.macaroon"

# Fill in code here to:
# - Clone your repo
# - Install your program
# - Run it with the certs/macaroons provided above
