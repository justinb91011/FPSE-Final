open Core
open OUnit2
open Uno_card
open Deck
open Player
(* open Cpu *)
open Game

let test_initialize_game _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state was not initialized."
  | Some state ->
    assert_equal 1 (List.length state.players);
    assert_equal 2 (List.length state.cpus);
    assert_equal 1 (List.length state.discard_pile);
    assert_equal 1 state.direction

let test_get_players _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state was not initialized."
  | Some state ->
    let players = Game.get_players state in
    assert_equal (1) (List.length players);
    let player_names = List.map ~f:fst players in
    assert (List.mem player_names "Player1" ~equal:String.equal)

let test_get_cpus _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state was not initialized."
  | Some state ->
    let cpus = Game.get_cpus state in
    assert_equal (2) (List.length cpus);
    let cpu_names = List.map ~f:fst cpus in
    assert (List.mem cpu_names "CPU1" ~equal:String.equal);
    assert (List.mem cpu_names "CPU2" ~equal:String.equal)
         
let test_is_valid_initial_card _ =
  (* We'll start with the case of a draw two, which should not be the intial top card. *)
  let draw_two = UnoCardInstance.create UnoCard.Blue (DrawTwo) in
  assert_bool "DrawTwo should not be an initial top card" (not (Game.is_valid_initial_card draw_two));
  (* The draw four should also not be the initial top card. *)
  let draw_four = UnoCardInstance.create UnoCard.WildColor (DrawFour) in
  assert_bool "DrawFour should not be an initial top card" (not (Game.is_valid_initial_card draw_four));
  let wildcard = UnoCardInstance.create UnoCard.WildColor (WildValue) in
  assert_bool "Wild Card should not be an initial top card" (not (Game.is_valid_initial_card wildcard));
  let skip = UnoCardInstance.create UnoCard.Green (Skip) in
  assert_bool "Skip should be an initial top card" (Game.is_valid_initial_card skip);
  let reverse = UnoCardInstance.create UnoCard.Yellow (Reverse) in
  assert_bool "Reverse Card should be an initial top card" (Game.is_valid_initial_card reverse);
  let numbered_color_card = UnoCardInstance.create UnoCard.Red (Number 5) in
  assert_bool "Wild Card should not be an initial top card" (Game.is_valid_initial_card numbered_color_card)

let test_next_player_index _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let new_index = Game.next_player_index state in
    assert_equal 1 new_index
  | None -> assert_failure "Game state not initialized"

let test_handle_skip_card _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let skip_card = UnoCardInstance.create UnoCard.Red Skip in
    let new_state = Game.handle_skip_card state skip_card in
    assert_equal 1 new_state.current_player_index
  | None -> assert_failure "Game state not initialized"

let test_handle_skip_card_with_random_card _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let not_skip_card = UnoCardInstance.create UnoCard.Red (Number 0) in
    let new_state = Game.handle_skip_card state not_skip_card in
    assert_equal 0 new_state.current_player_index
  | None -> assert_failure "Game state not initialized"

let test_handle_reverse_card _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
    let new_state = Game.handle_reverse_card state reverse_card 0 in
    (* Sanity check to make sure we're on the player. *)
    assert_equal (0) (state.current_player_index);
    (* Confirm that we reversed directions. *)
    assert_equal (-1) (new_state.direction);
    (* Confirm that the next player is the CPU2. *)
    assert_equal (2) (new_state.current_player_index);
    (* Confirm that the following player would be CPU1. *)
    assert_equal (1) (Game.next_player_index new_state)
  | None -> assert_failure "Game state not initialized"

let test_handle_cpu_reverse_card _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let updated_state = {state with current_player_index = 1} in
    let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
    let new_state = Game.handle_reverse_card updated_state reverse_card 1 in
    (* Sanity check to make sure we are on CPU1. *)
    assert_equal (1) (updated_state.current_player_index);
    (* Assert direction reversed *)
    assert_equal (-1) new_state.Game.direction;
    (* Assert the current player index is updated correctly *)
    assert_equal 0 new_state.current_player_index;
    (* Assert the following player index is updated correctly as well. *)
    assert_equal 2 (Game.next_player_index new_state);
    (* Case where we the CPU2 player plays the Reverse card. *)
    let new_updated_state = {state with current_player_index = 2} in
    let newly_state = Game.handle_reverse_card new_updated_state reverse_card 2 in
    (* Sanity check to make sure we are on CPU2. *)
    assert_equal (2) (new_updated_state.current_player_index);
    (* Assert direction reversed *)
    assert_equal (-1) newly_state.Game.direction;
    (* Assert the current player index is updated correctly *)
    assert_equal (1) newly_state.Game.current_player_index;
    assert_equal (0) (Game.next_player_index newly_state)
  | None -> assert_failure "Game state not initialized"

let test_handle_reverse_card_with_random_card _ =
    Game.initialize_game(Easy);
    match !Game.game_state with
    | Some state ->
      let not_reverse_card = UnoCardInstance.create UnoCard.Red (Number 5) in
      let new_state = Game.handle_reverse_card state not_reverse_card 0 in
      assert_equal (1) new_state.direction
    | None -> assert_failure "Game state not initialized"

let test_handle_reverse_card_counterclockwise _ =
    Game.initialize_game(Easy);
    match !Game.game_state with
    | Some state ->
      let updated_state = {state with direction = -1} in
      let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
      let new_state = Game.handle_reverse_card updated_state reverse_card 0 in
      (* Sanity check to make sure we are on player. *)
      assert_equal (0) (state.current_player_index);
      (* Confirm the direction has be reversed. *)
      assert_equal (1) (new_state.direction);
      (* Confirm that the next player is CPU1. *)
      assert_equal (1) (new_state.current_player_index);
      (* Confirm that the following player is CPU2. *)
      assert_equal (2) (Game.next_player_index new_state)
    | None -> assert_failure "Game state not initialized"

let test_handle_cpu_reverse_card_counterclockwise _ =
    Game.initialize_game(Easy);
    match !Game.game_state with
    | Some state ->
      let updated_state = {state with current_player_index = 1; direction = -1} in
      let reverse_card = UnoCardInstance.create UnoCard.Red Reverse in
      let new_state = Game.handle_reverse_card updated_state reverse_card 1 in
      (* Santiy check to make sure we are on CPU1. *)
      assert_equal (1) (updated_state.current_player_index);
      (* Assert direction reversed. *)
      assert_equal (1) (new_state.Game.direction);
      (* Assert the current player index is updated correctly *)
      assert_equal (2) (new_state.Game.current_player_index);
      (* Assert the next player is updated correctly. *)
      assert_equal (0) (Game.next_player_index new_state);

      let new_updated_state = {state with current_player_index = 2; direction = -1} in
      let newly_state = Game.handle_reverse_card new_updated_state reverse_card 2 in
      (* Sanity check to make sure we are on CPU2. *)
      assert_equal (2) (new_updated_state.current_player_index);
      (* Assert direction reversed. *)
      assert_equal (1) newly_state.Game.direction;
      (* Assert the current player index is updated correctly. *)
      assert_equal (0) (newly_state.Game.current_player_index);
      (* Assert the next player is updated correctly.*)
      assert_equal (1) (Game.next_player_index newly_state)
      
    | None -> assert_failure "Game state not initialized"

let test_handle_draw_two _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let draw_two_card = UnoCardInstance.create UnoCard.Red DrawTwo in
    let _, message = Game.handle_draw_two state draw_two_card in
    assert_bool "Message should be present" (Option.is_some message)
  | None -> assert_failure "Game state not initialized"

let test_handle_draw_two_cpu_1 _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let cpu_state = {state with current_player_index = 1} in
    let draw_two_card = UnoCardInstance.create UnoCard.Red DrawTwo in
    let _, message = Game.handle_draw_two cpu_state draw_two_card in
    assert_bool "Message should be present" (Option.is_some message)
  | None -> assert_failure "Game state not initialized"

let test_handle_draw_two_cpu_2 _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let cpu_state = {state with current_player_index = 2} in
    let draw_two_card = UnoCardInstance.create UnoCard.Red DrawTwo in
    let _, message = Game.handle_draw_two cpu_state draw_two_card in
    assert_bool "Message should be present" (Option.is_some message)
  | None -> assert_failure "Game state not initialized"

let test_handle_draw_two_random_card _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | Some state ->
    let not_draw_two_card = UnoCardInstance.create UnoCard.Red (Number 5) in
    let new_state, message = Game.handle_draw_two state not_draw_two_card in
    assert_equal None message;
    assert_equal state new_state
  | None -> assert_failure "Game state not initialized"

let test_handle_wild_card_blue _ =
      Game.initialize_game(Easy);
      match !Game.game_state with
      | None -> assert_failure "Game state not initialized"
      | Some state ->
        let wild_card = UnoCardInstance.create UnoCard.WildColor WildValue in
        match Game.handle_wild_card state wild_card (Some "blue") with
        | None -> assert_failure "Wild card handling failed."
        | Some new_state ->
          let top_discard = List.hd_exn new_state.discard_pile in
          assert_equal (UnoCard.Blue) (UnoCardInstance.get_color top_discard)

let test_handle_wild_card_red _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let wild_card = UnoCardInstance.create UnoCard.WildColor WildValue in
    match Game.handle_wild_card state wild_card (Some "red") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      let top_discard = List.hd_exn new_state.discard_pile in
      assert_equal (UnoCard.Red) (UnoCardInstance.get_color top_discard)

let test_handle_wild_card_green _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let wild_card = UnoCardInstance.create UnoCard.WildColor WildValue in
    match Game.handle_wild_card state wild_card (Some "green") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      let top_discard = List.hd_exn new_state.discard_pile in
      assert_equal (UnoCard.Green) (UnoCardInstance.get_color top_discard)

let test_handle_wild_card_yellow _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let wild_card = UnoCardInstance.create UnoCard.WildColor WildValue in
    match Game.handle_wild_card state wild_card (Some "yellow") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      let top_discard = List.hd_exn new_state.discard_pile in
      assert_equal (UnoCard.Yellow) (UnoCardInstance.get_color top_discard)

let test_handle_draw_four_blue _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let draw_four = UnoCardInstance.create UnoCard.WildColor DrawFour in
    match Game.handle_wild_card state draw_four (Some "blue") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      let top_discard = List.hd_exn new_state.discard_pile in
      assert_equal (UnoCard.Blue) (UnoCardInstance.get_color top_discard)

let test_handle_draw_four_red _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let draw_four = UnoCardInstance.create UnoCard.WildColor DrawFour in
    match Game.handle_wild_card state draw_four (Some "red") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      let top_discard = List.hd_exn new_state.discard_pile in
      assert_equal (UnoCard.Red) (UnoCardInstance.get_color top_discard)
      
let test_handle_draw_four_green_cpu_pov _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let cpu_state = {state with current_player_index = 2} in
    let draw_four = UnoCardInstance.create UnoCard.WildColor DrawFour in
    match Game.handle_wild_card cpu_state draw_four (Some "green") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      let top_discard = List.hd_exn new_state.discard_pile in
      assert_equal (UnoCard.Green) (UnoCardInstance.get_color top_discard)

let test_handle_draw_four_yellow_cpu_pov _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let cpu_state = {state with current_player_index = 2} in
    let draw_four = UnoCardInstance.create UnoCard.WildColor DrawFour in
    match Game.handle_wild_card cpu_state draw_four (Some "yellow") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      let top_discard = List.hd_exn new_state.discard_pile in
      assert_equal (UnoCard.Yellow) (UnoCardInstance.get_color top_discard)

let test_handle_draw_four_random_card _ =
  Game.initialize_game(Easy);
  match !Game.game_state with
  | None -> assert_failure "Game state not initialized"
  | Some state ->
    let not_draw_four = UnoCardInstance.create UnoCard.Red (Number 9) in
    match Game.handle_wild_card state not_draw_four (Some "blue") with
    | None -> assert_failure "Wild card handling failed."
    | Some new_state ->
      assert_equal state new_state
(* Might be failing if a card being played is a wild_card and they are choosing colors. *)
  let print_option s =
    match s with
    | None -> "None"
    | Some s -> s

  let get_top_card dis_pile = 
    match dis_pile with
    | [] -> UnoCardInstance.create WildColor (Number 99)
    | x :: _ -> x

  let test_play_cpu_turn _ =
    Game.initialize_game(Easy);
    match !Game.game_state with
    | Some state ->
        let updated_state = {state with current_player_index = 1; direction = 1} in
        let new_state, _, cpu_index, _= Game.play_cpu_turn updated_state in
        assert_equal 1 cpu_index;
        assert_bool "Deck should be updated." (Deck.remaining_cards new_state.deck <= Deck.remaining_cards state.deck);
    | None -> assert_failure "Game not initialized."  
let test_any_playable_card _ =
  let card1 = UnoCardInstance.create (UnoCard.Red) (Number 5) in
  let card2 = UnoCardInstance.create (UnoCard.Blue) (Number 0) in
  let card3 = UnoCardInstance.create (UnoCard.Yellow) (Skip) in
  let card4 = UnoCardInstance.create (UnoCard.Yellow) (DrawTwo) in
  let non_playable_top_card = UnoCardInstance.create (UnoCard.Green) (Number 1) in
  let playable_top_card = UnoCardInstance.create (UnoCard.Green) (Number 5) in
  let me = Player.add_cards (Player.create "Robert Xavier Velez") [card1; card2; card3; card4] in
  assert_bool "My hand should not contain a playable card with respect to the top_card" (not (Game.any_playable_card (Player.get_hand me) non_playable_top_card));
  assert_bool "My hand should not contain a playable card with respect to the top_card" (Game.any_playable_card (Player.get_hand me) playable_top_card)
  

let test_initialize_hard_game _ =
  Game.initialize_game(Hard);
  match !Game.game_state with
  | Some state ->
    assert_equal 1 (List.length state.players);
    assert_equal 2 (List.length state.cpus);
    assert_equal 1 (List.length state.discard_pile);
    assert_equal 1 state.direction
  | None -> assert_failure "Hard game not initialized."

let test_play_cpu_turn_hard _ =
  Game.initialize_game(Hard);
  match !Game.game_state with
  | Some state ->
      let updated_state = {state with current_player_index = 1; direction = 1} in
      let new_state, _, cpu_index, _= Game.play_cpu_turn updated_state in
      assert_equal 1 cpu_index;
      assert_bool "Deck should be updated." (Deck.remaining_cards new_state.deck <= Deck.remaining_cards state.deck);
  | None -> assert_failure "Game not initialized."  

let series =
  "Game Tests" >:::
  ["Game Initialization" >:: test_initialize_game;
   "Game Player Getter" >:: test_get_players;
   "Game CPU Getter" >:: test_get_cpus;
   "Game Next Player" >:: test_next_player_index;
   "Game Valid Initial Card - DrawTwo, DrawFour, WildCard, Skip, Reverse, and numbered cards" >:: test_is_valid_initial_card;
   "Game Skip Card Handling" >:: test_handle_skip_card;
   "Game Skip Card Handling - Not a Skip Card" >:: test_handle_skip_card_with_random_card;
   "Game Reverse Card Handling" >:: test_handle_reverse_card;
   "Game Reverse Card Handling - CPU" >:: test_handle_cpu_reverse_card;
   "Game Reverse Card Handling - Not a Reverse Card" >:: test_handle_reverse_card_with_random_card;
   "Game Reverse Card Handling - Counterclockwise Start" >:: test_handle_reverse_card_counterclockwise;
   "Game Reverse Card Handling - CPU Counterclockwise Start" >:: test_handle_cpu_reverse_card_counterclockwise;
   "Game Draw Two Card Handling" >:: test_handle_draw_two;
   "Game Draw Two Card Handling - CPU #1 Turn" >:: test_handle_draw_two_cpu_1;
   "Game Draw Two Card Handling - CPU #2 Turn" >:: test_handle_draw_two_cpu_2;
   "Game Draw Two Card Handling - Not a Draw Two Card" >:: test_handle_draw_two_random_card;
   "Game Wild Card Handling - Blue Chosen" >:: test_handle_wild_card_blue;
   "Game Wild Card Handling - Red Chosen" >:: test_handle_wild_card_red;
   "Game Wild Card Handling - Green Chosen" >:: test_handle_wild_card_green;
   "Game Wild Card Handling - Yellow Chosen" >:: test_handle_wild_card_yellow;
   "Game Draw Four Card Handling - Blue Chosen" >:: test_handle_draw_four_blue;
   "Game Draw Four Card Handling - Red Chosen" >:: test_handle_draw_four_red;
   "Game Draw Four Card Handling - Green Chosen" >:: test_handle_draw_four_green_cpu_pov;
   "Game Draw Four Card Handling - Yellow Chosen" >:: test_handle_draw_four_yellow_cpu_pov;
   "Game Draw Four Card Handling - Not a Draw Four Card" >:: test_handle_draw_four_random_card;
   "Game CPU Turn Handling" >:: test_play_cpu_turn;
   "Game Hand Playability with Top Card" >:: test_any_playable_card;
   "Game Initialization - Hard" >:: test_initialize_hard_game;
   "Game CPU Turn Handling - Hard" >:: test_play_cpu_turn_hard;]