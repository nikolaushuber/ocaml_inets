type 'a promise = 'a Moonpool.Fut.t 
type 'a resolver = 'a Moonpool.Fut.promise 
let resolve v a = Moonpool.Fut.fulfill v (Ok a)
let await v = Moonpool.Fut.await v 
let block v = Moonpool.Fut.wait_block_exn v 
let make_future () = Moonpool.Fut.make () 
let create_pool num_threads = Moonpool.Ws_pool.create ~num_threads () 
let run_async pool f = Moonpool.Runner.run_async pool f 

let n = try int_of_string @@ Sys.argv.(1) with _ -> 10 
let num_threads = try int_of_string @@ Sys.argv.(2) with _ -> 1 
let () = 
  try 
    let seed = int_of_string @@ Sys.argv.(3) in 
    Random.init seed 
  with _ -> Random.self_init () 

let pool = create_pool num_threads  

type pos = |
type neg = |

type (_, _) agent = 
  | MSort : (int list, neg) agent -> (int list, neg) agent 
  | MSort_tail : int * (int list, neg) agent -> (int list, neg) agent 
  | Merge : (int list, neg) agent * (int list, pos) agent -> (int list, neg) agent 
  | MergeCC : int * (int list, neg) agent * (int list, pos) agent -> (int list, neg) agent 
  | Split : (int list, neg) agent * (int list, neg) agent -> (int list, neg) agent 
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
  | NamePos v -> decode_list (block v)

let rec apply_rule : type a. (a, pos) agent -> (a, neg) agent -> unit = 
  fun a1 a2 -> match a1, a2 with 
  (* [] >< MSort(ret) => [] ~ ret *)
  | LNil, MSort ret -> LNil -><- ret 

  (* x :: xs >< MSort (ret) => xs ~ MSort_tail[x](ret)*)
  | LCons (x, xs), MSort ret -> xs -><- MSort_tail (x, ret)

  (* [] >< MSort_tail[n](ret) => [n] ~ ret *)
  | LNil, MSort_tail (n, ret) -> LCons (n, LNil) -><- ret 

  (* x :: xs >< MSort_tail[n](ret) => 
      n :: x :: xs ~ split(left, right), 
      MSort(a) ~ left, 
      MSort(b) ~ right, Merge(ret, b) ~ a 
  *)
  | LCons (x, xs), MSort_tail (n, ret) -> 
    let b_pos, b_neg = new_name () in 
    let a = Merge (ret, b_pos) in 
    let left = MSort a in 
    let right = MSort b_neg in 
    LCons (n, LCons (x, xs)) -><- Split (left, right)

  (* [] >< Merge(ret, snd) => snd ~ ret *)
  | LNil, Merge (ret, snd) -> snd -><- ret 

  (* x :: xs >< Merge(ret, snd) => snd ~ MergeCC[x](ret, xs)*)
  | LCons (x, xs), Merge (ret, snd) -> snd -><- MergeCC (x, ret, xs)

  (* [] >< MergeCC[y](ret, ys) => y :: ys ~ ret *)
  | LNil, MergeCC (y, ret, ys) -> LCons (y, ys) -><- ret

  (* x :: xs >< MergeCC (y, ret, ys) 
      | x <= y  => x :: cnt ~ ret, xs ~ MergeCC[y](cnt, ys)
      | _       => y :: cnt ~ ret, ys ~ MergeCC[x](cnt, xs)  
  *)
  | LCons (x, xs), MergeCC (y, ret, ys) when x <= y -> 
    let cnt_pos, cnt_neg = new_name () in 
    LCons (x, cnt_pos) -><- ret ; 
    xs -><- MergeCC (y, cnt_neg, ys)

  | LCons (x, xs), MergeCC (y, ret, ys) -> 
    let cnt_pos, cnt_neg = new_name () in 
    (LCons (y, cnt_pos)) -><- ret; 
    ys -><- MergeCC (x, cnt_neg, xs) 

  (* [] >< Split(right, left) => [] ~ right, [] ~ left *)
  | LNil, Split (right, left) -> LNil -><- right; LNil -><- left 

  (* x :: xs >< Split(right, left) => 
      x :: cnt ~ right, xs ~ Split (left, cnt) 
  *)
  | LCons (x, xs), Split (right, left) -> 
    let cntl_pos, cntl_neg = new_name () in 
    LCons (x, cntl_pos) -><- right; 
    xs -><- Split (left, cntl_neg) 

  (* Name handling *)
  | NamePos v, a -> await v -><- a  
  | a, NameNeg v -> resolve v a

and ( -><- ) : type a. (a, pos) agent -> (a, neg) agent -> unit  = 
  fun a1 a2 ->
    run_async pool (fun _ -> apply_rule a1 a2)

let msort l = 
  let l_agent = encode_list l in 
  let ret_pos, ret_neg = new_name () in 
  l_agent -><- MSort ret_neg; 
  decode_list ret_pos 

let rec is_sorted x = match x with
  | [] -> true
  | _ :: [] -> true
  | h :: h2 :: t -> if h <= h2 then is_sorted (h2 :: t) else false


let () = 
  let l = List.init n (fun _ -> Random.full_int Int.max_int) in
  let ret = msort l in  
  if not (is_sorted ret) then exit (-1); 
  () 
