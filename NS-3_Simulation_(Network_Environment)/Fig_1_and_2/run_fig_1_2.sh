#!/bin/bash
# ============================================================
# Run simulations for figures 1 and 2
# Set PARALLEL = number of CPU cores
# ============================================================

# Locate directory currently running in

cd ~/ns-3-dev

# Build the .cc file

echo "Building simulation..."
./ns3 build nru-wifi-coex 2>&1 | tail -3
if [ $? -ne 0 ]; then echo "BUILD FAILED."; exit 1; fi
echo "Build successful."

# Our final results file with values

OUTFILE=~/results_fig_1_2.csv
echo "nruDataRate_Mbps,runId,nru_throughput_Mbps,nru_delay_ms,wifi_throughput_Mbps,wifi_delay_ms,nru_nodes,wifi_nodes" > $OUTFILE

# NR-U data rates we try

NRU_RATES=(40 50 60 70 80 90 100 110 120)

# Set runs to average over, number of parallel threads

RUNS=10
PARALLEL=4

TOTAL=$((${#NRU_RATES[@]} * RUNS))
DONE=0
TMPDIR=$(mktemp -d)

# Run a single sim, notice we vary only NR-U data rate

run_sim() {
    local rate=$1
    local run=$2
    local tmpfile=$3

    OUTPUT=$(./ns3 run "nru-wifi-coex \
        --arrivalRate=3.0 \
        --runId=$run \
        --simTime=5 \
        --nruDensity=0.0001 \
        --wifiDensity=0.0001 \
        --nruSenseDist=100 \
        --nruTxDist=80 \
        --wifiSenseDist=90 \
        --wifiTxDist=70 \
        --nruDataRate=$rate \
        --wifiDataRate=54 \
        --areaSize=1000" 2>&1)

    NRU_TP=$(echo "$OUTPUT" | grep "NRU_THROUGHPUT"  | awk '{print $2}')
    NRU_DL=$(echo "$OUTPUT" | grep "NRU_DELAY"       | awk '{print $2}')
    WFI_TP=$(echo "$OUTPUT" | grep "WIFI_THROUGHPUT" | awk '{print $2}')
    WFI_DL=$(echo "$OUTPUT" | grep "WIFI_DELAY"      | awk '{print $2}')
    NRU_N=$(echo  "$OUTPUT" | grep "NRU_NODES"       | awk '{print $2}')
    WFI_N=$(echo  "$OUTPUT" | grep "WIFI_NODES"      | awk '{print $2}')

    echo "$rate,$run,$NRU_TP,$NRU_DL,$WFI_TP,$WFI_DL,$NRU_N,$WFI_N" > "$tmpfile"
    echo "rate=$rate run=$run | NRU: ${NRU_TP} Mbps ${NRU_DL} ms | WiFi: ${WFI_TP} Mbps ${WFI_DL} ms"
}

export -f run_sim

# Create the parallel jobs for each data rate we do N runs

JOBS=()
IDX=0

for rate in "${NRU_RATES[@]}"; do
    for run in $(seq 0 $((RUNS-1))); do
        TMPFILE="$TMPDIR/result_${rate}_${run}.csv"
        run_sim "$rate" "$run" "$TMPFILE" &
        JOBS+=($!)
        IDX=$((IDX+1))

        if [ ${#JOBS[@]} -ge $PARALLEL ]; then
            wait "${JOBS[0]}"
            JOBS=("${JOBS[@]:1}")
            DONE=$((DONE+1))
            echo "[$DONE/$TOTAL] completed"
        fi
    done
done

# Let each job complete, if so update progress on terminal

for job in "${JOBS[@]}"; do
    wait "$job"
    DONE=$((DONE+1))
    echo "[$DONE/$TOTAL] completed"
done

# Save results in CSV

for rate in "${NRU_RATES[@]}"; do
    for run in $(seq 0 $((RUNS-1))); do
        TMPFILE="$TMPDIR/result_${rate}_${run}.csv"
        if [ -f "$TMPFILE" ]; then
            cat "$TMPFILE" >> $OUTFILE
        fi
    done
done

# Exit

rm -rf "$TMPDIR"
echo ""
echo "Done. Results saved to $OUTFILE"
