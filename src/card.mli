(* This module will serve as the basis for the UNO playing cards *)

type color = Red | Yellow | Green | Blue | Wild
(** [color] is the possible color for the cards. *)
type value = Number of int | Skip | Reverse | DrawTwo | DrawFour | Wild
(** [value] is the possible values for the cards. *)
type card = { color : color ; value : value }
(** [card] is the  type that represnets the card using color and value. *)
val create_card : color -> value -> card
(** [create_card color value] returns a card of given color and value. *)
val get_color : card -> color
(** [get_color card] returns the color of the [card]. *)
val get_value : card -> value
(** [get_value card] returns the value of [card]. *)
val is_playable : card -> card -> bool
(** [is_playable card card] returns true if a card is playable, false otherwise. *)