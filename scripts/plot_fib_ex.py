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
    return x, mean  

x_seq, mean_seq = get_res("./results/fib_seq.json") 
x_par, mean_par = get_res("./results/fib_par.json") 
x_inet, mean_inet = get_res("./results/fib_inet.json") 

plt.figure() 

plt.yscale("log") 

plt.plot(x_seq, mean_seq, label="Sequential", linestyle="-")
plt.plot(x_par, mean_par, label="Parallel", linestyle="--")
plt.plot(x_inet, mean_inet, label="Interaction Net", linestyle=":")

plt.ylabel("Runtime [s]") 
plt.xlabel("n")

plt.legend()

plt.savefig("./results/fib_ex.png", dpi = 600)
