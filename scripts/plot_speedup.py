import json 
import matplotlib.pyplot as plt 
import argparse 

parser = argparse.ArgumentParser() 
parser.add_argument("-o", "--output", help = "Save image to the given filename") 
parser.add_argument("--dpi", help = "Set dpi when saving to image", type = int, default = 600) 
parser.add_argument("--cpus", help = "Set CPU count", type = int, default = 8)
parser.add_argument("--measurement", help = "Select which value to use for speedup calculation (min, mean, median)", default = "mean")

args = parser.parse_args() 

def get_res(fname): 
    with open (fname) as f: 
        res = json.load(f)["results"] 
        x = [] 
        mean = [] 
        for r in res: 
            x.append(int(r["parameters"]["N"])) 
            mean.append(r[args.measurement]) 

        speedup = [] 
        for m in mean: 
            speedup.append(mean[0] / m) 
    
    return (x, speedup) 

x_fib, su_fib = get_res('./results/fib_hyperfine.json') 
x_qsort, su_qsort = get_res('./results/qsort_hyperfine.json')
x_msort, su_msort = get_res('./results/msort_hyperfine.json') 
# x_qsort_arr, su_qsort_arr = get_res('./results/qsort_array_500000.json')

plt.figure(figsize=(10,6))

plt.plot(x_fib, su_fib, label = "Fib", linestyle = "-")
plt.plot(x_qsort, su_qsort, label = "Quicksort", linestyle = "--") 
plt.plot(x_msort, su_msort, label = "Mergesort", linestyle = ":") 
# plt.plot(x_qsort_arr, su_qsort_arr, label = "QSort(Array) 500000", linestyle = "-.")

plt.ylabel("Speed-up ratio") 
plt.xlabel("# threads in pool") 

# plt.ylim(1, 5)
plt.xlim(1, args.cpus)
plt.xticks(x_fib, labels = [str(x) for x in x_fib])

plt.legend() 

if args.output: 
    plt.savefig(args.output, dpi = args.dpi)
else:
    plt.show() 
