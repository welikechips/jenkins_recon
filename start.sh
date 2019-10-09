#!/bin/bash
while read p; do
        echo "Testing" ${p}
        ./jenkins.sh ${p}
        sleep 120
done < targetips
