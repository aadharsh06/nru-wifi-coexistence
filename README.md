# Simulation-Based Performance Analysis of an NR-U and WiFi Coexistence System

## Overview

This repository contains the simulation framework, mathematical models, and analysis scripts developed to evaluate the coexistence performance of New Radio Unlicensed (NR-U) and WiFi systems operating in the shared 5 GHz unlicensed spectrum. The core objective of this project is to explicitly model and analyze the impact of the hidden-node problem on network throughput and average packet delay.

The implementation integrates stochastic network modeling, packet-level discrete-event simulation, and empirical post-processing analysis.

## System Architecture

The project is structured across four primary layers:

1. **Network Topology Layer:** The spatial distribution of NR-U base stations (gNBs) and WiFi access points (APs) is modeled across a two-dimensional bounded area using independent homogeneous Poisson Point Processes (PPP).

2. **Simulation Layer (ns-3):** The core packet-level simulation is implemented in C++ using the ns-3 network simulator. NR-U channel access is modeled using the Category-4 Listen Before Talk (LBT) mechanism, while WiFi utilizes the standard Distributed Coordination Function (DCF).
3. **Analysis Layer (MATLAB & Python):** MATLAB is utilized for theoretical mathematical modeling of the coexistence behavior based on CSMA abstractions. Python scripts parse the simulation trace files to compute metrics and generate performance visualizations.

4. **Data Capture Layer:** Wireshark is integrated to capture packet transmissions, validate protocol behavior, and verify the physical occurrence of collisions.

## Key Features

* **Hidden Node Modeling:** The system explicitly defines sensible nodes (within the sensing range) and hidden nodes (outside the sensing range but within the interference range), allowing for the accurate simulation of unmitigated packet collisions.
* **Stochastic Traffic Generation:** Application-layer data traffic is generated using UDP sockets, with packet inter-arrival times following an exponential distribution to simulate a realistic Poisson arrival process.

* **Scalable Abstraction:** NR-U behavior is mapped onto the ns-3 WiFi PHY/MAC architecture using customized configuration parameters, including Clear Channel Assessment (CCA) thresholds derived via the Friis free-space propagation model and equivalent data rate packet scaling.

* **Automated Parameter Sweeping:** Shell scripts automate hundreds of simulation iterations across varying node densities, transmission rates, sensing distances, and traffic loads to ensure statistical reliability.

## Prerequisites

To execute the simulation and analysis scripts, the following environments must be configured:

* **ns-3 Network Simulator:** (Requires C++ compiler, CMake).

* **MATLAB:** Version R2023a or newer for mathematical modeling.

* **Python 3.x:** Required libraries include `pandas` and `matplotlib` for log parsing and graph generation.

* **Wireshark:** For optional `.pcap` trace file analysis.

## Simulation Parameters

The default configuration parameters utilized within the simulation environment are detailed below:

| Parameter                    | Value                         |
|-----------------------------|-------------------------------|
| Simulation Area Size        | 1000 m × 1000 m               |
| Node Spatial Distribution   | Homogeneous PPP               |
| NR-U Sensing Distance       | 100 m                         |
| WiFi Sensing Distance       | 90 m                          |
| NR-U Transmission Distance  | 80 m                          |
| WiFi Transmission Distance  | 70 m                          |
| NR-U Equivalent Data Rate   | 100 Mbps                      |
| WiFi Channel Rate           | 54 Mbps                       |
| UDP Payload Size            | 1500 bytes (scaled for NR-U)  |

## Usage Instructions

1. **Compilation:** Place the `nru-wifi-coex.cc` file into the `scratch/` directory of your ns-3 installation. Compile the script using the standard ns-3 build system (`./ns3 build`).


2. **Execution:** Run the simulation via the command line. Parameters can be modified at runtime using the defined command-line arguments:
```bash
./ns3 run "scratch/nru-wifi-coex --arrivalRate=3.0 --nruDensity=0.0001 --nruSenseDist=100.0"

```

3. **Analysis:** Execute the provided Python scripts against the generated standard output and CSV trace files to compute the average throughput (Mbps) and packet delay (ms).



## Key Analytical Findings

Extensive simulation results validate the theoretical coexistence models under varying environmental conditions:

**Transmission Rate:** Increasing the NR-U transmission rate reduces the physical channel occupancy time per packet, significantly improving NR-U throughput and reducing queueing delay.


* **Sensing Distance Trade-offs:** Expanding the NR-U sensing distance decreases hidden-node occurrences but drastically increases the number of sensible nodes. This forces the NR-U gNB into frequent deferral states, severely degrading its throughput while inadvertently protecting WiFi performance.


* **Node Density:** Higher spatial density directly increases MAC-layer contention. This results in heightened backoff frequencies, causing severe throughput degradation and exponential delay growth for both networks operating on the shared channel.


* **Traffic Saturation:** As the packet arrival rate increases, the network transitions from an underutilized state to full saturation. While initial throughput scales linearly, saturation induces exponential queueing delays, particularly for NR-U due to its larger sensing footprint.



## References

* Ren, Q., & Zheng, J. (2023). Simulation-based Performance Analysis of an NR-U and WiFi Coexistence System in the Presence of Hidden Nodes. Proceedings of the IEEE ICNC.


* 3GPP TS 37.213. Physical layer procedures for shared spectrum channel access. Release 17.


* The ns-3 Network Simulator.
