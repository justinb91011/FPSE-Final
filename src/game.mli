open Core
open Uno_card
open Deck
open Player
open Cpu

module Game : sig
    type game_state = {
        deck : Deck.t;
        discard_pile : UnoCardInstance.t list;
        players : (string * Player.t) list;
        cpus : (string * CPU.t) list;
        current_player_index : int;
        direction : int;  (* 1 for clockwise, -1 for counterclockwise *)
    }

    val initialize_game : unit -> unit
    (** [initialize_game ()] sets up the initial state of the game, including the player, CPUs, and the deck. *)

    val next_player_index : game_state -> int
    (** [next_player_index state] returns the index of the next player, considering the game's direction and the number of players. *)

    val handle_skip_card : game_state -> UnoCardInstance.t -> game_state
    (** [handle_skip_card state played_card] updates the game state if a skip card is played. *)

    val handle_reverse_card : game_state -> UnoCardInstance.t -> int -> game_state
    (** [handle_reverse_card state played_card who_played] updates the game state if a reverse card is played. *)

    val play_cpu_turn : game_state -> game_state * UnoCardInstance.t * int * string option
    (** [play_cpu_turn state] simulates a turn for the current CPU player and updates the game state. *)

    val any_playable_card : UnoCardInstance.t list -> UnoCardInstance.t -> bool
    (** [any_playable_card hand top_card] checks if any card in the player's hand is playable on the top card of the discard pile. *)
        
    val handle_draw_two : game_state -> UnoCardInstance.t -> game_state * string option
    (** [handle_draw_two state played_card] updates the game state if a draw two card is played. *)
    
    val handle_wild_card : game_state -> UnoCardInstance.t -> string option -> game_state option
    (** [handle_wild_card state played_card chosen_color] updates the game state if a wild card is played and a new color is chosen. *)
    
    val game_state : game_state option ref
    (** The current state of the game as a mutable reference. *)
end