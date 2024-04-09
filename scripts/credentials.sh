#!/bin/bash

tmp_dir=$(mktemp -d)
echo $tmp_dir
kubectl cp warnet-armada/lnd0:root/.lnd/tls.cert $tmp_dir/lnd0-tls.cert
kubectl cp warnet-armada/lnd1:root/.lnd/tls.cert $tmp_dir/lnd1-tls.cert
kubectl cp warnet-armada/lnd2:root/.lnd/tls.cert $tmp_dir/lnd2-tls.cert
kubectl cp warnet-armada/lnd0:root/.lnd/data/chain/bitcoin/regtest/admin.macaroon $tmp_dir/lnd0-admin.macaroon
kubectl cp warnet-armada/lnd1:root/.lnd/data/chain/bitcoin/regtest/admin.macaroon $tmp_dir/lnd1-admin.macaroon
kubectl cp warnet-armada/lnd2:root/.lnd/data/chain/bitcoin/regtest/admin.macaroon $tmp_dir/lnd2-admin.macaroon

kubectl cp $tmp_dir warnet-armada/flagship:/credentials