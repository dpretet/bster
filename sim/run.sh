#!/usr/bin/env bash

echo "Start BSTer test flow"
ts="./bster_testbench_operations.sv"

# Checkk if a specific testsuite is passed
if [[ -n $1 ]]; then
    ts="$1"
fi

svutRun -test "$ts" | tee run.log
ret=$?

if [[ $ret != 0 ]]; then
    echo "Execution testsuite failed"
    exit 1
fi

ec=$(grep -c "ERROR:" run.log)

if [[ $ec != 0 ]]; then
    echo "Execution failed"
    exit 1
fi

echo "BSTer test flow successfully terminated ^^"
