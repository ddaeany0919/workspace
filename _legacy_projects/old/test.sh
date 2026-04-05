#!/bin/bash

function getResult {
    local doAnymore=true;
    while $doAnymore; do
        select index in "A" "B" "C"; do
            case $index in
                "A")
                    doAnymore=false;
                    break;
                "B")
                    echo "BBBB";
                    continue;
                "C")
                    break;
            esac
        done
    done
}