#!/bin/bash 

ncpus=$1
nruns=$2 
fib_arg=$3
sort_arg=$4
seed=$5


rm -rf ./results/fib_cache.txt
for n in $(seq 1 $ncpus) 
do 
    for run in $(seq 1 $nruns) 
    do 
        perf stat -B -e cache-references,cache-misses,cpu-migrations,context-switches -- ./_build/default/examples/fib.exe $fib_arg $n 1> /dev/null 2>> ./results/fib_cache.txt 
    done 
done

rm -rf ./results/qsort_cache.txt 
for n in $(seq 1 $ncpus) 
do 
    for run in $(seq 1 $nruns) 
    do 
        perf stat -B -e cache-references,cache-misses,cpu-migrations,context-switches -- ./_build/default/examples/qsort.exe $sort_arg $n $seed 1> /dev/null 2>> ./results/qsort_cache.txt 
    done 
done 

rm -rf ./results/msort_cache.txt 
for n in $(seq 1 $ncpus) 
do 
    for run in $(seq 1 $nruns) 
    do 
        perf stat -B -e cache-references,cache-misses,cpu-migrations,context-switches -- ./_build/default/examples/msort.exe $sort_arg $n $seed 1> /dev/null 2>> ./results/msort_cache.txt 
    done 
done 

