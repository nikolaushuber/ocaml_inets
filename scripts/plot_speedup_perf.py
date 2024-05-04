import matplotlib.pyplot as plt 
import argparse 
import numpy as np 
import re 

parser = argparse.ArgumentParser()
parser.add_argument("--cpus", type = int, default = 8) 
parser.add_argument("-o", "--output") 
parser.add_argument("--dpi", type = int)

args = parser.parse_args() 

x = [x for x in range(1, args.cpus + 1)]
xticks = [str(x) for x in x]

def data_of_file(file): 
    with open (file) as f: 
        res = f.read() 

    res = re.findall("\d+,\d+\s+seconds\s+time\s+elapsed", res)
    res = [float(re.search("\d+,\d+", x).group().replace(",",".")) for x in res] 

    data = np.array(res) 
    datas = np.split(data, args.cpus)

    mean = [] 

    for d in datas:  
        mean.append(np.mean(d)) 
 
    speedup = []
    for m in mean: 
        speedup.append(mean[0] / m)

    return speedup

fib_speedup = data_of_file('./results/fib_cache.txt')
q_speedup = data_of_file('./results/qsort_cache.txt')
m_speedup = data_of_file('./results/msort_cache.txt')

plt.figure(figsize=(10,6))

plt.plot(x, fib_speedup, label = "Fib", linestyle = "-", linewidth=2.0)
plt.plot(x, q_speedup, label = "Quicksort", linestyle = "--", linewidth=2.0) 
plt.plot(x, m_speedup, label = "Mergesort", linestyle = ":", linewidth=2.0) 

plt.ylabel("Speed-up ratio", fontsize=15, fontweight='bold') 
plt.xlabel("# threads in pool", fontsize=15, fontweight='bold') 

plt.xlim(0, args.cpus + 1)
plt.xticks(x, labels = xticks, fontsize=12) 
plt.yticks(fontsize=12)

plt.legend(loc = 'upper left', fontsize = 12)

if args.output: 
    plt.savefig(args.output, dpi = args.dpi, bbox_inches = 'tight')
else:
    plt.show() 