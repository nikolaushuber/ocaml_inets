let n = try int_of_string Sys.argv.(1) with _ -> 10 

let rec fib = function 
  | 0 -> 0 
  | 1 -> 1 
  | n -> fib (n-1) + fib (n-2) 

let () = 
  fib n 
  |> string_of_int 
  |> print_endline 
