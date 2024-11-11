
module type Game = sig
  module Player : Player
  (** [Player] represents the human player module included in the game. *)

  module CPU : CPU
  (** [CPU] represents the CPU player module included in the game. *)

  type t
  (** [t] represents the state of the game. *)

  val init : players:int -> difficulty:CPU.difficulty list -> t
  (** [init players difficulty] initializes the game state with the specified number of players
      (1 human player and the rest CPU players) and a list of CPU difficulties. *)

  val current_player : t -> int
  (** [current_player game] returns the index of the current player whose turn it is. *)

  val get_player : t -> int -> Player.t option
  (** [get_player game player_index] returns the [Player.t] instance for the given [player_index]
      if the player is human, or [None] if it is a CPU. *)

  val get_cpu : t -> int -> CPU.t option
  (** [get_cpu game player_index] returns the [CPU.t] instance for the given [player_index]
      if the player is a CPU, or [None] if it is the human player. *)

  val top_card : t -> Card.t
  (** [top_card game] returns the top card of the discard pile, which determines valid plays. *)

  val get_player_hand : t -> int -> Card.t list option
  (** [get_player_hand game player_index] returns [Some hand] if the caller is authorized to see 
      their own hand (e.g., the current player), otherwise returns [None]. *)

  val get_opponent_card_counts : t -> int -> int list
  (** [get_opponent_card_counts game player_index] returns a list of the number of cards held by
      each opponent relative to [player_index]. For example, if [player_index] is 1, the result
      excludes player 1's card count but includes counts for all other players. *)

  val draw_card : t -> t
  (** [draw_card game] updates the game state by making the current player draw a card from the deck. *)

  val play_card : t -> Card.t -> t
  (** [play_card game card] updates the game state by playing the given [card] for the current player. *)

  val next_turn : t -> t
  (** [next_turn game] updates the game state to proceed to the next player's turn. *)

  val is_game_over : t -> bool
  (** [is_game_over game] returns [true] if the game has ended (one player has no cards left), 
      otherwise [false]. *)

  val get_winner : t -> int option
  (** [get_winner game] returns [Some player_index] of the winning player if the game is over, 
      otherwise returns [None]. *)
end