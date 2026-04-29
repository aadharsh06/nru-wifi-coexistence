"""
Plotting for figures 3 and 4.
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
csv_path = os.path.expanduser("results_fig_3_4.csv")

if not os.path.exists(csv_path):
    print(f"ERROR: {csv_path} not found.")
    exit(1)

# Read the CSV

df = pd.read_csv(csv_path)
grouped = df.groupby("nruSenseDist_m").agg(
    nru_tp_mean=("nru_throughput_Mbps", "mean"),
    nru_dl_mean=("nru_delay_ms", "mean"),
    wifi_tp_mean=("wifi_throughput_Mbps", "mean"),
    wifi_dl_mean=("wifi_delay_ms", "mean"),
).reset_index()

# Calculate means of the data

x = grouped["nruSenseDist_m"].values
nru_tp = grouped["nru_tp_mean"].values
wifi_tp = grouped["wifi_tp_mean"].values
nru_dl = grouped["nru_dl_mean"].values
wifi_dl = grouped["wifi_dl_mean"].values

# Plot Throughput

fig, ax = plt.subplots(figsize=(6, 4))
ax.plot(x, nru_tp,  'b-o', label='NR-U', linewidth=1.5, markersize=5)
ax.plot(x, wifi_tp, 'r-+', label='WiFi', linewidth=1.5, markersize=7,
        markeredgewidth=1.5)
ax.set_xlabel("the sensing distance of an NR-U gNB(m)", fontsize=10)
ax.set_ylabel("throughput(Mbps)", fontsize=10)
ax.set_ylim(bottom=0)
ax.set_xticks(x)
ax.legend(fontsize=9)
ax.grid(True, linestyle='--', alpha=0.4)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "Fig_3_Throughput_vs_sensingdist.png"), dpi=150)
print("Saved Fig_3_Throughput_vs_sensingdist.png")

# Plot Delay

fig, ax = plt.subplots(figsize=(6, 4))
ax.plot(x, nru_dl,  'b-o', label='NR-U', linewidth=1.5, markersize=5)
ax.plot(x, wifi_dl, 'r-+', label='WiFi', linewidth=1.5, markersize=7,
        markeredgewidth=1.5)
ax.set_xlabel("the sensing distance of an NR-U gNB(m)", fontsize=10)
ax.set_ylabel("packet delay(ms)", fontsize=10)
ax.set_ylim(bottom=0)
ax.set_xticks(x)
ax.legend(fontsize=9)
ax.grid(True, linestyle='--', alpha=0.4)
fig.tight_layout()
fig.savefig(os.path.join(OUT_DIR, "Fig_4_Delay_vs_sensingdist.png"), dpi=150)
print("Saved Fig_4_Delay_vs_sensingdist.png")
