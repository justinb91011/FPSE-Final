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
} [@@ocaml.warning "-69"]

let game_state = ref None

(* Helper function to check if there's any playable card in hand *)
(* let any_playable_card hand top_card =
  List.exists hand ~f:(fun c ->
    UnoCard.is_playable
      (UnoCardInstance.get_color c) (UnoCardInstance.get_value c)
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card)
  ) *)

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

let play_cpu_turn state =
  let _, current_cpu = List.nth_exn state.cpus (state.current_player_index - 1) in
  let top_discard = List.hd_exn state.discard_pile in

  let card, new_deck, updated_cpu = CPU.choose_card current_cpu top_discard state.deck in
  if UnoCard.is_playable
       (UnoCardInstance.get_color card) (UnoCardInstance.get_value card)
       (UnoCardInstance.get_color top_discard) (UnoCardInstance.get_value top_discard)
  then
    (* Play the chosen card *)
    let new_discard_pile = card :: state.discard_pile in
    let updated_cpus =
      List.mapi state.cpus ~f:(fun i (name, cpu) ->
        if i = state.current_player_index - 1 then (name, updated_cpu)
        else (name, cpu))
    in
    { state with
      deck = new_deck;
      discard_pile = new_discard_pile;
      cpus = updated_cpus;
      current_player_index = next_player_index state
    }
  else
    (* Invalid choice should not happen, but handle gracefully *)
    state

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
          Dream.html "Not your turn to play a card."
        else
          match Dream.query request "card_index" with
          | None -> Dream.html "No card selected."
          | Some card_index_str ->
            match Int.of_string_opt card_index_str with
            | None -> Dream.html ~code:400 "Invalid card index."
            | Some card_index ->
              let player_name, player = List.hd_exn state.players in
              let top_discard = List.hd_exn state.discard_pile in
              let hand = Player.get_hand player in

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
                  let state = { state with
                    discard_pile = card :: state.discard_pile;
                    players = [(player_name, player)];
                    current_player_index = next_player_index state
                  } in
                  game_state := Some state;
                  Dream.html "Card played successfully."
                else
                  Dream.html ~code:400 "Card is not playable."
    );

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
          let state = play_cpu_turn state in
          game_state := Some state;
          Dream.html "CPU turn completed."
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
