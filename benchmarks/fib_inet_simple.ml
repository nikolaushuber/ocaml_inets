module P = Moonpool.Ws_pool
module R = Moonpool.Runner 
module F = Moonpool.Fut 

type pos = |
type neg = | 

type (_, _) agent = 
  | Int : int -> (int, pos) agent 
  | Add : (int, neg) agent * (int, pos) agent -> (int, neg) agent 
  | AddAux : int * (int, neg) agent -> (int, neg) agent 
  | Fib : (int, neg) agent -> (int, neg) agent 
  | NamePos : ('a, pos) agent F.t -> ('a, pos) agent 
  | NameNeg : ('a, pos) agent F.promise -> ('a, neg) agent 

let mk_Name () = 
  let future, promise = F.make () in 
  NamePos future, NameNeg promise

let apply_rule pool a1 a2 =
  let rec apply_rule : type a. (a, pos) agent -> (a, neg) agent -> unit = 
    fun a1 a2 -> match a1, a2 with 
    | Int n, Add (r, b) -> b -><- AddAux (n, r) 
    | Int (m), AddAux (n, r) -> Int (n + m) -><- r  
    | Int n, Fib r when n = 0 -> Int 0 -><- r 
    | Int n, Fib r when n = 1 -> Int 1 -><- r 
    | Int n, Fib r -> 
      let cnt_pos, cnt_neg = mk_Name () in 
      Int (n-1) -><- Fib (Add(r, cnt_pos)); 
      Int (n-2) -><- Fib cnt_neg 
    | NamePos v, a -> F.on_result v (fun a' -> Result.get_ok a' -><- a)  
    | a, NameNeg v -> F.fulfill v (Ok a)

  and ( -><- ) : type a. (a, pos) agent -> (a, neg) agent -> unit  = 
    fun a1 a2 ->
    R.run_async pool (fun _ -> apply_rule a1 a2) 
  in

  a1 -><- a2 

let rec decode_int = function 
  | Int n -> n 
  | NamePos v -> decode_int (F.wait_block_exn v) 

let fib pool n = 
  let ret_pos, ret_neg = mk_Name () in 
  R.run_async pool (fun _ -> apply_rule pool (Int n) (Fib ret_neg));
  decode_int ret_pos  

let n = 
  try int_of_string @@ Sys.argv.(1) with _ -> 10 

let num_threads = 
  try int_of_string @@ Sys.argv.(2) with _ -> 1 

let pool = P.create ~num_threads ()  

let () = 
  let ret = fib pool n in  
  ret |> string_of_int |> print_endline
  