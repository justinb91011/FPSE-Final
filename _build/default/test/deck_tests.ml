open OUnit2
open Core
open Uno_card
open Deck

let test_create_deck _ =
  let my_deck = Deck.create_deck() in
  assert_equal 108 (List.length my_deck)

let test_shuffle _ =
  let my_deck = Deck.create_deck() in
  let shuffled_deck = Deck.shuffle my_deck in
  assert_equal 108 (List.length shuffled_deck);
  assert_bool "Shuffled deck should not have the same order as the original deck."
    (not (List.equal UnoCardInstance.equal my_deck shuffled_deck))

let test_draw_card _ =
  (* The way the deck is set up is that we enumerate over all the red cards -> yellow -> green -> blue -> wild. 
     With this in mind, in a newly created deck, the first card will always be ((color Red)(value(Number 0))) followed by ((color Red(value(Number1))) and so on.
     We leverage this fact in this test. *)
  let my_deck = Deck.create_deck() in
  let card, my_remaining_deck = Deck.draw_card my_deck in
  assert_equal 107 (List.length my_remaining_deck);
  let occurrences_in_my_deck = List.count my_deck ~f:(UnoCardInstance.equal card) in
  let occurrences_in_my_remaining_deck = List.count my_remaining_deck ~f:(UnoCardInstance.equal card) in
  assert_equal (occurrences_in_my_deck - 1) occurrences_in_my_remaining_deck;
  assert_raises (Failure "Cannot draw from an empty deck.") (fun () -> Deck.draw_card [])

let test_draw_n_cards _ =
  let my_deck = Deck.create_deck() in
  let drawn_cards, remaining_deck = Deck.draw_cards 25 my_deck in
  assert_equal 25 (List.length drawn_cards);
  assert_equal 83 (List.length remaining_deck);
  assert_raises (Failure "Not enough cards to draw.") (fun () -> Deck.draw_cards 1 [])

let test_add_card _ =
  let my_deck = Deck.create_deck() in
  let card, _ = Deck.draw_card my_deck in
  let updated_deck = Deck.add_card card my_deck in
  assert_equal 109 (List.length updated_deck);
  assert_bool "Added card should be the last card in the deck."
    (UnoCardInstance.equal card (List.last_exn updated_deck))

let test_remaining_card _ =
  let my_deck = Deck.create_deck() in
  assert_equal 108 (Deck.remaining_cards my_deck);
  let _, remaining_deck = Deck.draw_cards 50 my_deck in
  assert_equal 58 (Deck.remaining_cards remaining_deck)



let series = 
  "Deck Tests" >:::
  ["Deck Creation" >:: test_create_deck;
   "Deck Shufffle" >:: test_shuffle;
   "Deck Card Draw" >:: test_draw_card;
   "Deck N Card Draws" >:: test_draw_n_cards;
   "Deck Add Card" >:: test_add_card;
   "Deck Remaining Cards" >:: test_remaining_card]