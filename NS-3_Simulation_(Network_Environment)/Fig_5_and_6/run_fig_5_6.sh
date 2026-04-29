#!/bin/bash
# ============================================================
# Run simulations for figures 5 and 6
# Set PARALLEL = number of CPU cores
# ============================================================

set -u

# Locate directory currently running in

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR" || exit 1

# Build the .cc file

echo "Building simulation..."
./ns3 build scratch/sim-1.cc 2>&1 | tail -10 
if [ $? -ne 0 ]; then
    echo "BUILD FAILED."
    exit 1
fi
echo "Build successful."

# Our final results file with values

OUTFILE="$SCRIPT_DIR/results_fig_5_6.csv"
echo "nruDensity_nodes_per_m2,runId,nru_throughput_Mbps,nru_delay_ms,wifi_throughput_Mbps,wifi_delay_ms,nru_nodes,wifi_nodes" > "$OUTFILE"

# NR-U node densities we try

DENSITIES=(1e-4 1.5e-4 2e-4 2.5e-4 3e-4 3.5e-4 4e-4 4.5e-4 5e-4)

# Set runs to average over, number of parallel threads

RUNS=10
PARALLEL=4

TOTAL=$((${#DENSITIES[@]} * RUNS))
DONE=0
TMPDIR=$(mktemp -d)

# Run a single sim, notice we vary only NR-U density

run_sim() {
    local density=$1
    local run=$2
    local tmpfile=$3

    echo "[STARTING] Density=$density | Run=$run (Running in background...)"

    OUTPUT=$(./ns3 run "scratch/sim-1.cc \
        --arrivalRate=3.0 \
        --runId=$run \
        --simTime=5 \
        --nruDensity=$density \
        --wifiDensity=0.0001 \
        --nruSenseDist=100 \
        --nruTxDist=80 \
        --wifiSenseDist=90 \
        --wifiTxDist=70 \
        --nruDataRate=100 \
        --wifiDataRate=54 \
        --areaSize=1000" 2>&1)

    NRU_TP=$(echo "$OUTPUT" | grep "NRU_THROUGHPUT"  | awk '{print $2}')
    NRU_DL=$(echo "$OUTPUT" | grep "NRU_DELAY"       | awk '{print $2}')
    WFI_TP=$(echo "$OUTPUT" | grep "WIFI_THROUGHPUT" | awk '{print $2}')
    WFI_DL=$(echo "$OUTPUT" | grep "WIFI_DELAY"      | awk '{print $2}')
    NRU_N=$(echo  "$OUTPUT" | grep "NRU_NODES"       | awk '{print $2}')
    WFI_N=$(echo  "$OUTPUT" | grep "WIFI_NODES"      | awk '{print $2}')

    echo "$density,$run,$NRU_TP,$NRU_DL,$WFI_TP,$WFI_DL,$NRU_N,$WFI_N" > "$tmpfile"
    echo "[FINISHED] Density=$density Run=$run | NR-U: ${NRU_TP} Mbps ${NRU_DL} ms | WiFi: ${WFI_TP} Mbps ${WFI_DL} ms"
}

# Create the parallel jobs for each density we do N runs

JOBS=()

for density in "${DENSITIES[@]}"; do
    for run in $(seq 0 $((RUNS - 1))); do
        safe_density=${density//./p}
        TMPFILE="$TMPDIR/result_${safe_density}_${run}.csv"
        run_sim "$density" "$run" "$TMPFILE" &
        JOBS+=($!)

        if [ ${#JOBS[@]} -ge $PARALLEL ]; then
            wait "${JOBS[0]}"
            JOBS=("${JOBS[@]:1}")
            DONE=$((DONE + 1))
            echo "Progress: [$DONE/$TOTAL] complete."
        fi
    done
done

# Let each job complete, if so update progress on terminal

for job in "${JOBS[@]}"; do
    wait "$job"
    DONE=$((DONE + 1))
    echo "Progress: [$DONE/$TOTAL] complete."
done

# Save results in CSV

for density in "${DENSITIES[@]}"; do
    safe_density=${density//./p}
    for run in $(seq 0 $((RUNS - 1))); do
        TMPFILE="$TMPDIR/result_${safe_density}_${run}.csv"
        if [ -f "$TMPFILE" ]; then
            cat "$TMPFILE" >> "$OUTFILE"
        fi
    done
done

# Exit

rm -rf "$TMPDIR"
echo ""
echo "Done! Results saved to $OUTFILE"
