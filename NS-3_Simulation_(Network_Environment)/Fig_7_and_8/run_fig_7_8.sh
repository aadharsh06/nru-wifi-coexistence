#!/bin/bash
# ============================================================
# Run simulations for figures 7 and 8
# Set PARALLEL = number of CPU cores
# ============================================================

set -u

# Locate directory currently running in

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR" || exit 1

# Build the .cc file

echo "Building simulation..."
./ns3 build scratch/nru-wifi-coex.cc 2>&1 | tail -10 
if [ $? -ne 0 ]; then
    echo "BUILD FAILED."
    exit 1
fi
echo "Build successful."

# Our final results file with values

OUTFILE="$SCRIPT_DIR/results_fig_7_8.csv"
echo "arrivalRate_pkts_per_ms,runId,nru_throughput_Mbps,nru_delay_ms,wifi_throughput_Mbps,wifi_delay_ms,nru_nodes,wifi_nodes" > "$OUTFILE"

# logspace ( -1, 2, 12 )

ARRIVAL_RATES=(0.1000 0.1874 0.3511 0.6579 1.2328 2.3101 4.3288 8.1113 15.1991 28.4804 53.3670 100.0000)

# Set runs to average over, number of parallel threads

RUNS=10
PARALLEL=20 

TOTAL=$((${#ARRIVAL_RATES[@]} * RUNS))
DONE=0
TMPDIR=$(mktemp -d)

# Run a single sim, notice we vary only packet arrival rate

run_sim() {
    local rate=$1
    local run=$2
    local tmpfile=$3

    echo "[STARTING] Lambda=$rate | Run=$run (Running in background...)"

    OUTPUT=$(./ns3 run "scratch/nru-wifi-coex.cc \
        --arrivalRate=$rate \
        --runId=$run \
        --simTime=5 \
        --nruDensity=0.0001 \
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

    echo "$rate,$run,$NRU_TP,$NRU_DL,$WFI_TP,$WFI_DL,$NRU_N,$WFI_N" > "$tmpfile"
    echo "[FINISHED] Lambda=$rate Run=$run | NR-U: ${NRU_TP} Mbps ${NRU_DL} ms | WiFi: ${WFI_TP} Mbps ${WFI_DL} ms"
}

# Create the parallel jobs for each arrival rate we do N runs

JOBS=()

for rate in "${ARRIVAL_RATES[@]}"; do
    for run in $(seq 0 $((RUNS - 1))); do
        safe_rate=${rate//./p}
        TMPFILE="$TMPDIR/result_${safe_rate}_${run}.csv"
        run_sim "$rate" "$run" "$TMPFILE" &
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

for rate in "${ARRIVAL_RATES[@]}"; do
    safe_rate=${rate//./p}
    for run in $(seq 0 $((RUNS - 1))); do
        TMPFILE="$TMPDIR/result_${safe_rate}_${run}.csv"
        if [ -f "$TMPFILE" ]; then
            cat "$TMPFILE" >> "$OUTFILE"
        fi
    done
done

# Exit

rm -rf "$TMPDIR"
echo ""
echo "Done! Results saved to $OUTFILE"
