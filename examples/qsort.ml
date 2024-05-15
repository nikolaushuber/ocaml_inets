type 'a promise = 'a Moonpool.Fut.t 
type 'a resolver = 'a Moonpool.Fut.promise 
let resolve v a = Moonpool.Fut.fulfill v (Ok a)
let await v c = Moonpool.Fut.on_result v (fun a -> c (Result.get_ok a))
let await_val v = Moonpool.Fut.wait_block_exn v 
let make_future () = Moonpool.Fut.make () 
let create_pool num_threads = Moonpool.Ws_pool.create ~num_threads () 
let run_async pool f = Moonpool.Runner.run_async pool f 

let n = try int_of_string @@ Sys.argv.(1) with _ -> 1000
let num_threads = try int_of_string @@ Sys.argv.(2) with _ -> 1 

let pool = create_pool num_threads 

type pos = |
type neg = |

type (_, _) agent = 
  | QSort : (int list, neg) agent -> (int list, neg) agent 
  | Part : int * (int list, neg) agent * (int list, neg) agent -> (int list, neg) agent
  | Append : (int list, neg) agent * (int list, pos) agent -> (int list, neg) agent 
  | LNil : ('a list, pos) agent 
  | LCons : int * (int list, pos) agent -> (int list, pos) agent  
  | NamePos : ('a, pos) agent promise -> ('a, pos) agent 
  | NameNeg : ('a, pos) agent resolver -> ('a, neg) agent 

let new_name () = 
  let future, promise = make_future () in 
  NamePos future, NameNeg promise

let rec encode_list = function 
| [] -> LNil 
| x :: xs -> LCons (x, encode_list xs) 

let rec decode_list = function 
  | LNil -> [] 
  | LCons (x, xs) -> x :: decode_list xs 
  | NamePos v -> decode_list (await_val v)

let rec apply_rule : type a. (a, pos) agent -> (a, neg) agent -> unit = 
  fun a1 a2 -> match a1, a2 with 
  | LNil, QSort ret -> LNil -><- ret 
  | LCons (x, xs), QSort ret -> 
    let right_pos, right_neg = new_name () in 
    let smaller = QSort (Append (ret, LCons (x, right_pos))) in 
    let larger = QSort (right_neg) in 
    xs -><- (Part (x, smaller, larger)) 
  | LNil, Part (_, a, b) -> LNil -><- a; LNil -><- b 
  | LCons (y, ys), Part (x, smaller, larger) when y < x -> 
    let cnt_pos, cnt_neg = new_name () in 
    (LCons (y, cnt_pos)) -><- smaller; 
    ys -><- (Part (x, cnt_neg, larger)) 
  | LCons (y, ys), Part (x, smaller, larger) -> 
    let cnt_pos, cnt_neg = new_name () in 
    (LCons (y, cnt_pos)) -><- larger; 
    ys -><- (Part (x, smaller, cnt_neg))
  | LNil, Append (ret, listB) -> listB -><- ret 
  | LCons (x, xs), Append (ret, listB) -> 
    let cnt_pos, cnt_neg = new_name () in 
    (LCons (x, cnt_pos)) -><- ret; 
    xs -><- (Append (cnt_neg, listB)) 
  | NamePos v, a -> await v (fun a' -> a' -><- a)  
  | a, NameNeg v -> resolve v a

and ( -><- ) : type a. (a, pos) agent -> (a, neg) agent -> unit  = 
  fun a1 a2 ->
    run_async pool (fun _ -> apply_rule a1 a2)

let qsort l = 
  let l_agent = encode_list l in 
  let ret_pos, ret_neg = new_name () in 
  l_agent -><- QSort ret_neg; 
  decode_list ret_pos 

let rec is_sorted x = match x with
  | [] -> true
  | _ :: [] -> true
  | h :: h2 :: t -> if h <= h2 then is_sorted (h2 :: t) else false


let () = 
  try 
    let seed = int_of_string @@ Sys.argv.(3) in 
    Random.init seed 
  with _ -> Random.self_init () 

let () = 
  let l = List.init n (fun _ -> Random.full_int Int.max_int) in
  let ret = qsort l in
  if not (is_sorted ret) then exit (-1); 
  () 
