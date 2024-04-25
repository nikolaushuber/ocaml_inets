module P = Moonpool.Ws_pool
module R = Moonpool.Runner 
module F = Moonpool.Fut 

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
    (* [] >< MSort(ret) => [] ~ ret *)
    | LNil, MSort ret -> LNil -- ret 

    (* x :: xs >< MSort (ret) => xs ~ MSort_tail[x](ret)*)
    | LCons (x, xs), MSort ret -> xs -- MSort_tail (x, ret)

    (* [] >< MSort_tail[n](ret) => [n] ~ ret *)
    | LNil, MSort_tail (n, ret) -> LCons (n, LNil) -- ret 

    (* x :: xs >< MSort_tail[n](ret) => 
        n :: x :: xs ~ split(left, right), 
        MSort(a) ~ left, 
        MSort(b) ~ right, Merge(ret, b) ~a 
    *)
    | LCons (x, xs), MSort_tail (n, ret) -> 
      let b_pos, b_neg = mk_Name () in 
      let a = Merge (ret, b_pos) in 
      let left = MSort a in 
      let right = MSort b_neg in 
      LCons (n, LCons (x, xs)) -- Split (left, right)

    (* [] >< Merge(ret, snd) => snd ~ ret *)
    | LNil, Merge (ret, snd) -> snd -- ret 

    (* x :: xs >< Merge(ret, snd) => snd ~ MergeCC[x](ret, xs)*)
    | LCons (x, xs), Merge (ret, snd) -> snd -- MergeCC (x, ret, xs)

    (* [] >< MergeCC[y](ret, ys) => y :: ys ~ ret *)
    | LNil, MergeCC (y, ret, ys) -> LCons (y, ys) -- ret

    (* x :: xs >< MergeCC (y, ret, ys) 
        | x <= y  => x :: cnt ~ ret, xs ~ MergeCC[y](cnt, ys)
        | _       => y :: cnt ~ ret, ys ~ MergeCC[x](cnt, xs)  
    *)
    | LCons (x, xs), MergeCC (y, ret, ys) when x <= y -> 
      let cnt_pos, cnt_neg = mk_Name () in 
      LCons (x, cnt_pos) -- ret ; 
      xs -- MergeCC (y, cnt_neg, ys)

    | LCons (x, xs), MergeCC (y, ret, ys) -> 
      let cnt_pos, cnt_neg = mk_Name () in 
      (LCons (y, cnt_pos)) -- ret; 
      ys -- MergeCC (x, cnt_neg, xs) 

    (* [] >< Split(right, left) => [] ~ right, [] ~ left *)
    | LNil, Split (right, left) -> LNil -- right; LNil -- left 

    (* x :: xs >< Split(right, left) => 
        x :: cnt ~ right, xs ~ Split (left, cnt) 
    *)
    | LCons (x, xs), Split (right, left) -> 
      let cntl_pos, cntl_neg = mk_Name () in 
      LCons (x, cntl_pos) -- right; 
      xs -- Split (left, cntl_neg) 

    (* Name handling *)
    | NamePos v, a -> F.on_result v (fun a' -> (Result.get_ok a') -- a)  
    | a, NameNeg v -> F.fulfill v (Ok a)

  and ( -- ) : type a. (a, pos) agent -> (a, neg) agent -> unit  = 
    fun a1 a2 ->
    R.run_async pool (fun _ -> apply_rule a1 a2)
  in

  a1 -- a2 

let msort pool l = 
  let l_agent = encode_list l in 
  let ret_pos, ret_neg = mk_Name () in 
  R.run_async pool (fun _ -> apply_rule pool l_agent (MSort ret_neg)); 
  decode_list ret_pos 

let rec is_sorted x = match x with
| [] -> true
| _::[] -> true
| h::h2::t -> if h <= h2 then is_sorted (h2::t) else false

let n = 
  try int_of_string @@ Sys.argv.(1) with _ -> 10 

let num_threads = 
  try int_of_string @@ Sys.argv.(2) with _ -> 1 

let pool = P.create ~num_threads () 

let () = 
  Random.self_init (); 
  let l = List.init n (fun _ -> Random.full_int Int.max_int) in
  let ret = msort pool l in  
  if not (is_sorted ret) then exit (-1); 
  () 
