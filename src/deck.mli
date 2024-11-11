type t
(** [t] represents the entire deck of cards, in this case a list. *)
val create_deck : unit -> t
(** [create_deck] creates and returns a standard 108 card UNO deck. *)
val shuffle : t -> t
(** [shuffle t] given a deck, produced a shuffle deck. *)
val draw_card : t -> card * t
(** [draw_card t] given a deck, produces the drawn card and the updated deck. *)
val draw_cards : int -> t -> card list * t
(** [draw_cards int] given a deck and an int, produce a list of drawn cards of length int and the updated deck. *)
val add_card : card -> t -> t
(** [add_card card t] add a [card] back into the deck [t] and produce an updated deck. *)
val remaining_cards : t -> int
(** [remaining_cards t] given a deck [t] returns an int that represents the number of cards still available. *)
