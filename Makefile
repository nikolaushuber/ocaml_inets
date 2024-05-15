# Change these to fit your setup: 

# Number of processors (e.g., as reported by lscpu)
NUM_CPUS = 20


### Speedup + Fib runtime ### 

# Number of tests to average over 
NUM_RUNS = 10

# Number of warmup runs per test 		
NUM_WARMUP = 5

# Name of the python executable to run for plotting 		
PYTHON = python3


### Tool comparison ###

# Inpla executable 	
INPLA = ../inpla/inpla

# HINets executable 
HINETS = RunInets	

# Number of runs for tool comparison 
NUM_RUNS_TOOLS = 10 

# Timeout when running inpla, our encoding, and HINets
TOOLS_TIMEOUT = 1m 


### ONLY CHANGE THINGS BELOW IF YOU KNOW WHAT YOU ARE DOING ###

FIB_ARG = 45
SORT_ARG = 100000 
SORT_SEED = 1234567

FIB = ./_build/default/examples/fib.exe 
QSORT = ./_build/default/examples/qsort.exe 
QSORT_ARRAY = ./_build/default/examples/qsort_array.exe 
MSORT = ./_build/default/examples/msort.exe 

FIB_PAR = ./_build/default/benchmarks/fib_par.exe 
FIB_SEQ = ./_build/default/benchmarks/fib_seq.exe 
FIB_INET_SIMP = ./_build/default/benchmarks/fib_inet_simple.exe 

SLEEP_TIME = 1

HYPERFINE = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} -P N 1 ${NUM_CPUS} --cleanup 'sleep ${SLEEP_TIME}' --export-json results

.PHONY: speedup_perf build clean fib_ex speedup_hyperfine perf 

benchmark: speedup_perf fib_ex 

speedup_hyperfine: results build 
	${HYPERFINE}/fib_speedup.json '${FIB} ${FIB_ARG} {N}' 
	${HYPERFINE}/qsort_speedup.json '${QSORT} ${SORT_ARG} {N} ${SORT_SEED}'
	${HYPERFINE}/msort_speedup.json '${MSORT} ${SORT_ARG} {N} ${SORT_SEED}'
	${PYTHON} scripts/plot_speedup.py --cpus=${NUM_CPUS} -o ./results/speedup.png

HYPERFINE_FIB = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} -P N 20 50 -D 5 --cleanup 'sleep ${SLEEP_TIME}' --export-json results

fib_ex: results build 
	${HYPERFINE_FIB}/fib_par.json '${FIB_PAR} {N} ${NUM_CPUS}' 
	${HYPERFINE_FIB}/fib_seq.json '${FIB_SEQ} {N}' 
	${HYPERFINE_FIB}/fib_inet.json '${FIB} {N} ${NUM_CPUS}'
	${PYTHON} scripts/plot_fib_ex.py -o ./results/fib_ex.png

perf: results build 
	bash scripts/run_cache_analysis.sh ${NUM_CPUS} ${NUM_RUNS} ${FIB_ARG} ${SORT_ARG} ${SORT_SEED}
	${PYTHON} scripts/plot_cpu_migrations.py --cpus=${NUM_CPUS} -o ./results/cpu_migrations.png
	
speedup_perf: perf 
	${PYTHON} scripts/plot_speedup_perf.py --cpus=${NUM_CPUS} -o ./results/speedup_perf.png 

HYPERFINE_TOOL = hyperfine -r ${NUM_RUNS} --warmup ${NUM_WARMUP} --cleanup 'sleep ${SLEEP_TIME}' --export-json results

tool_comparison: results build 
	${HYPERFINE_TOOL}/fib_inpla_20.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${INPLA} -t ${NUM_CPUS} -f ./benchmarks/Inpla/fib20.in'"
	${HYPERFINE_TOOL}/fib_inpla_25.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${INPLA} -t ${NUM_CPUS} -f ./benchmarks/Inpla/fib25.in'"
	${HYPERFINE_TOOL}/fib_inpla_30.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${INPLA} -t ${NUM_CPUS} -f ./benchmarks/Inpla/fib30.in'"
	${HYPERFINE_TOOL}/fib_inpla_35.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${INPLA} -t ${NUM_CPUS} -f ./benchmarks/Inpla/fib35.in'"
	${HYPERFINE_TOOL}/fib_inet_20.json "timeout ${TOOLS_TIMEOUT} sh -c '${FIB_INET_SIMP} 20 ${NUM_CPUS}'"
	${HYPERFINE_TOOL}/fib_inet_25.json "timeout ${TOOLS_TIMEOUT} sh -c '${FIB_INET_SIMP} 25 ${NUM_CPUS}'"
	${HYPERFINE_TOOL}/fib_inet_30.json "timeout ${TOOLS_TIMEOUT} sh -c '${FIB_INET_SIMP} 30 ${NUM_CPUS}'"
	${HYPERFINE_TOOL}/fib_inet_35.json "timeout ${TOOLS_TIMEOUT} sh -c '${FIB_INET_SIMP} 35 ${NUM_CPUS}'"
	${HYPERFINE_TOOL}/fib_hinets_20.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${HINETS} +RTS -N${NUM_CPUS} -H8G -M8G -RTS ./benchmarks/RunInets/fibonacci20.inet'"
	${HYPERFINE_TOOL}/fib_hinets_25.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${HINETS} +RTS -N${NUM_CPUS} -H8G -M8G -RTS ./benchmarks/RunInets/fibonacci25.inet'"
	${HYPERFINE_TOOL}/fib_hinets_30.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${HINETS} +RTS -N${NUM_CPUS} -H8G -M8G -RTS ./benchmarks/RunInets/fibonacci30.inet'"
	${HYPERFINE_TOOL}/fib_hinets_35.json -i "timeout ${TOOLS_TIMEOUT} sh -c '${HINETS} +RTS -N${NUM_CPUS} -H8G -M8G -RTS ./benchmarks/RunInets/fibonacci35.inet'"
	${PYTHON} scripts/plot_tool_comparison.py -o ./results/tool_comparison.png

results: 
	mkdir results 

clean: 
	rm -rf results 
	dune clean 

build: 
	dune build 
