type 'a promise = 'a Moonpool.Fut.t 
type 'a resolver = 'a Moonpool.Fut.promise 
let resolve v a = Moonpool.Fut.fulfill v (Ok a)
let await v = Moonpool.Fut.wait_block_exn v 
let make_future () = Moonpool.Fut.make () 
let create_pool num_threads = Moonpool.Ws_pool.create ~num_threads () 
let run_async pool f = Moonpool.Runner.run_async pool f 

let n = try int_of_string @@ Sys.argv.(1) with _ -> 10 
let num_threads = try int_of_string @@ Sys.argv.(2) with _ -> 1 

let pool = create_pool num_threads 

type pos = |
type neg = | 

type (_, _) agent = 
  | Int : int -> (int, pos) agent 
  | Add : (int, neg) agent * (int, pos) agent -> (int, neg) agent 
  | AddAux : int * (int, neg) agent -> (int, neg) agent 
  | Fib : (int, neg) agent -> (int, neg) agent 
  | NamePos : ('a, pos) agent promise -> ('a, pos) agent 
  | NameNeg : ('a, pos) agent resolver -> ('a, neg) agent 

let new_name () = 
  let promise, resolver = make_future () in 
  NamePos promise, NameNeg resolver

let rec fib_seq = function 
  | 0 -> 0 
  | 1 -> 1 
  | n -> fib_seq (n-1) + fib_seq (n-2) 

let rec apply_rule : type a. (a, pos) agent -> (a, neg) agent -> unit = 
  fun a1 a2 -> match a1, a2 with 
  | Int n, Add (r, b) -> b -><- AddAux (n, r) 
  | Int (m), AddAux (n, r) -> Int (n + m) -><- r  
  | Int n, Fib r when n = 0 -> Int 0 -><- r 
  | Int n, Fib r when n = 1 -> Int 1 -><- r 
  | Int n, Fib r when n <= 20 -> Int (fib_seq n) -><- r 
  | Int n, Fib r -> 
    let cnt_pos, cnt_neg = new_name () in 
    Int (n-1) -><- Fib (Add(r, cnt_pos)); 
    Int (n-2) -><- Fib cnt_neg 
  | NamePos v, a -> await v -><- a
  | a, NameNeg v -> resolve v a

and ( -><- ) : type a. (a, pos) agent -> (a, neg) agent -> unit  = 
  fun a1 a2 ->
    run_async pool (fun _ -> apply_rule a1 a2) 

let rec decode_int = function 
  | Int n -> n 
  | NamePos v -> decode_int (await v) 

let fib n = 
  let ret_pos, ret_neg = new_name () in 
  Int n -><- Fib ret_neg;
  decode_int ret_pos  

let () = 
  fib n
  |> string_of_int
  |> print_endline
  