(* run_game.ml *)

open Core
(* open Lwt.Infix *)
open Uno_card
open Deck
open Player
open Cpu

(* Define the game state type *)
type game_state = {
  deck : Deck.t;
  discard_pile : UnoCardInstance.t list;
  players : (string * Player.t) list;  (* List of players with their names *)
  cpus : (string * CPU.t) list;        (* List of CPUs with identifiers *)
  current_player_index : int;          (* Index to track whose turn it is *)
  direction : int;                     (* 1 for clockwise, -1 for counter-clockwise *)
} [@@ocaml.warning "-69"] 

(* Create a reference to store the game state *)
let game_state = ref None  (* Initially, there's no game state *)

(* Function to initialize the game state *)
let initialize_game () =
  (* Create and shuffle the deck *)
  let deck = Deck.create_deck () |> Deck.shuffle in

  (* Create players *)
  let player = Player.create "Player1" in
  let cpu1 = CPU.create CPU.Easy in
  let cpu2 = CPU.create CPU.Easy in

  (* Draw 7 cards for each player and update the deck accordingly *)
  let player_cards, deck = Deck.draw_cards 7 deck in
  let player = Player.add_cards player player_cards in

  let cpu1_cards, deck = Deck.draw_cards 7 deck in
  let cpu1 = CPU.add_cards cpu1 cpu1_cards in

  let cpu2_cards, deck = Deck.draw_cards 7 deck in
  let cpu2 = CPU.add_cards cpu2 cpu2_cards in

  (* Draw the top card to start the discard pile *)
  let top_card, deck = Deck.draw_card deck in
  let discard_pile = [top_card] in

  (* Initialize the game state *)
  let initial_state = {
    deck;
    discard_pile;
    players = [("Player1", player)];
    cpus = [("CPU1", cpu1); ("CPU2", cpu2)];
    current_player_index = 0;
    direction = 1;
  } in

  (* Update the game_state reference *)
  game_state := Some initial_state

(* Initialize the game state *)
let () = initialize_game ()

(* Start the Dream server *)
let () =
  Dream.run
    ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router [
    (* Root route to display the player's hand *)
    Dream.get "/" (fun _ ->
      match !game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        (* let open Player in  *)
        let player_name, player = List.hd_exn state.players in
        let hand = Player.get_hand player in
        let hand_str = String.concat ~sep:", " (List.map hand ~f:(fun card ->
          let color = UnoCardInstance.get_color card in
          let value = UnoCardInstance.get_value card in
          Printf.sprintf "%s %s"
            (Sexp.to_string (UnoCard.sexp_of_color color))
            (Sexp.to_string (UnoCard.sexp_of_value value))
        )) in
        Dream.html (Printf.sprintf "Welcome to UNO, %s!<br>Your hand: %s" player_name hand_str)
    );
    (* Additional routes can be added here *)
  ]