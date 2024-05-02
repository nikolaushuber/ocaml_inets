NUM_CPUS = 20 

PYTHON = python3
FIB_ARG = 45
SORT_ARG = 100000 
SORT_SEED = 1234567

FIB = ./_build/default/examples/fib.exe 
QSORT = ./_build/default/examples/qsort.exe 
QSORT_ARRAY = ./_build/default/examples/qsort_array.exe 
MSORT = ./_build/default/examples/msort.exe 

FIB_PAR = ./_build/default/benchmarks/fib_par.exe 
FIB_SEQ = ./_build/default/benchmarks/fib_seq.exe 

NUM_RUNS = 100
NUM_WARMUP = 5

SLEEP_TIME = 1

HYPERFINE = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} -P N 1 ${NUM_CPUS} --cleanup 'sleep ${SLEEP_TIME}' --export-json results

.PHONY: speedup build clean fib_ex 

benchmark: speedup fib_ex perf 

speedup: results build 
	${HYPERFINE}/fib_speedup.json '${FIB} ${FIB_ARG} {N}' 
	${HYPERFINE}/qsort_speedup.json '${QSORT} ${SORT_ARG} {N} ${SORT_SEED}'
	${HYPERFINE}/msort_speedup.json '${MSORT} ${SORT_ARG} {N} ${SORT_SEED}'
	${PYTHON} scripts/plot_speedup.py --cpus=${NUM_CPUS} -o ./results/speedup.png

HYPERFINE_FIB = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} -P N 20 50 -D 5 --cleanup 'sleep ${SLEEP_TIME}' --export-json results

fib_ex: results build 
	${HYPERFINE_FIB}/fib_par.json '${FIB_PAR} {N} 8' 
	${HYPERFINE_FIB}/fib_seq.json '${FIB_SEQ} {N}' 
	${HYPERFINE_FIB}/fib_inet.json '${FIB} {N} 8'
	${PYTHON} scripts/plot_fib_ex.py -o ./results/fib_ex.png

perf: results build 
	bash scripts/run_cache_analysis.sh ${NUM_CPUS} ${NUM_RUNS} ${FIB_ARG} ${SORT_ARG} ${SORT_SEED}
	${PYTHON} scripts/plot_cpu_migrations.py --cpus=${NUM_CPUS} -o ./results/cpu_migrations.png
	

results: 
	mkdir results 

clean: 
	rm -rf results 
	dune clean 

build: 
	dune build 
