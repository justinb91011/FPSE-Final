type t
(** [t] type that represents the player, either AI or human. *)
val create_player : string -> t
(** [create_player s] create a player with their name as string s and return the player. *)
val get_name : t -> string
(** [get_name t] given a player [t], return their name. *)
val get_hand : t -> card list
(** [get_hand t] given a player [t], return their hand as a list of cards. *)
val add_card : t -> card -> t
(** [add_card t card] given a player [t], add a [card] to their hand and return the updated player. *)
val remove_card : t -> card -> t
(** [remove card t card] given a player [t], remove a [card] and return the updated player. *)
val has_playable_card : card -> t -> bool
(** [has_playable_card card t] given the [card] at top of the discard pile, and a player [t], return true
    if the player has a card that's playable, false otherwise. *)
val choose_card : difficulty:int -> card -> t -> card option
(** [choose_card difficulty card t] given a AI player [t] with difficulty level [difficulty] and [card] at the 
    top of the discard pile, return either Some card if a playable card exists (depending on difficulty) or None 
    if no card is playable. *)