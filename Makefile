FIB = ./_build/default/examples/fib.exe 
QSORT = ./_build/default/examples/qsort.exe 
QSORT_ARRAY = ./_build/default/examples/qsort_array.exe 
MSORT = ./_build/default/examples/msort.exe 

FIB_PAR = ./_build/default/benchmarks/fib_par.exe 
FIB_SEQ = ./_build/default/benchmarks/fib_seq.exe 

NUM_RUNS = 10 
NUM_WARMUP = 5

SLEEP_TIME = 10 

HYPERFINE = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} -P N 1 9 --cleanup 'sleep ${SLEEP_TIME}' --export-json results

.PHONY: speedup build clean fib_ex 

benchmark: speedup fib_ex

speedup: results build 
	${HYPERFINE}/fib38.json '${FIB} 38 {N}' 
	${HYPERFINE}/qsort_10000.json '${QSORT} 10000 {N}'
	${HYPERFINE}/qsort_array_500000.json '${QSORT_ARRAY} 500000 {N}'
	${HYPERFINE}/msort_10000.json '${MSORT} 10000 {N}'
	python scripts/plot_speedup.py

HYPERFINE_FIB = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} -P N 20 50 -D 5 --cleanup 'sleep ${SLEEP_TIME}' --export-json results

fib_ex: results build 
	${HYPERFINE_FIB}/fib_par.json '${FIB_PAR} {N} 8' 
	${HYPERFINE_FIB}/fib_seq.json '${FIB_SEQ} {N}' 
	${HYPERFINE_FIB}/fib_inet.json '${FIB} {N} 8'
	python scripts/plot_fib_ex.py 

results: 
	mkdir results 

clean: 
	rm -rf results 
	dune clean 

build: 
	dune build 
