#!/bin/bash

if [ ! -d "attackathon" ]; then
    echo "Error: attackathon repo not found, script should be run from directory containing it."
    exit 1
fi

echo "Adding attacking nodes to cluster"
kubectl apply -f attackathon/setup/armada.yaml

while true; do
    # Get the status of pods in the namespace
    pod_status=$(kubectl get pods -n warnet-armada --no-headers)

    # Check if all pods are ready
    if [[ $(echo "$pod_status" | grep -c -E '\s[0-9]+\/[0-9]+\s+Running\s+') -eq $(echo "$pod_status" | wc -l) ]]; then
        echo "All pods are ready."
        break
    else
        echo "Waiting for attacking nodes to be ready"
        sleep 1
    fi
done
