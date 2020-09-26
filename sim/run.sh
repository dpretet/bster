#!/usr/bin/env bash

echo "Start BSTer test flow"

svutRun -test ./bster_testbench.sv | tee run.log
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
