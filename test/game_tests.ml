open Core
open OUnit2
open Uno_card
(* open Deck *)
(* open Player *)
(* open Cpu *)
open Game


let test_initialize_game _ =
  Game.initialize_game();
  match !Game.game_state with
  | None -> assert_failure "Game state was not initialized."
  | Some state ->
    assert_equal 1 (List.length state.players);
    assert_equal 2 (List.length state.cpus);
    assert_equal 1 (List.length state.discard_pile);
    assert_equal 1 state.direction

let test_next_player_index _ =
  Game.initialize_game();
  match !Game.game_state with
  | Some state ->
    let new_index = Game.next_player_index state in
    assert_equal 1 new_index
  | None -> assert_failure "Game state not initialized"

let test_handle_skip_card _ =
  Game.initialize_game();
  match !Game.game_state with
  | Some state ->
    let skip_card = UnoCardInstance.create UnoCard.Red Skip in
    let new_state = Game.handle_skip_card state skip_card in
    assert_equal 1 new_state.current_player_index
  | None -> assert_failure "Game state not initialized"

  let test_handle_skip_card_with_random_card _ =
    Game.initialize_game();
    match !Game.game_state with
    | Some state ->
      let not_skip_card = UnoCardInstance.create UnoCard.Red (Number 0) in
      let new_state = Game.handle_skip_card state not_skip_card in
      assert_equal 0 new_state.current_player_index
    | None -> assert_failure "Game state not initialized"

  let test_handle_reverse_card _ =
    Game.initialize_game();
    match !Game.game_state with
    | Some state ->
      let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
      let new_state = Game.handle_reverse_card state reverse_card 0 in
      assert_equal (-1) new_state.direction
    | None -> assert_failure "Game state not initialized"

  let test_handle_cpu_reverse_card _ =
    Game.initialize_game();
    match !Game.game_state with
    | Some state ->
      let updated_state = {state with current_player_index = 1} in
      let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
      let new_state = Game.handle_reverse_card updated_state reverse_card 1 in
      (* Assert direction reversed *)
      assert_equal (-1) new_state.Game.direction;
      (* Assert the current player index is updated correctly *)
      assert_equal 0 new_state.Game.current_player_index;

      let new_updated_state = {state with current_player_index = 2} in
      let newly_state = Game.handle_reverse_card new_updated_state reverse_card 2 in
      (* Assert direction reversed *)
      assert_equal (-1) newly_state.Game.direction;
      (* Assert the current player index is updated correctly *)
      assert_equal 1 newly_state.Game.current_player_index;
    | None -> assert_failure "Game state not initialized"

  let test_handle_reverse_card_with_random_card _ =
      Game.initialize_game();
      match !Game.game_state with
      | Some state ->
        let not_reverse_card = UnoCardInstance.create UnoCard.Red (Number 5) in
        let new_state = Game.handle_reverse_card state not_reverse_card 0 in
        assert_equal (1) new_state.direction
      | None -> assert_failure "Game state not initialized"

  let test_handle_reverse_card_counterclockwise _ =
      Game.initialize_game();
      match !Game.game_state with
      | Some state ->
        let updated_state = {state with direction = -1} in
        let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
        let new_state = Game.handle_reverse_card updated_state reverse_card 0 in
        assert_equal (1) new_state.direction
      | None -> assert_failure "Game state not initialized"
  
  let test_handle_cpu_reverse_card_counterclockwise _ =
      Game.initialize_game();
      match !Game.game_state with
      | Some state ->
        let updated_state = {state with current_player_index = 1; direction = -1} in
        let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
        let new_state = Game.handle_reverse_card updated_state reverse_card 1 in
        (* Assert direction reversed *)
        assert_equal (1) new_state.Game.direction;
        (* Assert the current player index is updated correctly *)
        assert_equal 2 new_state.Game.current_player_index;
  
        let new_updated_state = {state with current_player_index = 2; direction = -1} in
        let newly_state = Game.handle_reverse_card new_updated_state reverse_card 2 in
        (* Assert direction reversed *)
        assert_equal (1) newly_state.Game.direction;
        (* Assert the current player index is updated correctly *)
        assert_equal 0 newly_state.Game.current_player_index;
      | None -> assert_failure "Game state not initialized"

  let test_handle_draw_two _ =
    Game.initialize_game();
    match !Game.game_state with
    | Some state ->
      let draw_two_card = UnoCardInstance.create UnoCard.Red DrawTwo in
      let _, message = Game.handle_draw_two state draw_two_card in
      assert_bool "Message should be present" (Option.is_some message)
    | None -> assert_failure "Game state not initialized"
  let test_handle_wild_card _ =
      Game.initialize_game();
      match !Game.game_state with
      | None -> assert_failure "Game state not initialized"
      | Some state ->
        let wild_card = UnoCardInstance.create UnoCard.WildColor WildValue in
        match Game.handle_wild_card state wild_card (Some "blue") with
        | None -> assert_failure "Wild card handling failed."
        | Some new_state ->
          let top_discard = List.hd_exn new_state.discard_pile in
          assert_equal (UnoCard.Blue) (UnoCardInstance.get_color top_discard)

let series =
  "Game Tests" >:::
  ["Game Initialization" >:: test_initialize_game;
   "Game Next Player" >:: test_next_player_index;
   "Game Skip Card Handling" >:: test_handle_skip_card;
   "Game Skip Card Handling - Not a Skip Card" >:: test_handle_skip_card_with_random_card;
   "Game Reverse Card Handling" >:: test_handle_reverse_card;
   "Game Reverse Card Handling - CPU" >:: test_handle_cpu_reverse_card;
   "Game Reverse Card Handling - Not a Reverse Card" >:: test_handle_reverse_card_with_random_card;
   "Game Reverse Card Handling - Counterclockwise Start" >:: test_handle_reverse_card_counterclockwise;
   "Game Reverse Card Handling - CPU Counterclockwise Start" >:: test_handle_cpu_reverse_card_counterclockwise;
   "Game Draw Two Card Handling" >:: test_handle_draw_two;
   "Game Wild Card Handling" >:: test_handle_wild_card]