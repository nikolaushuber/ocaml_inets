import json 
import matplotlib.pyplot as plt 
import numpy as np 
import argparse 

results_path = './results/'

parser = argparse.ArgumentParser()
parser.add_argument("--dpi", type = int, default =  600)
parser.add_argument("-o", "--output")

args = parser.parse_args() 

def get_mean_and_stddev (filename): 
    with open (results_path + filename) as f: 
        res = json.load(f)["results"][0]
        mean = res["mean"] 
        stdd = res["stddev"] 
    
    return mean, stdd 


inet_20_mean, inet_20_dev = get_mean_and_stddev('fib_inet_20.json')
inet_25_mean, inet_25_dev = get_mean_and_stddev('fib_inet_25.json')
inet_30_mean, inet_30_dev = get_mean_and_stddev('fib_inet_30.json')
inet_35_mean, inet_35_dev = get_mean_and_stddev('fib_inet_35.json')

inet_mean = [inet_20_mean, inet_25_mean, inet_30_mean, inet_35_mean]

nd_20_mean, nd_20_dev = get_mean_and_stddev('fib_hinets_20.json')
nd_25_mean, nd_25_dev = get_mean_and_stddev('fib_hinets_25.json')
nd_30_mean, nd_30_dev = get_mean_and_stddev('fib_hinets_30.json')

hinets_mean = [nd_20_mean, nd_25_mean, nd_30_mean, 0.0] 

inpla_20_mean, inpla_20_dev = get_mean_and_stddev('fib_inpla_20.json')
inpla_25_mean, inpla_25_dev = get_mean_and_stddev('fib_inpla_25.json')
inpla_30_mean, inpla_30_dev = get_mean_and_stddev('fib_inpla_30.json')
inpla_35_mean, inpla_35_dev = get_mean_and_stddev('fib_inpla_35.json')

inpla_mean = [inpla_20_mean, inpla_25_mean, inpla_30_mean, inpla_35_mean]

width = 0.2
x = np.arange(4)
xlabels = ['20', '25', '30', '35']

fix, ax = plt.subplots() 

plt.yscale("log")

p = ax.bar(x-width, inpla_mean, width, label='Inpla') 
ax.bar_label(p, fmt='%.3f', rotation=90, padding=3, fontsize = 12)
p = ax.bar(x, inet_mean, width, label='OCaml') 
ax.bar_label(p, fmt='%.3f', rotation=90, padding=3, fontsize = 12)
p = ax.bar(x+width, hinets_mean, width, label='HINet') 
ax.bar_label(p, fmt='%.3f', rotation=90, padding=3, fontsize = 12)

ax.legend(loc = 'upper left', fontsize = 12) 

plt.ylabel("Runtime [s]", fontsize = 15, fontweight = 'bold')
plt.xlabel("n", fontsize = 15, fontweight = 'bold')

ax.spines['top'].set_visible(False)
ax.spines['right'].set_visible(False)


plt.xticks(x, xlabels, fontsize = 12) 
plt.yticks(fontsize = 12)

if args.output: 
    plt.savefig(args.output, dpi = args.dpi, bbox_inches='tight')
else:
    plt.show() 