(* THIS IS OUR LIBRARY! *)
module type Card_game_rules = sig 
  type color [@@deriving compare, equal, sexp]
  (** [color] is the possible color for the cards. *)

  type value [@@deriving compare, equal, sexp]

  val is_playable : color -> value -> color -> value -> bool
  (** [is_playable card1 card2] returns [true] if [card1] can be played on top of [card2], 
      based on color, value, or wild rules. *)
end

module Make (Card : Card_game_rules) : sig
  type t [@@deriving compare, equal, sexp]
  (** [t] represents a card using a combination of [color] and [value]. *)

  val create : Card.color -> Card.value -> t
  (** [create color value] returns a card of the given color and value. *)

  val get_color : t -> Card.color
  (** [get_color card] returns the color of the [card]. *)

  val get_value : t -> Card.value
  (** [get_value card] returns the value of the [card]. *)
end 
