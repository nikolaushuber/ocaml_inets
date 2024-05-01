import matplotlib.pyplot as plt 
import argparse 
import numpy as np 
import re 

parser = argparse.ArgumentParser()
parser.add_argument("--cpus", type = int, default = 8) 
parser.add_argument("-r", "--runs", type = int, default = 10) 
parser.add_argument("--dpi", type = int, default =  600)
parser.add_argument("-o", "--output")

args = parser.parse_args() 

x = [x for x in range(1, args.cpus + 1)]
xticks = [str(x) for x in x]

def data_of_file(file): 
    with open (file) as f: 
        res = f.read() 

    res = re.findall("(\d+,\d+%)", res)
    res = [float(r.replace(",",".").strip("%")) for r in res]

    data = np.array(res) 
    datas = np.split(data, args.cpus)

    mean = [] 
    std = [] 

    for d in datas:  
        mean.append(np.mean(d)) 
        std.append(np.std(d)) 

    return mean, std 

fib_mean, fib_std = data_of_file('./results/fib_cache.txt')
q_mean, q_std = data_of_file('./results/qsort_cache.txt')
m_mean, m_std = data_of_file('./results/msort_cache.txt')

plt.figure (figsize=(10,6))

plt.errorbar(x, fib_mean, fib_std, solid_capstyle='projecting', capsize=5, label="Fib")
plt.errorbar(x, q_mean, q_std, solid_capstyle='projecting', capsize=5, label="Quicksort")
plt.errorbar(x, m_mean, m_std, solid_capstyle='projecting', capsize=5, label="Mergesort")

plt.legend()
plt.xlim([0, args.cpus+1])
plt.xticks(x, label=xticks)

if args.output: 
    plt.savefig(args.output, dpi=args.dpi) 
else: 
    plt.show()