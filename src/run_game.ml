open Core
open Uno_card
open Deck
open Player
open Cpu

type game_state = {
  deck : Deck.t;
  discard_pile : UnoCardInstance.t list;
  players : (string * Player.t) list;
  cpus : (string * CPU.t) list;
  current_player_index : int;
  direction : int;  (* 1 for clockwise, -1 for counterclockwise *)
}

let game_state = ref None

(* Helper function to check if there's any playable card in hand *)
let any_playable_card hand top_card =
  List.exists hand ~f:(fun c ->
    UnoCard.is_playable
      (UnoCardInstance.get_color c) (UnoCardInstance.get_value c)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card)
  )

let initialize_game () =
  let deck = Deck.create_deck () |> Deck.shuffle in

  let player = Player.create "Player1" in
  let cpu1 = CPU.create CPU.Easy in
  let cpu2 = CPU.create CPU.Easy in

  let player_cards, deck = Deck.draw_cards 7 deck in
  let player = Player.add_cards player player_cards in

  let cpu1_cards, deck = Deck.draw_cards 7 deck in
  let cpu1 = CPU.add_cards cpu1 cpu1_cards in

  let cpu2_cards, deck = Deck.draw_cards 7 deck in
  let cpu2 = CPU.add_cards cpu2 cpu2_cards in

  let top_card, deck = Deck.draw_card deck in
  let discard_pile = [top_card] in

  let initial_state = {
    deck;
    discard_pile;
    players = [("Player1", player)];
    cpus = [("CPU1", cpu1); ("CPU2", cpu2)];
    current_player_index = 0;
    direction = 1;
  } in

  game_state := Some initial_state

let next_player_index state =
  let num_players = List.length state.players + List.length state.cpus in
  (state.current_player_index + state.direction + num_players) mod num_players

