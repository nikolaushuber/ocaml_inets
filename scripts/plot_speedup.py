import json 
import matplotlib.pyplot as plt 

def get_res(fname): 
    with open (fname) as f: 
        res = json.load(f)["results"] 
        x = [] 
        mean = [] 
        for r in res: 
            x.append(int(r["parameters"]["N"])) 
            mean.append(r["median"]) 

        speedup = [] 
        for m in mean: 
            speedup.append(mean[0] / m) 
    
    return (x, speedup) 

x_fib, su_fib = get_res('./results/fib38.json') 
x_qsort, su_qsort = get_res('./results/qsort_10000.json')
x_msort, su_msort = get_res('./results/msort_10000.json') 
x_qsort_arr, su_qsort_arr = get_res('./results/qsort_array_500000.json')

plt.figure(figsize=(10,6))

plt.plot(x_fib, su_fib, label = "Fib 38", linestyle = "-")
plt.plot(x_qsort, su_qsort, label = "QSort 10000", linestyle = "--") 
plt.plot(x_msort, su_msort, label = "MSort 10000", linestyle = ":") 
plt.plot(x_qsort_arr, su_qsort_arr, label = "QSort(Array) 500000", linestyle = "-.")

plt.ylabel("Speed-up ratio") 
plt.xlabel("# threads in pool") 

plt.ylim(1, 5)
plt.xlim(1, 9)

plt.legend() 
plt.savefig("./results/speedup.png", dpi = 600)
