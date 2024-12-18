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
  let chosen_card, remaining_deck, updated_cpu, color_chosen = CPU.choose_card cpu top_card (Deck.create_deck()) in
  assert_bool "The CPU should have chosen a playable card even if it's the easy difficulty."
    (UnoCard.is_playable
      (UnoCardInstance.get_color chosen_card) (UnoCardInstance.get_value chosen_card)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card));
  assert_equal None (color_chosen);
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
  let drawn_card, remaining_deck, updated_cpu, color_chosen = CPU.choose_card cpu top_card initial_deck in
  assert_equal None color_chosen;
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
  else (
    (* If drawn card is not playable, it's added to the hand:
       The hand size increases to 3, and the drawn card is in the hand *)
    assert_equal 3 (List.length updated_hand);
    assert_bool "Drawn card should be in the CPU's hand."
      (List.exists updated_hand ~f:(UnoCardInstance.equal drawn_card))
  );

  (* Another test case, this time where the CPU draws a card but it is not playable, thus the card is added to their hand and their turn is over. *)
  let new_top_card = UnoCardInstance.create Green (Number 7) in
  let new_cpu = CPU.add_cards (CPU.create Easy) [card1; card2] in
  let newly_drawn_card, new_deck, newly_updated_cpu, color_chosen = CPU.choose_card new_cpu new_top_card initial_deck in
  (* Since the card that was drawn by the CPU was not instanly playable, we must check that the CPU hand now contains three cards,
    including the newly drawn one, and that the new deck now has one less card. *)
  assert_equal 3 (Deck.remaining_cards (CPU.get_hand newly_updated_cpu));
  assert_equal None color_chosen;
  assert_bool "The CPU's hand should contain the newly drawn card." 
    (List.exists (CPU.get_hand newly_updated_cpu) ~f:(UnoCardInstance.equal newly_drawn_card));
  assert_equal 107 (Deck.remaining_cards new_deck)

