#!/usr/bin/env bash

echo "Start BSTer test flow"

svutRun -test ./bster_testbench.sv | tee log
ret=$?

if [[ $ret != 0 ]]; then
    echo "Execution testsuite failed"
    exit 1
fi

ec=$(grep -c "ERROR:" log)

if [[ $ec != 0 ]]; then
    echo "Execution suffered $ec issues"
    exit 1
fi

echo "BSTer test flow successfully terminated ^^"
