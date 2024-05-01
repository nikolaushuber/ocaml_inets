import matplotlib.pyplot as plt 
from matplotlib.transforms import Affine2D
import argparse 
import numpy as np 
import re 

cpus = 8 
runs = 10 

parser = argparse.ArgumentParser()
parser.add_argument("--cpus", type = int, default = 8) 
parser.add_argument("-r", "--runs", type = int, default = 10)

args = parser.parse_args() 

x = [x for x in range(1, args.cpus + 1)]
xticks = [str(x) for x in x]

def data_of_file(file): 
    with open (file) as f: 
        res = f.read() 

    res = re.findall("\d+\s+cpu-migrations", res) 
    res = [float(re.search("\d+", x).group()) for x in res] 

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

ax = plt.gca() 

trans1 = Affine2D().translate(-0.1, 0.0) + ax.transData 
trans2 = Affine2D().translate(0.1, 0.0) + ax.transData 

plt.errorbar(x, fib_mean, fib_std, marker="o", linestyle="none", solid_capstyle='projecting', capsize=5, label="Fib", transform=trans1)
plt.errorbar(x, q_mean, q_std, marker="o", linestyle="none", solid_capstyle='projecting', capsize=5, label="Quicksort")
plt.errorbar(x, m_mean, m_std, marker="o", linestyle="none", solid_capstyle='projecting', capsize=5, label="Mergesort", transform=trans2)

plt.legend()
plt.xlim([0, args.cpus+1])
plt.xticks(x, label=xticks)

plt.show()