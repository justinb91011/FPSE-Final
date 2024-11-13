
module type CPU = sig
  type difficulty = Easy | Medium | Hard
  (** [difficulty] represents the CPU's difficulty level. *)

  type t
  (** [t] represents a CPU player in the game. *)

  val create : difficulty -> t
  (** [create difficulty] initializes a CPU player with the given [difficulty]. *)

  val get_hand : t -> Card.t list
  (** [get_hand cpu] returns the list of cards in the CPU player's hand. *)

  val add_cards : t -> Card.t list -> t
  (** [add_cards cpu cards] adds [cards] to the CPU player's hand and returns the updated CPU. *)

  val play_card : t -> Card.t -> t
  (** [play_card cpu card] removes the given [card] from the CPU player's hand if it is playable. *)

  val choose_card : t -> Card.t list -> opponents:int list -> Card.t
  (** [choose_card cpu options opponents] allows the CPU to select a card to play from [options]. 
      The decision depends on the [difficulty]:
      - Easy: Chooses a random card.
      - Medium: Alternates between random and algorithmic choice.
      - Hard: Strictly uses the ranking algorithm. *)

  val has_won : t -> bool
  (** [has_won cpu] returns [true] if the CPU player has no cards left, [false] otherwise. *)
end