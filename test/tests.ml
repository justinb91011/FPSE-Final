(* This is where we will be testing our code *)
open Core
open OUnit2

let series = 
  "UNO IMPLEMENTATION TESTS" >:::
  [Card_tests.series;
   Deck_tests.series
  ]

let () = run_test_tt_main series