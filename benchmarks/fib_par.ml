open Moonpool 

let n = try int_of_string Sys.argv.(1) with _ -> 10 
let num_threads = 
  try int_of_string @@ Sys.argv.(2) with _ -> Domain.recommended_domain_count ()

let pool = Ws_pool.create ~num_threads () 

let rec fib_seq = function 
  | 0 -> 0 
  | 1 -> 1 
  | n -> fib_seq (n-1) + fib_seq (n-2) 

let rec fib_par n =
  if n <= 20 then 
    Fut.spawn ~on:pool (fun _ -> fib_seq n)
  else
    Fut.spawn ~on:pool (fun _ -> 
      let a = fib_par (n-1) in 
      let b = fib_par (n-2) in
      Fut.await a + Fut.await b    
    )

let () =
  Fut.wait_block_exn (fib_par n) 
  |> string_of_int 
  |> print_endline
