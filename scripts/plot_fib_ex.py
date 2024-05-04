import json 
import matplotlib.pyplot as plt 
import argparse 

parser = argparse.ArgumentParser()
parser.add_argument("--dpi", type = int, default =  600)
parser.add_argument("-o", "--output")

args = parser.parse_args() 

def get_res(fname): 
    with open (fname) as f: 
        res = json.load(f)["results"] 
        x = [] 
        mean = [] 
        for r in res: 
            x.append(int(r["parameters"]["N"])) 
            mean.append(r["median"]) 
    return x, mean  

x_seq, mean_seq = get_res("./results/fib_seq.json") 
x_par, mean_par = get_res("./results/fib_par.json") 
x_inet, mean_inet = get_res("./results/fib_inet.json") 

plt.figure() 

plt.yscale("log") 

plt.plot(x_seq, mean_seq, label="Sequential", linestyle="-", linewidth=2.0)
plt.plot(x_par, mean_par, label="Parallel", linestyle="--", linewidth=2.0)
plt.plot(x_inet, mean_inet, label="Interaction Net", linestyle=":", linewidth=2.0)

plt.ylabel("Runtime [s]", fontsize = 15, fontweight = 'bold') 
plt.xlabel("n", fontsize = 15, fontweight = 'bold')

plt.xticks(fontsize=12)
plt.yticks(fontsize=12)

plt.legend(loc = 'upper left', fontsize = 12)

if args.output: 
    plt.savefig(args.output, dpi = args.dpi, bbox_inches='tight')
else:
    plt.show() 
