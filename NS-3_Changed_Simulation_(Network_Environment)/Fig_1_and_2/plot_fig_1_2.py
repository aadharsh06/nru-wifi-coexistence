"""
Plotting for figures 1 and 2.
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
csv_path = os.path.expanduser("results_fig_1_2.csv")

if not os.path.exists(csv_path):
    print(f"ERROR: {csv_path} not found.")
    exit(1)

# Read the CSV

df = pd.read_csv(csv_path)
grouped = df.groupby("nruDataRate_Mbps").agg(
    nru_tp_mean=("nru_throughput_Mbps", "mean"),
    nru_dl_mean=("nru_delay_ms", "mean"),
    wifi_tp_mean=("wifi_throughput_Mbps", "mean"),
    wifi_dl_mean=("wifi_delay_ms", "mean"),
).reset_index()

# Calculate means of the data

x = grouped["nruDataRate_Mbps"].values
nru_tp = grouped["nru_tp_mean"].values
wifi_tp = grouped["wifi_tp_mean"].values
nru_dl = grouped["nru_dl_mean"].values
wifi_dl = grouped["wifi_dl_mean"].values

# Plot Throughput

fig, ax = plt.subplots(figsize=(5.5, 4))
ax.plot(x, nru_tp,  'b-*', label='NR-U', linewidth=1.5, markersize=6)
ax.plot(x, wifi_tp, 'r-+', label='WiFi', linewidth=1.5, markersize=8,
        markeredgewidth=1.5)
ax.set_xlabel("the channel transmission rate of an NR-U gNB(Mbps)", fontsize=9)
ax.set_ylabel("throughput(Mbps)", fontsize=9)
ax.set_xlim(40, 120)
ax.set_ylim(2.5, 8)
ax.set_xticks([40, 50, 60, 70, 80, 90, 100, 110, 120])
ax.set_yticks([2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8])
ax.legend(fontsize=9, loc='upper left')
ax.grid(False)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "Fig_1_Throughput_vs_nrurate.png"), dpi=150)
print("Saved Fig_1_Throughput_vs_nrurate.png")

# Plot Delay

fig, ax = plt.subplots(figsize=(5.5, 4))
ax.plot(x, nru_dl,  'b-*', label='NR-U', linewidth=1.5, markersize=6)
ax.plot(x, wifi_dl, 'r-+', label='WiFi', linewidth=1.5, markersize=8,
        markeredgewidth=1.5)
ax.set_xlabel("the channel transmission rate of an NR-U gNB(Mbps)", fontsize=9)
ax.set_ylabel("packet delay(ms)", fontsize=9)
ax.set_xlim(40, 120)
ax.set_ylim(1, 3.5)
ax.set_xticks([40, 50, 60, 70, 80, 90, 100, 110, 120])
ax.set_yticks([1, 1.5, 2, 2.5, 3, 3.5])
ax.legend(fontsize=9, loc='upper right')
ax.grid(False)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "Fig_2_Delay_vs_nrurate.png"), dpi=150)
print("Saved Fig_2_Delay_vs_nrurate.png")
