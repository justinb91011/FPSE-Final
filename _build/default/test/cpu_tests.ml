open Core
open OUnit2
open Cpu
open Uno_card
open Deck

let test_create _ =
  let cpu = CPU.create CPU.Easy in
  assert_equal CPU.Easy (CPU.get_difficulty cpu);
  assert_equal [] (CPU.get_hand cpu);
  let cpu1 = CPU.create CPU.Medium in
  assert_equal CPU.Medium (CPU.get_difficulty cpu1);
  assert_equal [] (CPU.get_hand cpu1);
  let cpu2 = CPU.create CPU.Hard in
  assert_equal CPU.Hard (CPU.get_difficulty cpu2);
  assert_equal [] (CPU.get_hand cpu2)

let test_add_cards _ =
  let cpu = CPU.create Easy in
  let card1 = UnoCardInstance.create Red (Number 5) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let updated_cpu = CPU.add_cards cpu [card1; card2] in
  assert_equal 2 (List.length (CPU.get_hand updated_cpu));
  assert_bool "Player hand should contain card1."
    (List.exists (CPU.get_hand updated_cpu) ~f:(UnoCardInstance.equal card1));
  assert_bool "Player hand should contain card2."
    (List.exists (CPU.get_hand updated_cpu) ~f:(UnoCardInstance.equal card2))
  
let test_choose_card_easy _ =
  let card1 = UnoCardInstance.create Red (Number 5) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let cpu = CPU.add_cards (CPU.create Easy) [card2; card1] in
  let chosen_card, remaining_deck, updated_cpu = CPU.choose_card cpu top_card (Deck.create_deck()) in
  assert_bool "The CPU should have chosen a playable card even if it's the easy difficulty."
    (UnoCard.is_playable
      (UnoCardInstance.get_color chosen_card) (UnoCardInstance.get_value chosen_card)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card));
  (* The CPU did not have to draw, thus the deck should still be full. *)
  assert_equal 108 (Deck.remaining_cards remaining_deck);
  (* The CPU's hand should now just contain one card as they played one of their two cards. *)
  assert_equal 1 (List.length (CPU.get_hand updated_cpu)) (* Changed here *)

let test_choose_card_easy_no_playable_card _ =
  let card1 = UnoCardInstance.create Blue (Number 5) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let initial_deck = Deck.create_deck() in
  let cpu = CPU.add_cards (CPU.create Easy) [card1; card2] in
  let drawn_card, remaining_deck, updated_cpu = CPU.choose_card cpu top_card initial_deck in

  (* Verify deck size assumptions remain correct *)
  assert_equal 108 (Deck.remaining_cards initial_deck);
  assert_equal 107 (Deck.remaining_cards remaining_deck);

  (* Check if the drawn card was playable or not *)
  let top_color = UnoCardInstance.get_color top_card in
  let top_value = UnoCardInstance.get_value top_card in
  let drawn_color = UnoCardInstance.get_color drawn_card in
  let drawn_value = UnoCardInstance.get_value drawn_card in
  let drawn_playable = UnoCard.is_playable drawn_color drawn_value top_color top_value in

  let updated_hand = CPU.get_hand updated_cpu in

  if drawn_playable then
    (* If drawn card is playable, CPU should have played it immediately:
       The hand size remains at 2. *)
    assert_equal 2 (List.length updated_hand)
  else begin
    (* If drawn card is not playable, it's added to the hand:
       The hand size increases to 3, and the drawn card is in the hand *)
    assert_equal 3 (List.length updated_hand); (* Changed here *)
    assert_bool "Drawn card should be in the CPU's hand."
      (List.exists updated_hand ~f:(UnoCardInstance.equal drawn_card))
  end

let test_has_won _ =
  (* We will emulate a case in where a cpu plays a card and then has an empty hand => the CPU won UNO. *)
  let card1 = UnoCardInstance.create Red (Number 5) in
  let cpu = CPU.add_cards (CPU.create Easy) [card1] in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let _,_,updated_cpu = CPU.choose_card cpu top_card (Deck.create_deck()) in
  assert_bool "CPU has won the game!" (CPU.has_won updated_cpu);
  (* We will now test the case where a player still has cards in their hand, thus not having won the game. *)
  assert_bool "CPU has NOT won the game!" (not (CPU.has_won cpu))


let series =
  "Cpu Tests" >:::
  ["Cpu Creation" >:: test_create;
   "Cpu Card Addition" >:: test_add_cards;
   "Cpu Card Choice - Easy" >:: test_choose_card_easy;
   "Cpu Card Choice - Easy - Draw" >:: test_choose_card_easy_no_playable_card;
   "Cpu Win Check - Easy >::" >:: test_has_won]