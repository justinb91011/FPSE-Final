open Core

module type Card_game_rules = sig
  type color [@@deriving compare, equal, sexp]
  (** [color] is the possible color for the cards. *)

  type value [@@deriving compare, equal, sexp]

  val is_playable : color -> value -> color -> value -> bool
  (** [is_playable card1 card2] returns [true] if [card1] can be played on top of [card2], 
      based on color, value, or wild rules. *)
end

module Make (Card : Card_game_rules) = struct  
  type t = { color : Card.color; value : Card.value } [@@deriving compare, equal, sexp]
  (** [t] represents a card using a combination of [color] and [value]. *)

  let create (card_color : Card.color) (card_value : Card.value) = 
    {color = card_color; value = card_value}

  let get_color (card : t) =
    card.color

  let get_value (card : t) =
    card.value
end