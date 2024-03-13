import json
import sys

def convert_input_to_output(input_file, output_file):
    with open(input_file, 'r') as f:
        data = json.load(f)

    sim_network = []

    for edge in data['edges']:
        node1_pub = edge['node1_pub']
        node2_pub = edge['node2_pub']
        capacity_msat = int(edge['capacity'])

        node1_policy = edge['node1_policy']
        node2_policy = edge['node2_policy']

        node_1 = {
            "pubkey": node1_pub,
            "max_htlc_count": 483,
            "max_in_flight_msat": capacity_msat,
            "min_htlc_size_msat": 1,
            "max_htlc_size_msat": capacity_msat,
            "cltv_expiry_delta": node1_policy['time_lock_delta'],
            "base_fee": int(node1_policy['fee_base_msat']),
            "fee_rate_prop": int(node1_policy['fee_rate_milli_msat'])
        }

        node_2 = {
            "pubkey": node2_pub,
            "max_htlc_count": 483,
            "max_in_flight_msat": capacity_msat,
            "min_htlc_size_msat": 1,
            "max_htlc_size_msat": capacity_msat,
            "cltv_expiry_delta": node2_policy['time_lock_delta'],
            "base_fee": int(node2_policy['fee_base_msat']),
            "fee_rate_prop": int(node2_policy['fee_rate_milli_msat'])
        }

        scid = len(sim_network) + 1

        sim_network.append({
            "scid": scid,
            "capacity_msat": capacity_msat,
            "node_1": node_1,
            "node_2": node_2
        })

    output_data = {"sim_network": sim_network}

    with open(output_file, 'w') as f:
        json.dump(output_data, f, indent=2)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py input_file.json")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = "sim_graph.json"  # Assuming the output file name

    convert_input_to_output(input_file, output_file)
