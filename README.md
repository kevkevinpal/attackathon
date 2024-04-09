# Attackathon

![image info](hackerman.jpg)

## Task 

In this attackathon, your task will be to write a program that performs
a [channel jamming attack](https://bitcoinops.org/en/topics/channel-jamming-attacks/) 
against a test lightning network. Your goal is to **completely jam a 
routing node for an hour.**

Your program should: 
- Accept the public key of the node being attacked as a parameter. 
- Write an attack against the [hybrid approach to jamming mitigations](https://research.chaincode.com/2022/11/15/unjamming-lightning/)
  which is deployed on the network.
- Open any channels required to perform the attack, and close them 
  when the attack has competed.

The final deliverable for the attackathon is a [run script](TODO) 
that downloads, installs and runs your attack in a kubernetes cluster.

## Jamming Definition

The conventional definition of a jamming attack classifies a node as 
jammed if for all of its channels: 

```
All of its local(/outbound) HTLC slots are occupied.
OR 
All of its local(/outbound) liquidity is occupied.
```

Given that we are operating within the context of a reputation system, 
we extend our definition of a node being "jammed" to consider the 
possibility that the attack may try to use the reputation system 
_itself_ to disrupt quality of service.

We therefore expand our definition of a jamming attack to account for 
this: 

```
All of its general bucket's local(/outbound) liquidity is occupied
AND 
All of its peers have low reputation
```

This expanded definition accounts for the case where an attacker has 
successfully sabotaged the reputation of all of a node's peers, so they 
no longer have access to the **protected bucket** which reserves 
resources for high reputation peers during an attack.

## Network

The attack you develop will be tested against a [warnet](https://warnet.dev/)
running a network of [LND](https://github.com/carlaKC/lnd/tree/7883-experimental-endorsement) 
nodes that have the jamming attack mitigation implemented* (via an 
external tool called circuitbreaker).

Some relevant characteristics of the network: 
- The reputation system has been primed with historical forwarding 
  data, so nodes in the network have already had a chance to build 
  up reputation before the attack begins.
- Each node in the network: 
  - Allows 483 HTLCs in flight per channel.
  - Allows 45% of its channel's capacity in flight.
  - Allocates 50% of these resources to "general" traffic, and 50% to 
    protected traffic.
- The graph was obtained by reducing the mainnet graph using a 
  random walk around our target node, and real-world routing policies 
  are used.
- When you run the attack, the non-malicious nodes in the network will 
  be executing [randomly generated payments](https://simln.dev) to 
  mimic an active network.

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
* Kubernetes
* [Just](https://github.com/casey/just)

Clone the attackathon repo:
`git clone https://github.com/carlaKC/attackathon`

*Do not change directory.*

The scripts will pull the relevant repositories to your current working
directory and set up your network. They expect the `attackathon` 
repository to be in the current directory.
* Warnet server: [./attackathon/scripts/start_warnet.sh](./scripts/start_warnet.sh) 
  sets up the warnet server, which is responsible for orchestration of 
  the network. 
  * You'll only need to do this once, but leave it running!
  * When you're done with it, bring it down with 
    [./attackathon/scripts/stop_warnet.sh](./scripts/stop_warnet.sh)
* Start network: [./attackathon/scripts/start_network.sh](/.scripts/start_network.sh)
  brings up your lightning network, opens channels, simulates 
  random payments in the network and mines blocks every 5 minutes.
  `./attackathon/scripts/start_network.sh ln_10`
  * If you want to kill your test network and start fresh, you can 
    re-run this script.
* Start attacking pods: [./attackathon/scripts/start_attacker.sh](./scripts/start_attacker.sh)
  brings up the lightning nodes that you will use for your attack and 
  a bitcoin node that you can use to fund the nodes / mine blocks.
  * You can use [./attackathon/scripts/stop_attacker.sh](./scripts/stop_attacker.sh) 
    to tear this down if you'd like to start over at any point.

## Assessment

Attacks will be assessed using the following measures:
- Did the attack achieve a jamming attack as described above?
- What was the total cost of the attack, considering:
  - On-chain fees: for channel opens and closes, sending funds between 
    nodes on-chain will node be included for simplicity's sake.
  - Off-chain fees: the sum of fees paid for successful off-chain 
    payments plus 1% of the success-case fees for *all* payments that 
    are sent to represent unconditional fees.
  - Opportunity cost of capital: for each channel that is opened, 5% 
    p.a. charged on the total capital deployed in the channels, 
    assuming 10 minute blocks.
- When compared to the operation of the network _without_ a jamming 
  attack, how many honest htlcs were dropped as a result of the attack?

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

To get started, you will need to clone the following repos *in the same
working directory*:
1. [This repo](https://github.com/carlaKC/attackathon)
2. [Warnet](https://github.com/bitcoin-dev-project/warnet)
3. [SimLN](https://github.com/bitcoin-dev-project/sim-ln)
3. [Circuitbreaker](https://github.com/lightningequipment/circuitbreaker)

You will need to provide: 
1. A `json` file with the same format as LND's `describegraph` output 
  which describes the graph that you'd like to simulate.
2. The duration of time, expressed in seconds, that you'd like the 
  setup script to generate fake historical forwards for all the nodes 
  in the network for.

The setup script provided will generate all required files and docker 
images for you:
`./attackathon/setup/create_network.sh {path to json file} {duration in seconds}`

Note that you *must* run this from your directory containing `warnet`, 
`simln` and `circuitbreaker` because it moves between directories to 
achieve various tasks! The name that you give the `json` file is 
considered to be your `network_name`. 

Once the script has completed, check in any files that it generated and 
provide your students with the following: 
1. The `network_name` for your attackathon.
2. The attackathon repo (/branch) with all files checked in.

The script currently hardcodes the docker hub account for images to 
`carlakirkcohen` and tries to push to it, so you'll need to search and 
replace if you want to test the full flow.

</details>
