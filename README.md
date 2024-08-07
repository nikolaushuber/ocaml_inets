# Interaction Nets in OCaml 

[![DOI](https://zenodo.org/badge/791889944.svg)](https://zenodo.org/doi/10.5281/zenodo.12633476)

Interaction nets are a visual programming language built upon graph rewriting. This project holds the code for example nets encoded in the OCaml programming language. You can find the encoded examples in the `/examples` folder. 

## Publication

This repository is a companion to the following paper: 

An Encoding of Interaction Nets in OCaml, 
Nikolaus Huber & Wang Yi 
(GCM 2024)

## Getting started 

In order to use the provided code you need to install a compatible OCaml environment. The easiest way of doing so is with [opam](https://opam.ocaml.org): 

```bash
git clone https://github.com/nikolaushuber/ocaml_inets.git 
cd ocaml_inets 
opam switch create . -y  
dune build 
```

You can now run the built examples: 

```bash 
./_build/default/examples/fib.exe <n> <num domains> 
./_build/default/examples/qsort.exe <list size> <num domains> <seed> 
./_build/default/examples/msort.exe <list size> <num domains> <seed> 
```

## Recreating the graphs from the paper 

In order to recreate the benchmark graphs from the paper you will need the following software packages installed: 

- python + matplotlib + numpy 
- make 
- bash 
- hyperfine 
- perf 

If all of the above are installed, you can issue 

```bash 
make benchmark 
```

in the root of this repository. This will create a folder `results` holding all the images. You may have to first adapt the values in the beginning of `Makefile` to fit your particular processor. 

If you would like to recreate the tool comparison graph, you can issue 

```bash 
make tool_comparison 
``` 

in the root of this repository. This needs inpla and HINet installed (see below). 
You will also have to change the paths to those programs in the beginning of `Makefile`. 

## License 

MIT. Benchmark inputs for inpla and HINet are under their own licenses, a copy is in the respective folder. 

## Other interaction net projects 

- [inpla](https://github.com/inpla/inpla/), currently the most performant general interaction net evaluator 
- [ingpu](https://github.com/euschn/ingpu), an interaction evaluator using GPUs. Needs all interaction rules encoded as CUDA kernels 
- [HINet](http://www.cas.mcmaster.ca/~kahl/Haskell/HINet/), an interaction net evaluator written in Haskell 
- [HVM](https://github.com/HigherOrderCO/HVM), a virtual machine written in Rust designed to execute interaction nets 
