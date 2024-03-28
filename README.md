# Attackathon

![image info](hackerman.jpg)

## Task 

In this attackathon, your task will be to write a program that performs 
a [channel jamming attack](https://bitcoinops.org/en/topics/channel-jamming-attacks/) 
against a test lightning network. You will be required to write a 
program that performs a jamming attack against a node in the test 
network. 

Your goal is to **completely jam all of the node's channels for an hour.**

Your program should: 
- Accept the public key of the node being attacked as a parameter. 
- Write an attack against the [hybrid approach to jamming mitigations](https://research.chaincode.com/2022/11/15/unjamming-lightning/)
  which is deployed on the network.
- Open any channels required to perform the attack, and close them 
  when the attack has competed.

The final deliverable for the attackathon is a [docker image](TODO) 
that downloads, installs and runs your attack.

## Network

The attack you develop will be tested against a [warnet](https://warnet.dev/)
running a network of LND nodes that have the jamming attack mitigation 
implemented* (via an external tool called circuitbreaker).

Some relevant characteristics of the network: 
- The reputation system has been primed with historical forwarding 
  data, so nodes in the network have already had a chance to build 
  up reputation before the attack begins.
- The graph was obtained by reducing the mainnet graph using a 
  random walk around our target node, and real-world routing policies 
  are used.
- When you run the attack, the non-malicious nodes in the network will 
  be executing [randomly generated payments](https://simln.dev) to 
  mimic an active network.

The LND nodes on the network are running a [fork of LND](https://github.com/carlaKC/lnd/tree/7883-experimental-endorsement)
which supports setting of `endorsement` signals for payments.

Some APIS to note:
- [AddHoldInvoice](https://lightning.engineering/api-docs/api/lnd/invoices/add-hold-invoice)
  creates an invoice that can be manually [settled](https://lightning.engineering/api-docs/api/lnd/invoices/settle-invoice) 
  or [canceled](https://lightning.engineering/api-docs/api/lnd/invoices/cancel-invoice)
- Endorsement signals can be set on the [SendToRoute](https://lightning.engineering/api-docs/api/lnd/router/send-to-route-v2)
  or [SendPayment](https://lightning.engineering/api-docs/api/lnd/router/send-payment-v2)
  APIs.

\* Note that endorsement signaling and reputation tracking are fully 
deployed on the test network, but unconditional fees are not. You should
assume that they will be 1% of your success-case fees, and we will 
account for them during attack analysis.

### Local Development

To assist with local development, we've provided a test network that 
can be used to run your attacks against. Prerequisites to set up this 
network are: 
* Python3
* Docker

Clone the attackathon repo:
`git clone https://github.com/carlaKC/attackathon`

*Do not change directory.*

The scripts will pull the relevant repositories to your current working
directory and set up your network. They expect the `attackathon` 
repository to be in the current directory.
* Warnet server: [./attackathon/scripts/run_warnet.sh](./scripts/run_warnet.sh) 
  sets up the warnet server, which is responsible for orchestration of 
  the network.
* Warnet cli: [./attackathon/scripts/run_attack.sh](/.scripts/start_network.sh)
  brings up your lightning network, opens channels and simulates 
  random payments in the network and runs your attack.

## Assessment

Attacks will be assessed using the following measures:
- Did the attacker successfully occupy the resources of the targeted 
  node such that it could not process honest payments?
- What was the total cost of the attack, considering:
  - On-chain fees: for channel opens and closes, sending funds between 
    nodes on-chain will node be included for simplicity's sake.
  - Off-chain fees: the sum of fees paid for successful off-chain 
    payments plus 1% of the success-case fees for *all* payments that 
    are sent to represent unconditional fees.
  - Opportunity cost of capital: for each channel that is opened, 5% 
    p.a. charged on the total capital deployed in the channels, 
    assuming 10 minute blocks.

### HackNicePlz

We're trying to break channel jamming mitigations, not our setup itself
so please be a good sport and let us know if there's anything buggy! 
Real attackers won't be able to take advantage of our test setup, so 
neither should we.


## Network Creation

Participants do not need to read the following section, it contains 
instructions on how to setup a warnet network to run the attackathon 
on.

<details>
 <summary>Setup Instructions</summary>

## Payment Bootstrap

To run a realistic attackathon, nodes in the network need to be 
bootstrapped with payment history to build up their reputation scores 
for honest nodes in the network. We're interested in bootstrapping 6 
months of data (as this is the duration we look at in the proposal), 
so we need to simulate and insert that data (rather than leave a warnet 
running for 6 months / try to mess with time).

The steps for payment bootstrapping are:
1. Select desired topology for attackathon
2. Run [SimLN](https://github.com/bitcoin-dev-project/sim-ln) in 
   `sim_network` mode to generate fake payment data for the network 
   with simulation time (not real time).
3. Convert simulation timestamps to real dates.
4. Run warnet with the same topology, and import data via 
   [Circuitbreaker](https://github.com/lightningequipment/circuitbreaker)

### 1. Choose Topology

SimLN requires a description of the desired topology to generate data. 
The [lnd_to_simln.py](./setup/lnd_to_simln.py) script can be used to 
convert the output of LND's `describegraph` command to a simulation 
file for SimLN. This utility is useful when simulating a reduced 
version of the mainnet graph, as you'll already have the data in this 
format.

To convert LND's graph (`graph.json`) to a `sim_graph.json` for SimLN:
`python setup/lnd_to_simln.py graph.json`

To prepare a SimLN file that can be used to generate data for warnet, 
the script will perform the following operations:
- Reformat the graph file to the input format that SimLN requires
- Replace short channel ids with deterministically generated short 
  channel ids: 
  - Block height = 300 + index of channel in json
  - Transaction index = 1
  - Output index = 0
- Set an alias for each node equal to their index in the list of 
  nodes provided in the original graph file.

The script will output a json file with the same name as the input file, 
with a `simln.json` suffix added in the current directory.

### 2. Run SimLN to Generate Data

Next, run SimLN with the generated simulation file setting the total 
time flag to the amount of time that you'd like to generate data for:
`sim-cli --sim-file={path to sim_graph.json} --total-time=1.577e+7`

When the simulator has finished generating data in its simulated 
network, the output will be available in `results/htlc_forwards.csv`.
This file contains a record of every forward that the network has 
processed during the period provided.

### 3. Convert Simulation Timestamps

For the attackathon, we want nodes to have _recent_ timestamps so that 
honest peers reputation is up to date. This means that we'll always 
need to progress the timestamps in `htlc_forwards.csv` to the present 
before running the attackathon warnet. Note that the payment activity 
can be pre-generated, but this "fast fowwarding" must be done at the 
time the warnet is spun up (or future dated to a known start time).

To progress the timestamps in your generated data such that the latest
timestamp reported by the simulation is set to the present (and all 
others are appropriately "fast-forwarded"), use the following command:

`python setup/progress_timestamps.py ln_10_raw_data.csv data/ln_10_data.csv`

This will write the csv file with the updated timestamps to 
`data/ln_10_data.csv`.

Note that you'll want to do this step every time for fresh data!

### 4. Create Warnet Topology

Once you've generated data for your network, and progressed your 
timestamps to the present, you'll want to create a warnet graphml 
file that specifies your topology.

`git clone https://github.com/bitcoin-dev-project/warnet`
`git checkout XYZ` <- we'll have a hackathon branch w/ stuff?

```
python3 -m venv .venv # Use alternative venv manager if desired
source .venv/bin/activate
pip install --upgrade pip
pip install -e .
```

If you run into problems, check the [installation instructions](https://github.com/bitcoin-dev-project/warnet/blob/main/docs/install.md)
as this doc may be outdated!

Warnet operates with a server and a cli, so you'll need to start the 
server: 
`warnet`

Once you've started the server, you can use its cli to generate a 
graph file for the graph you've chosen and the data you've prepared:

`warcli network import-json {graph.json} --cb_data={ln_10_data.csv} --outfile={dest}`

### 5. Run warnet

Finally, you can use the file generated in the previous step to bring 
up your warnet:
`warcli network up {dest} --force`

Next, to setup the lightning channels in your network:
`warcli scenario run ln_init'

This may take a while, because it opens up one channel per block and 
waits for gossip to be fully synced. You *must* wait for this to 
complete before proceeding to the next step!

TODO: removeme once sim-ln is natively added!
`git clone https://github.com/bitcoin-dev-project/sim-ln`
`cargo install --locked --path sim-cli`

`warcli network export` -> {warnet path}
`sim-cli --sim-file {warnet path}/sim.json`

</details>
