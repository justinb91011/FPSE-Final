open Uno_card

module Player : sig
  type t
  (** [t] represents a human player in the game. *)

  val create : string -> t
  (** [create name] initializes a player with the given [name]. *)

  val get_name : t -> string
  (** [get_name player] returns the player's name. *)

  val get_hand : t -> UnoCardInstance.t list
  (** [get_hand player] returns the list of cards in the player's hand. *)

  val add_cards : t -> UnoCardInstance.t list -> t
  (** [add_cards player cards] adds [cards] to the player's hand and returns the updated player. *)

  val play_card : t -> UnoCardInstance.t -> UnoCardInstance.t -> t
  (** [play_card player card top_card] removes the given [card] from the player's hand if it is playable. *)

  val has_won : t -> bool
  (** [has_won player] returns [true] if the player has no cards left, [false] otherwise. *)

end