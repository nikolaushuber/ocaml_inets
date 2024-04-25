FIB = ./_build/default/examples/fib.exe 
QSORT = ./_build/default/examples/qsort.exe 
QSORT_ARRAY = ./_build/default/examples/qsort_array.exe 
MSORT = ./_build/default/examples/msort.exe 

NUM_RUNS = 10 
NUM_WARMUP = 5

SLEEP_TIME = 10 

HYPERFINE = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} -P N 1 9 --cleanup 'sleep ${SLEEP_TIME}' --export-json results

.PHONY: speedup build clean 

speedup: results build 
	${HYPERFINE}/fib38.json '${FIB} 38 {N}' 
	${HYPERFINE}/qsort_10000.json '${QSORT} 10000 {N}'
	${HYPERFINE}/qsort_array_500000.json '${QSORT_ARRAY} 500000 {N}'
	${HYPERFINE}/msort_10000.json '${MSORT} 10000 {N}'
	python scripts/plot_speedup.py

results: 
	mkdir results 

clean: 
	rm -rf results 
	dune clean 

build: 
	dune build 
