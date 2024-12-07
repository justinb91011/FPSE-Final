open Uno_card

module Deck : sig
  type t = UnoCardInstance.t list
  (** [t] represents the entire deck of cards. *)

  val create_deck : unit -> t
  (** [create] creates and returns a standard 108-card UNO deck. *)

  val shuffle : t -> t
  (** [shuffle deck] returns a new deck with the cards shuffled. *)

  val draw_card : t -> UnoCardInstance.t * t
  (** [draw_card deck] removes and returns the top card of [deck] and the updated deck. *)

  val draw_cards : int -> t -> UnoCardInstance.t list * t
  (** [draw_cards n deck] removes and returns a list of [n] cards from [deck] and the updated deck. *)

  val add_card : UnoCardInstance.t -> t -> t
  (** [add_card card deck] adds [card] to the bottom of [deck] and returns the updated deck. *)

  val remaining_cards : t -> int
  (** [remaining_cards deck] returns the number of cards left in [deck]. *)
end
