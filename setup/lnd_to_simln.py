import json
import sys

def convert_to_sim_network(input_file, output_file):
    with open(input_file, 'r') as f:
        data = json.load(f)

    sim_network = []

    for edge in data['edges']:
        node_1_policy = edge.get('node1_policy', None)
        node_2_policy = edge.get('node2_policy', None)

        if not node_1_policy or not node_2_policy:
            print(f"Warning: Skipping edge with channel ID {edge['channel_id']} because node1 or node2 policy is null.")
            continue

        max_htlc_size_msat_1 = int(node_1_policy['max_htlc_msat'])
        if max_htlc_size_msat_1 > int(edge['capacity']):
            max_htlc_size_msat_1 = int(edge['capacity'])

        max_htlc_size_msat_2 = int(node_2_policy['max_htlc_msat'])
        if max_htlc_size_msat_2 > int(edge['capacity']):
            max_htlc_size_msat_2 = int(edge['capacity'])

        node_1 = {
            "pubkey": edge['source'],
            "max_htlc_count": 483,
            "max_in_flight_msat": int(edge['capacity']),
            "min_htlc_size_msat": int(node_1_policy['min_htlc']),
            "max_htlc_size_msat": max_htlc_size_msat_1,
            "cltv_expiry_delta": int(node_1_policy['time_lock_delta']),
            "base_fee": int(node_1_policy['fee_base_msat']),
            "fee_rate_prop": int(node_1_policy['fee_rate_milli_msat'])
        }

        node_2 = {
            "pubkey": edge['target'],
            "max_htlc_count": 15,
            "max_in_flight_msat": int(edge['capacity']),
            "min_htlc_size_msat": int(node_2_policy['min_htlc']),
            "max_htlc_size_msat": max_htlc_size_msat_2,
            "cltv_expiry_delta": int(node_2_policy['time_lock_delta']),
            "base_fee": int(node_2_policy['fee_base_msat']),
            "fee_rate_prop": int(node_2_policy['fee_rate_milli_msat'])
        }

        scid = int(edge['channel_id'])

        sim_network.append({
            "scid": scid,
            "capacity_msat": int(edge['capacity']),
            "node_1": node_1,
            "node_2": node_2
        })

    output_data = {"sim_network": sim_network}

    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py input_file")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = input_file.split('.')[0] + '_simln.json'

    convert_to_sim_network(input_file, output_file)
