"""
Plotting for figures 7 and 8.
We utilize matplotlib.

NOTE: This script runs SIM-2 directly and saves figures in the same directory.
"""

import subprocess
import re
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# Run the NS-3 simulation

def run_ns3(rate_mbps, n_w, n_u, seed):
    rate_str = f"{rate_mbps:.4f}Mbps"
    cmd = [
        "./ns3",
        "run",
        f"scratch/SIM-2.cc --dataRate={rate_str} --nWifi={n_w} "
        f"--nNru={n_u} --rngRun={seed}",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    out = result.stdout

    w_tp, n_tp, w_dly, n_dly = 0.0, 0.0, 0.0, 0.0

    m_w_tp = re.search(r"Avg WiFi Throughput \(per AP\):\s+([0-9.]+)\s+Mbps", out)
    m_n_tp = re.search(r"Avg NR-U Throughput \(per gNB\):\s+([0-9.]+)\s+Mbps", out)
    m_w_dly = re.search(r"Avg WiFi Delay:\s+([0-9.eE+-]+)\s+ms", out)
    m_n_dly = re.search(r"Avg NR-U Delay:\s+([0-9.eE+-]+)\s+ms", out)

    if m_w_tp:
        w_tp = float(m_w_tp.group(1))
    if m_n_tp:
        n_tp = float(m_n_tp.group(1))
    if m_w_dly:
        w_dly = float(m_w_dly.group(1))
    if m_n_dly:
        n_dly = float(m_n_dly.group(1))

    return w_tp, n_tp, w_dly, n_dly

# Set simulation values

rng_run = 61
grid_area = 300.0 * 300.0

print("\n" + "="*50)
print("RUNNING SCENARIO 1: Varying Arrival Rate (Fig 7 & 8)")
print("="*50)

# Create values to test

lambda_vec = np.logspace(-1, 2, 12)
n_wifi_fixed = 9
n_nru_fixed = 9

tp_w_1, tp_u_1, del_w_1, del_u_1 = [], [], [], []

# Run each simulation

for rate in lambda_vec:
    mbps = rate * 12.0
    print(f"Testing Lambda {rate:.4f} pkts/ms...", end="", flush=True)

    wt, nt, wd, nd = run_ns3(mbps, n_wifi_fixed, n_nru_fixed, rng_run)
    tp_w_1.append(wt)
    tp_u_1.append(nt)
    del_w_1.append(wd)
    del_u_1.append(nd)

    print(f" [Done] W_TP:{wt:.2f} U_TP:{nt:.2f} | W_Dly:{wd:.2f}ms U_Dly:{nd:.2f}ms")

# Plot Throughput

plt.figure(figsize=(8, 6))
plt.plot(lambda_vec, tp_u_1, 'b-*', linewidth=2.0, markersize=8, label='NR-U')
plt.plot(lambda_vec, tp_w_1, 'r-+', linewidth=2.0, markersize=8, label='WiFi')
plt.xscale('log')
plt.title('Fig. 7 Throughput vs the packet arrival rate', fontsize=14)
plt.xlabel(r'Packet Arrival Rate $\lambda$ (packets/ms)', fontsize=12)
plt.ylabel('Throughput (Mbps)', fontsize=12)
plt.grid(True, which="both", linestyle="--", linewidth=0.5, alpha=0.7)
plt.legend(fontsize=11, loc='best', frameon=True)
plt.savefig("Fig_7_Throughput_vs_Lambda.png", dpi=300, bbox_inches='tight')
plt.close()
print("Saved Fig_7_Throughput_vs_Lambda.png")

# Plot Delay

plt.figure(figsize=(8, 6))
plt.plot(lambda_vec, del_u_1, 'b-*', linewidth=2.0, markersize=8, label='NR-U')
plt.plot(lambda_vec, del_w_1, 'r-+', linewidth=2.0, markersize=8, label='WiFi')
plt.xscale('log')
plt.title('Fig. 8 Packet delay vs the packet arrival rate', fontsize=14)
plt.xlabel(r'Packet Arrival Rate $\lambda$ (packets/ms)', fontsize=12)
plt.ylabel('Packet Delay (ms)', fontsize=12)
plt.grid(True, which="both", linestyle="--", linewidth=0.5, alpha=0.7)
plt.legend(fontsize=11, loc='best', frameon=True)
plt.savefig("Fig_8_Delay_vs_Lambda.png", dpi=300, bbox_inches='tight')
plt.close()
print("Saved Fig_8_Delay_vs_Lambda.png")
