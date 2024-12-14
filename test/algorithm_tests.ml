(* open Core *)
open OUnit2
open Algorithm
open Uno_card
open Cpu

let test_rank_card_no_playable_card _ =
  let non_playable_top_card = UnoCardInstance.create UnoCard.Red (Number 5) in
  let cpu_card1 = UnoCardInstance.create UnoCard.Yellow (Number 8) in
  let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
  let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
  let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
  assert_equal 0 (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[3; 4] ~top_card:non_playable_top_card)

let test_rank_card_numbered_card _ =
  let top_card = UnoCardInstance.create UnoCard.Red (Number 8) in
  let cpu_card1 = UnoCardInstance.create UnoCard.Yellow (Number 8) in
  let cpu_card2 = UnoCardInstance.create UnoCard.Blue (Number 9) in
  let cpu_card3 = UnoCardInstance.create UnoCard.Green (Number 0) in
  let cpu = CPU.add_cards (CPU.create Medium) [cpu_card1; cpu_card2; cpu_card3] in
  assert_equal 1 (Algorithm.rank_card cpu_card1 ~hand:(CPU.get_hand cpu) ~opponents:[3; 4] ~top_card)
let series =
  "Algorithm Tests" >:::
  ["Algorithm Rank Card Test - Non Playable Card" >:: test_rank_card_no_playable_card;
   "Algorithm Rank Card Test - Numbered Card" >:: test_rank_card_numbered_card]