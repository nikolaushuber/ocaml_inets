module P = Moonpool.Ws_pool
module R = Moonpool.Runner 
module F = Moonpool.Fut 

type pos = |
type neg = |

type (_, _) agent = 
  | QSort : (int array, neg) agent -> (int array, neg) agent 
  | Part : (int array, neg) agent * (int array, neg) agent -> (int array, neg) agent 
  | Comb : (int array, neg) agent * (int array, pos) agent -> (int array, neg) agent 
  | Comb' : (int array, neg) agent -> (int array, neg) agent 
  | Array : int array * int * int -> (int array, pos) agent 
  | NamePos : ('a, pos) agent F.t -> ('a, pos) agent 
  | NameNeg : ('a, pos) agent F.promise -> ('a, neg) agent 

let mk_Name () = 
  let future, promise = F.make () in 
  NamePos future, NameNeg promise

  let apply_rule pool a1 a2 =
    let rec apply_rule : type a. (a, pos) agent -> (a, neg) agent -> unit = 
      fun a1 a2 -> match a1, a2 with 
      | Array (ar, left, right), QSort (ret) when left < right -> 
        let cnt_pos, cnt_neg = mk_Name () in 
        let x = Comb (ret, cnt_pos) in 
        let smaller = QSort x in 
        let larger = QSort (cnt_neg) in 
        Array (ar, left, right) -><- Part (smaller, larger)

      | Array (ar, left, right), QSort (ret) -> Array (ar, left, right) -><- ret

      | Array _, Comb (ret, b) -> b -><- Comb' ret

      | Array (ar, left, right), Comb' ret -> Array (ar, left, right) -><- ret

      | Array (ar, left, right), Part (smaller, larger) -> 
        let i = ref left in 
        let j = ref (right - 1) in 

        let pivot = Array.get ar right in 

        while i < j do
          while (i < j) && (ar.(!i) <= pivot) do 
            incr i
          done; 

          while (j > i) && (ar.(!j) > pivot) do 
            decr j 
          done; 

          if ar.(!i) > ar.(!j) then 
            let t = ar.(!i) in 
            ar.(!i) <- ar.(!j); 
            ar.(!j) <- t 
          else 
            ()
        done; 

        if ar.(!i) > pivot then 
          let t = ar.(!i) in 
          ar.(!i) <- ar.(right); 
          ar.(right) <- t 
        else
            i := right
        ;

        Array (ar, left, !i-1) -><- smaller; 
        Array (ar, !i+1, right) -><- larger

      | NamePos v, a -> F.on_result v (fun a' -> (Result.get_ok a') -><- a)  
      | a, NameNeg v -> F.fulfill v (Ok a)

    and ( -><- ) : type a. (a, pos) agent -> (a, neg) agent -> unit  = 
      fun a1 a2 ->
      R.run_async pool (fun _ -> apply_rule a1 a2)
    in

    a1 -><- a2 

let rec decode_array = function 
  | Array (ar, _, _) -> ar 
  | NamePos v -> decode_array (F.wait_block_exn v) 

let qsort pool l = 
  let l_agent = Array (l, 0, (Array.length l) - 1) in 
  let ret_pos, ret_neg = mk_Name () in 
  R.run_async pool (fun _ -> apply_rule pool l_agent (QSort ret_neg)); 
  decode_array ret_pos 
  
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
  let l = Array.init n (fun _ -> Random.full_int Int.max_int) in
  let ret = qsort pool l in  
  if not (is_sorted (ret |> Array.to_list)) then exit (-1); 
  () 
