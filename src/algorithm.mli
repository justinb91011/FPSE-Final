(* open Card *)
open Uno_card

module Algorithm : sig
  val rank_card : UnoCardInstance.t -> hand:UnoCardInstance.t list -> opponents:int list -> top_card:UnoCardInstance.t -> int
  (** [rank_card card ~hand ~opponents ~top_card] computes the rank of [card] based on the current [hand] 
      and the [opponents]' card counts. A higher rank indicates a better choice. *)
  
  val minimax : UnoCardInstance.t list -> UnoCardInstance.t -> int list -> int -> bool -> UnoCardInstance.t
  (** [minimax hand opponent_hands opponent_counts depth is_maximizing] determines the optimal 
    card to play using the minimax algorithm.
    - [hand]: The CPU's hand.
    - [top_card]: The top card in the discard pile.
    - [opponent_counts]: The number of cards each opponent has.
    - [depth]: The depth to search.
    - [is_maximizing]: Whether the current player is maximizing or minimizing the ranking. *)
end