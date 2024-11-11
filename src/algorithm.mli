
module type Algorithm = sig
  val rank_card : Card.t -> hand:Card.t list -> opponents:int list -> int
  (** [rank_card card ~hand ~opponents] computes the rank of [card] based on the current [hand] 
      and the [opponents]' card counts. A higher rank indicates a better choice. *)
  
  val minimax : Card.t list -> Card.t list list -> int list -> int -> bool -> Card.t
  (** [minimax hand opponent_hands opponent_counts depth is_maximizing] determines the optimal 
    card to play using the minimax algorithm.
    - [hand]: The CPU's hand.
    - [opponent_hands]: The hands of the opponents.
    - [opponent_counts]: The number of cards each opponent has.
    - [depth]: The depth to search.
    - [is_maximizing]: Whether the current player is maximizing or minimizing the ranking. *)
  
end