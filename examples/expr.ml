[@@@ocaml.warning "-37-32-34"]

type 'a promise = 'a Moonpool.Fut.t 
type 'a resolver = 'a Moonpool.Fut.promise 
let resolve v a = Moonpool.Fut.fulfill v (Ok a)
let await v c = Moonpool.Fut.on_result v (fun a -> c (Result.get_ok a))
let make_future () = Moonpool.Fut.make () 
let create_pool num_threads = Moonpool.Ws_pool.create ~num_threads () 
let run_async pool f = Moonpool.Runner.run_async pool f 


type pos = | 
type neg = | 

type (_, _) agent =
  | Int : int -> (int, pos) agent 
  | IsEven : (bool, neg) agent -> (int, neg) agent  
  | T : (bool, pos) agent 
  | F : (bool, pos) agent 
  | And : (bool, neg) agent * (bool, pos) agent -> (bool, neg) agent 
  | If : ('a, neg) agent * ('a, pos) agent * ('a, pos) agent -> (bool, neg) agent 
  | NamePos : ('a, pos) agent promise -> ('a, pos) agent 
  | NameNeg : ('a, pos) agent resolver -> ('a, neg) agent

let new_name () = 
  let promise, resolver = make_future () in 
  NamePos promise, NameNeg resolver 

let num_threads = 
  try int_of_string @@ Sys.argv.(2) with _ -> 1 

let pool = create_pool num_threads 

let rec apply_rule : type a. (a, pos) agent -> (a, neg) agent -> unit = 
  fun a1 a2 -> match a1, a2 with 
  | T, And (r, b)                     -> b -><- r 
  | F, And (r, b)                     -> ignore b; F -><- r 
  | Int n, IsEven r when n mod 2 = 0  -> T -><- r 
  | Int _, IsEven r                   -> F -><- r  
  | T, If (r, t, e)                   -> ignore e; t -><- r 
  | F, If (r, t, e)                   -> ignore t; e -><- r
  | NamePos v, a                      -> await v (fun b -> b -><- a)  
  | a, NameNeg v                      -> resolve v a

and ( -><- ) : type a. (a, pos) agent -> (a, neg) agent -> unit = 
  fun a1 a2 -> 
    run_async pool (fun _ -> apply_rule a1 a2)

let rec decode_int = function 
  | Int n -> n  
  | NamePos v -> decode_int (Moonpool.Fut.wait_block_exn v) 
  
