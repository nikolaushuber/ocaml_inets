module P = Moonpool.Ws_pool
module R = Moonpool.Runner 
module F = Moonpool.Fut 

type pos = |
type neg = |

type (_, _) agent = 
  | QSort : (int list, neg) agent -> (int list, neg) agent 
  | Part : int * (int list, neg) agent * (int list, neg) agent -> (int list, neg) agent
  | Append : (int list, neg) agent * (int list, pos) agent -> (int list, neg) agent 
  | LNil : ('a list, pos) agent 
  | LCons : int * (int list, pos) agent -> (int list, pos) agent  
  | NamePos : ('a, pos) agent F.t -> ('a, pos) agent 
  | NameNeg : ('a, pos) agent F.promise -> ('a, neg) agent 

let mk_Name () = 
  let future, promise = F.make () in 
  NamePos future, NameNeg promise

let rec encode_list = function 
| [] -> LNil 
| x :: xs -> LCons (x, encode_list xs) 

let rec decode_list = function 
  | LNil -> [] 
  | LCons (x, xs) -> x :: decode_list xs 
  | NamePos v -> decode_list (F.wait_block_exn v)

let apply_rule pool a1 a2 =
  let rec apply_rule : type a. (a, pos) agent -> (a, neg) agent -> unit = 
    fun a1 a2 -> match a1, a2 with 
    | LNil, QSort ret -> LNil -- ret 
    | LCons (x, xs), QSort ret -> 
      let right_pos, right_neg = mk_Name () in 
      let smaller = QSort (Append (ret, LCons (x, right_pos))) in 
      let larger = QSort (right_neg) in 
      xs -- (Part (x, smaller, larger)) 
    | LNil, Part (_, a, b) -> LNil -- a; LNil -- b 
    | LCons (y, ys), Part (x, smaller, larger) when y < x -> 
      let cnt_pos, cnt_neg = mk_Name () in 
      (LCons (y, cnt_pos)) -- smaller; 
      ys -- (Part (x, cnt_neg, larger)) 
    | LCons (y, ys), Part (x, smaller, larger) -> 
      let cnt_pos, cnt_neg = mk_Name () in 
      (LCons (y, cnt_pos)) -- larger; 
      ys -- (Part (x, smaller, cnt_neg))
    | LNil, Append (ret, listB) -> listB -- ret 
    | LCons (x, xs), Append (ret, listB) -> 
      let cnt_pos, cnt_neg = mk_Name () in 
      (LCons (x, cnt_pos)) -- ret; 
      xs -- (Append (cnt_neg, listB)) 
    | NamePos v, a -> F.on_result v (fun a' -> (Result.get_ok a') -- a)  
    | a, NameNeg v -> F.fulfill v (Ok a)

  and ( -- ) : type a. (a, pos) agent -> (a, neg) agent -> unit  = 
    fun a1 a2 ->
    R.run_async pool (fun _ -> apply_rule a1 a2)
  in

  a1 -- a2 

let qsort pool l = 
  let l_agent = encode_list l in 
  let ret_pos, ret_neg = mk_Name () in 
  R.run_async pool (fun _ -> apply_rule pool l_agent (QSort ret_neg)); 
  decode_list ret_pos 

let rec is_sorted x = match x with
| [] -> true
| _::[] -> true
| h::h2::t -> if h <= h2 then is_sorted (h2::t) else false

let n = 
  try int_of_string @@ Sys.argv.(1) with _ -> 1000

let num_threads = 
  try int_of_string @@ Sys.argv.(2) with _ -> 1 

let pool = P.create ~num_threads () 

let () = 
  Random.self_init ();
  let l = List.init n (fun _ -> Random.full_int Int.max_int) in
  let ret = qsort pool l in  
  if not (is_sorted ret) then exit (-1); 
  () 
