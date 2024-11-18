open Core

module Card = struct
  type color = Red | Yellow | Green | Blue | Wild
  (** [color] is the possible color for the cards. *)

  type value = Number of int | Skip | Reverse | DrawTwo | DrawFour | Wild

  type t = { color : color; value : value }
  (** [t] represents a card using a combination of [color] and [value]. *)

  let create (card_color : color) (card_value : value) = 
    {card_color; card_value}

  let get_color (card : t) =
    card.color

  let get_value (card : t) =
    card.value

  let is_playable (card1 : t) (card2 : t) =
    match card1, card2 with
    | {color = Wild, _}, _ -> true
    | {color = c1; value = v1}, 
      {color = c2; value = v2} -> c1 = c2 || v1 = v2
end