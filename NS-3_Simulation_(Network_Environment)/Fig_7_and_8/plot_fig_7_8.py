"""
Plotting for figures 7 and 8.
We utilize matplotlib.

NOTE: Make sure CSV file is in the same directory.
"""

import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import os

# Ensure paths

OUT_DIR = os.path.expanduser(".")
csv_path = os.path.expanduser("results_fig_7_8.csv")

if not os.path.exists(csv_path):
    print(f"ERROR: {csv_path} not found.")
    exit(1)

# Read the CSV

df = pd.read_csv(csv_path)
grouped = df.groupby("arrivalRate_pkts_per_ms").agg(
    nru_tp_mean=("nru_throughput_Mbps", "mean"),
    nru_dl_mean=("nru_delay_ms", "mean"),
    wifi_tp_mean=("wifi_throughput_Mbps", "mean"),
    wifi_dl_mean=("wifi_delay_ms", "mean"),
).reset_index()

# Calculate means of the data

x = grouped["arrivalRate_pkts_per_ms"].values
nru_tp = grouped["nru_tp_mean"].values
wifi_tp = grouped["wifi_tp_mean"].values
nru_dl = grouped["nru_dl_mean"].values
wifi_dl = grouped["wifi_dl_mean"].values

# Plot Throughput

fig, ax = plt.subplots(figsize=(8, 6))
ax.plot(x, nru_tp, 'b-*', linewidth=2.0, markersize=8, label='NR-U')
ax.plot(x, wifi_tp, 'r-+', linewidth=2.0, markersize=8, label='WiFi')
ax.set_title('Fig. 7 Throughput vs the packet arrival rate', fontsize=14)
ax.set_xlabel('The packet arrival rate (packets/ms)', fontsize=12)
ax.set_ylabel('Throughput (Mbps)', fontsize=12)
ax.grid(True, linestyle="--", linewidth=0.5, alpha=0.7)
ax.legend(fontsize=11, loc='best', frameon=True)
ax.set_xscale('log')
ax.set_xlim(x[0], x[-1])
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "Fig_7_Throughput_vs_Lambda.png"), dpi=300)
print("Saved Fig_7_Throughput_vs_Lambda.png")

# Plot Delay

fig, ax = plt.subplots(figsize=(8, 6))
ax.plot(x, nru_dl, 'b-*', linewidth=2.0, markersize=8, label='NR-U')
ax.plot(x, wifi_dl, 'r-+', linewidth=2.0, markersize=8, label='WiFi')
ax.set_title('Fig. 8 Packet delay vs the packet arrival rate', fontsize=14)
ax.set_xlabel('The packet arrival rate (packets/ms)', fontsize=12)
ax.set_ylabel('Packet delay (ms)', fontsize=12)
ax.grid(True, linestyle="--", linewidth=0.5, alpha=0.7)
ax.legend(fontsize=11, loc='best', frameon=True)
ax.set_xscale('log')
ax.set_xlim(x[0], x[-1])
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "Fig_8_Delay_vs_Lambda.png"), dpi=300)
print("Saved Fig_8_Delay_vs_Lambda.png")
