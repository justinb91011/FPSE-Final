open OUnit2
open Player
open Uno_card
open Core

let test_create _ =
  let my_player = Player.create "Robert Griffin Justin" in
  assert_equal "Robert Griffin Justin" (Player.get_name my_player);
  assert_equal [] (Player.get_hand my_player)

let test_add_cards _ =
  let my_player = Player.create "Robert Griffin Justin" in
  let card1 = UnoCardInstance.create Red (Number 5) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let my_updated_player = Player.add_cards my_player [card1; card2] in
  assert_equal 2 (List.length (Player.get_hand my_updated_player));
  assert_bool "Player hand should contain card1."
    (List.exists (Player.get_hand my_updated_player) ~f:(UnoCardInstance.equal card1));
  assert_bool "Player hand should contain card2."
    (List.exists (Player.get_hand my_updated_player) ~f:(UnoCardInstance.equal card2))

let test_play_card _ =
  let card1 = UnoCardInstance.create Red (Number 5) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let my_player = Player.add_cards (Player.create "Robert Griffin Justin") [card2; card1] in
  let updated_player = Player.play_card my_player card1 top_card in
  (* Here we test the successful case. *)
  assert_equal 1 (List.length (Player.get_hand updated_player));
  let unsuccessful_top_card = UnoCardInstance.create Yellow (Number 2) in
  let new_player = Player.add_cards (Player.create "Robert Griffin Justin") [card1; card2] in
  (* Here we test the unsuccessful case. *)
  assert_raises (Failure "Card is not playable") (fun () -> Player.play_card new_player card1 unsuccessful_top_card);
  (* This is a sanity check in the case where a player has two of the same card, meaning one of the cards remains in their hand. *)
  let player = Player.add_cards (Player.create "Robert Griffin Justin") [card1; card1] in
  let new_updated_player = Player.play_card player card1 top_card in
  assert_equal 1 (List.length (Player.get_hand new_updated_player));
  let empty_player = Player.create "NULL" in
  (* This case should never truly be reached as this means the card is NOT in the hand. *)
  assert_raises (Failure "Card must be in hand. Should not be reached.") (fun () -> Player.play_card empty_player card1 top_card)

let test_has_won _ =
  (* We will emulate a case in where a player plays a card and then has an empty hand => they won UNO. *)
  let card1 = UnoCardInstance.create Red (Number 5) in
  let my_player = Player.add_cards (Player.create "Robert Griffin Justin") [card1] in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let updated_player = Player.play_card my_player card1 top_card in
  assert_bool "my_player has won the game!" (Player.has_won updated_player);
  assert_bool "my_player has NOT won the game!" (not (Player.has_won my_player))

let series =
  "Player Tests" >:::
  ["Player Creation" >:: test_create;
   "Player Card Addition" >:: test_add_cards;
   "Player Card Played" >:: test_play_card;
   "Player Win Check" >:: test_has_won]