(* Function to handle the skip card logic *)
let handle_skip_card state played_card =
  let value = UnoCardInstance.get_value played_card in
  match value with
  | Skip ->
    (* Skip the next player's turn by advancing once more *)
    { state with current_player_index = next_player_index state }
  | _ ->
    (* If not a skip card, do nothing *)
    state

(* Function to handle the reverse card logic *)
let handle_reverse_card state played_card who_played =
  let value = UnoCardInstance.get_value played_card in
  match value with
  | Reverse ->
    (* Determine new direction and next turn based on who played and current direction *)
    let new_direction, new_turn =
      if state.direction = 1 then
        (* Currently clockwise *)
        match who_played with
        | 0 (* Player1 played Reverse *) -> (-1, 2)  (* direction = -1, turn = CPU#2 (index 2) *)
        | 1 (* CPU1 played Reverse *) -> (-1, 0)    (* direction = -1, turn = Player1 (index 0) *)
        | 2 (* CPU2 played Reverse *) -> (-1, 1)    (* direction = -1, turn = CPU#1 (index 1) *)
        | _ -> (state.direction, state.current_player_index)
      else
        (* Currently counterclockwise (direction = -1) *)
        match who_played with
        | 0 (* Player1 played Reverse *) -> (1, 1)  (* direction = 1, turn = CPU#1 (index 1) *)
        | 1 (* CPU1 played Reverse *) -> (1, 2)     (* direction = 1, turn = CPU#2 (index 2) *)
        | 2 (* CPU2 played Reverse *) -> (1, 0)     (* direction = 1, turn = Player1 (index 0) *)
        | _ -> (state.direction, state.current_player_index)
    in
    { state with direction = new_direction; current_player_index = new_turn }
  | _ ->
    (* If not a reverse card, do nothing *)
    state

(* Modified play_cpu_turn to return (new_state, card, cpu_index) *)
let play_cpu_turn state =
  let cpu_index = state.current_player_index in
  let (_, current_cpu) = List.nth_exn state.cpus (cpu_index - 1) in
  let top_discard = List.hd_exn state.discard_pile in

  (* CPU chooses a card *)
  let card, new_deck, updated_cpu = CPU.choose_card current_cpu top_discard state.deck in

  (* Determine if CPU played the card *)
  let card_played = not (List.exists (CPU.get_hand updated_cpu) ~f:(UnoCardInstance.equal card)) in

  (* Update discard pile only if card was actually played *)
  let new_discard_pile =
    if card_played then
      card :: state.discard_pile
    else
      state.discard_pile
  in

  let updated_cpus =
    List.mapi state.cpus ~f:(fun i (name, cpu) ->
      if i = cpu_index - 1 then (name, updated_cpu)
      else (name, cpu))
  in

  let new_state = { state with
    deck = new_deck;
    discard_pile = new_discard_pile;
    cpus = updated_cpus;
    current_player_index = next_player_index state
  } in

  (new_state, card, cpu_index)

let () = initialize_game ()

let () =
  Dream.run
    ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router [

    (* Handle the player's turn *)
    Dream.post "/play" (fun request ->
      match !game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        if state.current_player_index <> 0 then
          Dream.html "Not your turn to place a card"
        else
          match Dream.query request "card_index" with
          | None -> Dream.html "No card selected."
          | Some card_index_str ->
            match Int.of_string_opt card_index_str with
            | None ->
              Dream.html ~code:400 "Invalid card index."
            | Some card_index ->
              let player_name, player = List.hd_exn state.players in
              let top_discard = List.hd_exn state.discard_pile in
              let hand = Player.get_hand player in

              if any_playable_card hand top_discard then
                begin
                  if card_index < 0 || card_index >= List.length hand then
                    Dream.html ~code:400 "Invalid card index."
                  else
                    let card = List.nth_exn hand card_index in
                    if UnoCard.is_playable
                         (UnoCardInstance.get_color card) (UnoCardInstance.get_value card)
                         (UnoCardInstance.get_color top_discard) (UnoCardInstance.get_value top_discard)
                    then
                      (* Play the chosen card *)
                      let player = Player.play_card player card top_discard in
                      let discard_pile = card :: state.discard_pile in
                      let state = { state with
                        discard_pile;
                        players = [(player_name, player)];
                        current_player_index = 1;
                      } in
                      game_state := Some state;

                      (* Handle skip card if played *)
                      let state = handle_skip_card (Option.value_exn !game_state) card in
                      game_state := Some state;

                      (* Player index who played is always 0 here *)
                      let state = handle_reverse_card (Option.value_exn !game_state) card 0 in
                      game_state := Some state;

                      (* Check if player has won after handling skip and reverse *)
                      let _, player = List.hd_exn state.players in
                      if Player.has_won player then
                        Dream.html "Player1 has won the game. Game over."
                      else 
                        Dream.html (Printf.sprintf "Card played successfully!")
                    else
                      Dream.html ~code:400 "Card is not playable. Please choose a different card."
                end
              else
                (* No playable cards in hand, draw one from the deck *)
                let (drawn_card, new_deck) = Deck.draw_card state.deck in
                let player = Player.add_cards player [drawn_card] in
                let state = { state with deck = new_deck } in

                (* Describe the drawn card *)
                let drawn_color = UnoCardInstance.get_color drawn_card in
                let drawn_value = UnoCardInstance.get_value drawn_card in
                let drawn_card_str =
                  Printf.sprintf "%s %s"
                    (Sexp.to_string (UnoCard.sexp_of_color drawn_color))
                    (Sexp.to_string (UnoCard.sexp_of_value drawn_value))
                in

                if UnoCard.is_playable
                     (UnoCardInstance.get_color drawn_card) (UnoCardInstance.get_value drawn_card)
                     (UnoCardInstance.get_color top_discard) (UnoCardInstance.get_value top_discard)
                then
                  (* Play the drawn card *)
                  let player = Player.play_card player drawn_card top_discard in
                  let discard_pile = drawn_card :: state.discard_pile in
                  let state = { state with
                    discard_pile;
                    players = [(player_name, player)];
                    current_player_index = 1;
                  } in
                  game_state := Some state;

                  (* Handle skip if the drawn card played is skip *)
                  let state = handle_skip_card (Option.value_exn !game_state) drawn_card in
                  game_state := Some state;

                  (* Player played so who_played=0 *)
                  let state = handle_reverse_card (Option.value_exn !game_state) drawn_card 0 in
                  game_state := Some state;

                  (* Check if player has won after possibly skipping and reversing *)
                  let _, player = List.hd_exn state.players in
                  if Player.has_won player then
                    Dream.html "Player1 has won the game. Game over."
                  else
                    let top_discard = List.hd_exn state.discard_pile in
                    let top_color = UnoCardInstance.get_color top_discard in
                    let top_value = UnoCardInstance.get_value top_discard in
                    let top_card_str =
                      Printf.sprintf "%s %s"
                        (Sexp.to_string (UnoCard.sexp_of_color top_color))
                        (Sexp.to_string (UnoCard.sexp_of_value top_value))
                    in
                    Dream.html (Printf.sprintf
                      "No playable card in your hand; you drew %s and played it! Top card: %s"
                      drawn_card_str top_card_str)
                else
                  (* Keep the drawn card and next turn *)
                  let state = { state with
                    players = [(player_name, player)];
                    current_player_index = 1;
                  } in
                  game_state := Some state;
                  Dream.html (Printf.sprintf
                    "No playable card in your hand; you drew %s and kept it. Turn ends."
                    drawn_card_str));

    (* Handle the game state *)
    Dream.get "/" (fun _ ->
      match !game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        let top_discard = List.hd_exn state.discard_pile in
        let top_color = UnoCardInstance.get_color top_discard in
        let top_value = UnoCardInstance.get_value top_discard in
        let top_card_str =
          Printf.sprintf "%s %s"
            (Sexp.to_string (UnoCard.sexp_of_color top_color))
            (Sexp.to_string (UnoCard.sexp_of_value top_value))
        in

        let player_name, player = List.hd_exn state.players in
        let hand = Player.get_hand player in
        let hand_str = String.concat ~sep:", " (
          List.map hand ~f:(fun card ->
            let color = UnoCardInstance.get_color card in
            let value = UnoCardInstance.get_value card in
            Printf.sprintf "%s %s"
              (Sexp.to_string (UnoCard.sexp_of_color color))
              (Sexp.to_string (UnoCard.sexp_of_value value))
          )
        ) in
        Dream.html (Printf.sprintf
          "Welcome to UNO, %s!<br>Your hand: %s<br>Top of Discard Pile: %s"
          player_name hand_str top_card_str)
    );

    (* Handle the CPU turns *)
    Dream.post "/cpu_turn" (fun _ ->
      match !game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        if state.current_player_index = 0 then
          Dream.html "It's the player's turn."
        else
          let (new_state, chosen_card, cpu_index) = play_cpu_turn state in
          game_state := Some new_state;

          let new_top = List.hd_exn new_state.discard_pile in
          if UnoCardInstance.equal chosen_card new_top then
            (* CPU played the chosen_card *)
            let state = handle_skip_card (Option.value_exn !game_state) chosen_card in
            game_state := Some state;

            (* CPU played, who_played = cpu_index (1 or 2) *)
            let state = handle_reverse_card (Option.value_exn !game_state) chosen_card cpu_index in
            game_state := Some state;
    
            let (_, updated_cpu) = List.nth_exn state.cpus (cpu_index - 1) in
            if CPU.has_won updated_cpu then
              Dream.html (Printf.sprintf "CPU%d has won the game. Game over." cpu_index)
            else 
              let played_color = UnoCardInstance.get_color chosen_card in
              let played_value = UnoCardInstance.get_value chosen_card in
              let played_card_str =
                Printf.sprintf "%s %s"
                  (Sexp.to_string (UnoCard.sexp_of_color played_color))
                  (Sexp.to_string (UnoCard.sexp_of_value played_value))
              in
              Dream.html (Printf.sprintf "CPU%d turn completed. Played: %s" cpu_index played_card_str)
          else
            (* CPU did not play the card, only drew it *)
            Dream.html (Printf.sprintf "CPU%d turn completed. Drew a card." cpu_index)
    );

    Dream.get "/cpu_hands" (fun _ ->
      match !game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        let cpu_hands =
          List.map state.cpus ~f:(fun (name, cpu) ->
            let hand = CPU.get_hand cpu in
            let hand_str = String.concat ~sep:", " (
              List.map hand ~f:(fun card ->
                let color = UnoCardInstance.get_color card in
                let value = UnoCardInstance.get_value card in
                Printf.sprintf "%s %s"
                  (Sexp.to_string (UnoCard.sexp_of_color color))
                  (Sexp.to_string (UnoCard.sexp_of_value value))
              )
            ) in
            Printf.sprintf "%s's hand: %s" name hand_str
          )
        in
        Dream.html (String.concat ~sep:"<br>" cpu_hands)
    );
  ]