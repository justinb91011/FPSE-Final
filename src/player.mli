
module type Player = sig
  type t
  (** [t] represents a human player in the game. *)

  val create : string -> t
  (** [create name] initializes a player with the given [name]. *)

  val get_hand : t -> Card.t list
  (** [get_hand player] returns the list of cards in the player's hand. *)

  val add_cards : t -> Card.t list -> t
  (** [add_cards player cards] adds [cards] to the player's hand and returns the updated player. *)

  val play_card : t -> Card.t -> t
  (** [play_card player card] removes the given [card] from the player's hand if it is playable. *)

  val choose_card : t -> Card.t list -> Card.t
  (** [choose_card player options] allows the player to select a card to play from [options]. *)

  val has_won : t -> bool
  (** [has_won player] returns [true] if the player has no cards left, [false] otherwise. *)

end