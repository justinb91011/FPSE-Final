(* This module will serve as the basis for the UNO playing cards *)

module type Card = sig 
  type color = Red | Yellow | Green | Blue | Wild
  (** [color] is the possible color for the cards. *)

  type value = Number of int | Skip | Reverse | DrawTwo | DrawFour | Wild

  type t = { color : color; value : value }
  (** [t] represents a card using a combination of [color] and [value]. *)

  val create : color -> value -> t
  (** [create color value] returns a card of the given color and value. *)

  val get_color : t -> color
  (** [get_color card] returns the color of the [card]. *)

  val get_value : t -> value
  (** [get_value card] returns the value of the [card]. *)

  val is_playable : t -> t -> bool
  (** [is_playable card1 card2] returns [true] if [card1] can be played on top of [card2], 
      based on color, value, or wild rules. *)

  val rank_card : t -> hand:t list -> opponents:int list -> int
  (** [rank_card card ~hand ~opponents] computes the rank of [card] based on the current [hand] 
      and the [opponents]' card counts. Ranking follows the rules for number cards, action cards, 
      and wild cards specified in the CPU algorithm. A higher rank indicates a better choice. *)

  val choose_color : hand:t list -> color
  (** [choose_color ~hand] selects the optimal color to play based on the colors in the given [hand]. 
      If there is a tie, it selects a color at random. *)
end 