let test_choose_card_wild_card_drawn _ =
  let drawn_card= UnoCardInstance.create WildColor (WildValue) in
  let card1 = UnoCardInstance.create Blue (Number 0) in
  let card2 = UnoCardInstance.create Red (Number 9) in
  let top_card = UnoCardInstance.create Yellow (Number 2) in
  let cpu = CPU.add_cards (CPU.create Easy) [card2; card1] in
  let chosen_card, remaining_deck, updated_cpu, color_chosen_opt = CPU.choose_card cpu top_card [drawn_card] in
  assert_bool "The CPU should have chosen a playable card even if it's the easy difficulty."
    (UnoCard.is_playable
      (UnoCardInstance.get_color chosen_card) (UnoCardInstance.get_value chosen_card)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card));
  let valid_colors = ["Blue"; "Red"; "Green"; "Yellow"] in
  let color_chosen = Option.value_exn color_chosen_opt in
  assert_bool "Chosen color should be one of Blue, Red, Green, or Yellow." (List.exists valid_colors ~f:(String.equal color_chosen));
  (* The CPU did draw, thus the deck should be empty. *)
  assert_equal 0 (Deck.remaining_cards remaining_deck);
  (* The CPU's hand should still contain two cards as they played the one they drew. *)
  assert_equal 2 (List.length (CPU.get_hand updated_cpu))

let test_choose_card_draw_four_card_drawn _ =
  let drawn_card= UnoCardInstance.create WildColor (DrawFour) in
  let card1 = UnoCardInstance.create Blue (Number 0) in
  let card2 = UnoCardInstance.create Red (Number 9) in
  let top_card = UnoCardInstance.create Yellow (Number 2) in
  let cpu = CPU.add_cards (CPU.create Easy) [card2; card1] in
  let chosen_card, remaining_deck, updated_cpu, color_chosen_opt = CPU.choose_card cpu top_card [drawn_card] in
  assert_bool "The CPU should have chosen a playable card even if it's the easy difficulty."
    (UnoCard.is_playable
      (UnoCardInstance.get_color chosen_card) (UnoCardInstance.get_value chosen_card)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card));
  let valid_colors = ["Blue"; "Red"; "Green"; "Yellow"] in
  let color_chosen = Option.value_exn color_chosen_opt in
  assert_bool "Chosen color should be one of Blue, Red, Green, or Yellow." (List.exists valid_colors ~f:(String.equal color_chosen));
  (* The CPU did not have to draw, thus the deck should still be full. *)
  assert_equal 0 (Deck.remaining_cards remaining_deck);
  (* The CPU's hand should still contain two cards as they played the one they drew. *)
  assert_equal 2 (List.length (CPU.get_hand updated_cpu))

let test_choose_card_easy_wildcard _ =
  let card1 = UnoCardInstance.create WildColor (WildValue) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let cpu = CPU.add_cards (CPU.create Easy) [card2; card1] in
  let chosen_card, remaining_deck, updated_cpu, color_chosen_opt = CPU.choose_card cpu top_card (Deck.create_deck()) in
  assert_bool "The CPU should have chosen a playable card even if it's the easy difficulty."
    (UnoCard.is_playable
      (UnoCardInstance.get_color chosen_card) (UnoCardInstance.get_value chosen_card)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card));
  let valid_colors = ["Blue"; "Red"; "Green"; "Yellow"] in
  let color_chosen = Option.value_exn color_chosen_opt in
  assert_bool "Chosen color should be one of Blue, Red, Green, or Yellow." (List.exists valid_colors ~f:(String.equal color_chosen));
  (* The CPU did not have to draw, thus the deck should still be full. *)
  assert_equal 108 (Deck.remaining_cards remaining_deck);
  (* The CPU's hand should now just contain one card as they played one of their two cards. *)
  assert_equal 1 (List.length (CPU.get_hand updated_cpu)) (* Changed here *)

let test_has_won _ =
  (* We will emulate a case in where a cpu plays a card and then has an empty hand => the CPU won UNO. *)
  let card1 = UnoCardInstance.create Red (Number 5) in
  let cpu = CPU.add_cards (CPU.create Easy) [card1] in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let _,_,updated_cpu, color_chosen = CPU.choose_card cpu top_card (Deck.create_deck()) in
  assert_equal None color_chosen;
  assert_bool "CPU has won the game!" (CPU.has_won updated_cpu);
  (* We will now test the case where a player still has cards in their hand, thus not having won the game. *)
  assert_bool "CPU has NOT won the game!" (not (CPU.has_won cpu))

let test_choose_card_hard _ =
  let card1 = UnoCardInstance.create Red (Number 5) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let cpu = CPU.add_cards (CPU.create Hard) [card2; card1] in
  let chosen_card, remaining_deck, updated_cpu, color_chosen = CPU.choose_card_hard cpu top_card (Deck.create_deck()) [2;3] in
  assert_bool "The CPU should have chosen a playable card."
    (UnoCard.is_playable
      (UnoCardInstance.get_color chosen_card) (UnoCardInstance.get_value chosen_card)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card));
  assert_equal None (color_chosen);
  (* The CPU did not have to draw, thus the deck should still be full. *)
  assert_equal 108 (Deck.remaining_cards remaining_deck);
  (* The CPU's hand should now just contain one card as they played one of their two cards. *)
  assert_equal 1 (List.length (CPU.get_hand updated_cpu))

let test_choose_card_hard_no_playable_card _ =
  let card1 = UnoCardInstance.create Blue (Number 5) in
  let card2 = UnoCardInstance.create Blue (Number 0) in
  let top_card = UnoCardInstance.create Red (Number 9) in
  let initial_deck = Deck.create_deck() in
  let cpu = CPU.add_cards (CPU.create Hard) [card1; card2] in
  let drawn_card, remaining_deck, updated_cpu, color_chosen = CPU.choose_card_hard cpu top_card initial_deck [2;3] in
  assert_equal None color_chosen;
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
  else (
    (* If drawn card is not playable, it's added to the hand:
       The hand size increases to 3, and the drawn card is in the hand *)
    assert_equal 3 (List.length updated_hand);
    assert_bool "Drawn card should be in the CPU's hand."
      (List.exists updated_hand ~f:(UnoCardInstance.equal drawn_card))
  );

  (* Another test case, this time where the CPU draws a card but it is not playable, thus the card is added to their hand and their turn is over. *)
  let new_top_card = UnoCardInstance.create Green (Number 7) in
  let new_cpu = CPU.add_cards (CPU.create Easy) [card1; card2] in
  let newly_drawn_card, new_deck, newly_updated_cpu, color_chosen = CPU.choose_card new_cpu new_top_card initial_deck in
  (* Since the card that was drawn by the CPU was not instanly playable, we must check that the CPU hand now contains three cards,
    including the newly drawn one, and that the new deck now has one less card. *)
  assert_equal 3 (Deck.remaining_cards (CPU.get_hand newly_updated_cpu));
  assert_equal None color_chosen;
  assert_bool "The CPU's hand should contain the newly drawn card." 
    (List.exists (CPU.get_hand newly_updated_cpu) ~f:(UnoCardInstance.equal newly_drawn_card));
  assert_equal 107 (Deck.remaining_cards new_deck)

  
let series =
  "Cpu Tests" >:::
  ["Cpu Creation" >:: test_create;
   "Cpu Card Addition" >:: test_add_cards;
   "Cpu Card Choice - Easy" >:: test_choose_card_easy;
   "Cpu Card Choice - Easy - Draw" >:: test_choose_card_easy_no_playable_card;
   "Cpu Card Choice - Easy - Drawn Wildcard" >:: test_choose_card_wild_card_drawn;
   "Cpu Card Choice - Easy - Drawn Draw Four" >:: test_choose_card_draw_four_card_drawn;
   "Cpu Card Choice - Easy - Wildcard" >:: test_choose_card_easy_wildcard;
   "Cpu Card Choice - Hard" >:: test_choose_card_hard;
   "Cpu Card Choice - Hard - Draw" >:: test_choose_card_hard_no_playable_card;
   "Cpu Win Check - Easy" >:: test_has_won]