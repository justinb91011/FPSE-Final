(* run_game.ml *)

open Core
(* open Lwt.Infix *)
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
  direction : int;
} [@@ocaml.warning "-69"]

let game_state = ref None

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

let () = initialize_game ()

let () =
  Dream.run
    ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _ ->
      match !game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        let top_discard = List.hd_exn state.discard_pile in
        let top_color = UnoCardInstance.get_color top_discard in
        let top_value = UnoCardInstance.get_value top_discard in
        let top_card_str = Printf.sprintf "%s %s"
          (Sexp.to_string (UnoCard.sexp_of_color top_color))
          (Sexp.to_string (UnoCard.sexp_of_value top_value)) in

        let player_name, player = List.hd_exn state.players in
        let hand = Player.get_hand player in
        let hand_str = String.concat ~sep:", " (List.map hand ~f:(fun card ->
          let color = UnoCardInstance.get_color card in
          let value = UnoCardInstance.get_value card in
          Printf.sprintf "%s %s"
            (Sexp.to_string (UnoCard.sexp_of_color color))
            (Sexp.to_string (UnoCard.sexp_of_value value))
        )) in
        Dream.html (Printf.sprintf
          "Welcome to UNO, %s!<br>Your hand: %s<br>Top of Discard Pile: %s"
          player_name hand_str top_card_str)
    );

    Dream.post "/play" (fun request ->
      match !game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        (* First check if it's Player1's turn (current_player_index = 0) *)
        if state.current_player_index <> 0 then
          Dream.html "Not your turn to place a card"
        else
          match Dream.query request "card_index" with
          | None -> Dream.html "No card selected."
          | Some card_index_str ->
            (try
               let card_index = Int.of_string card_index_str in
               let player_name, player = List.hd_exn state.players in
               let hand = Player.get_hand player in
               let card = List.nth_exn hand card_index in
               let top_discard = List.hd_exn state.discard_pile in

               (* Directly call play_card; it will raise if not playable *)
               let player = Player.play_card player card top_discard in

               let discard_pile = card :: state.discard_pile in
               let state = { state with
                 discard_pile;
                 players = [(player_name, player)];
                 current_player_index = 1; (* Update turn to the next player (CPU) *)
               } in
              game_state := Some state;
              (* Now get the new top card information *)
              let top_discard = List.hd_exn state.discard_pile in
              let top_color = UnoCardInstance.get_color top_discard in
              let top_value = UnoCardInstance.get_value top_discard in
              let top_card_str =
                Printf.sprintf "%s %s"
                  (Sexp.to_string (UnoCard.sexp_of_color top_color))
                  (Sexp.to_string (UnoCard.sexp_of_value top_value))
              in
              Dream.html (Printf.sprintf "You played a good card! The top card is now: %s" top_card_str)
             with
             | Failure _ ->
                Dream.html ~code:400 "Card is not playable on the current discard pile."
             | _ ->
                Dream.html ~code:400"Invalid card index."))
  ]