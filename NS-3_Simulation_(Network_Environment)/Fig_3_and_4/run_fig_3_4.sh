#!/bin/bash
# ============================================================
# Run simulations for figures 3 and 4
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

OUTFILE=~/results_fig_3_4.csv
echo "nruSenseDist_m,runId,nru_throughput_Mbps,nru_delay_ms,wifi_throughput_Mbps,wifi_delay_ms,nru_nodes,wifi_nodes" > $OUTFILE

# NR-U sensing distances we try

SENSE_DISTS=(90 100 110 120 130 140 150 160)

# Set runs to average over, number of parallel threads

RUNS=10
PARALLEL=4

TOTAL=$((${#SENSE_DISTS[@]} * RUNS))
DONE=0
TMPDIR=$(mktemp -d)

# Run a single sim, notice we vary only NR-U sensing distance

run_sim() {
    local dist=$1
    local run=$2
    local tmpfile=$3

    OUTPUT=$(./ns3 run "nru-wifi-coex \
        --arrivalRate=3.0 \
        --runId=$run \
        --simTime=5 \
        --nruDensity=0.0001 \
        --wifiDensity=0.0001 \
        --nruSenseDist=$dist \
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

    echo "$dist,$run,$NRU_TP,$NRU_DL,$WFI_TP,$WFI_DL,$NRU_N,$WFI_N" > "$tmpfile"
    echo "dist=$dist run=$run | NRU: ${NRU_TP} Mbps ${NRU_DL} ms | WiFi: ${WFI_TP} Mbps ${WFI_DL} ms"
}

export -f run_sim
export -p > /dev/null

# Create the parallel jobs for each sensing distance we do N runs

JOBS=()
IDX=0

for dist in "${SENSE_DISTS[@]}"; do
    for run in $(seq 0 $((RUNS-1))); do
        TMPFILE="$TMPDIR/result_${dist}_${run}.csv"
        run_sim "$dist" "$run" "$TMPFILE" &
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

for dist in "${SENSE_DISTS[@]}"; do
    for run in $(seq 0 $((RUNS-1))); do
        TMPFILE="$TMPDIR/result_${dist}_${run}.csv"
        if [ -f "$TMPFILE" ]; then
            cat "$TMPFILE" >> $OUTFILE
        fi
    done
done

# Exit

rm -rf "$TMPDIR"
echo ""
echo "Done. Results saved to $OUTFILE"
