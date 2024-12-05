open Core
open Uno_card

module Player = struct
  type t = {
    name : string;
    hand : UnoCardInstance.t list
  }

  let create (name : string) : t =
    {name; hand = []}

  let get_name (player : t) : string =
    player.name

  let get_hand (player : t) : UnoCardInstance.t list =
    player.hand

  let add_cards (player : t) (cards : UnoCardInstance.t list) : t =
    {player with hand = player.hand @ cards}

  let play_card (player : t) (card : UnoCardInstance.t) (top_card : UnoCardInstance.t) : t =
    if UnoCard.is_playable 
      (UnoCardInstance.get_color card) (UnoCardInstance.get_value card) 
      (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card)
    then
      let rec remove_first_occurrence hand =
        match hand with
        | [] -> failwith "Card must be in hand. Should not be reached."
        | c :: rest ->
          if UnoCardInstance.equal c card then rest
          else c :: remove_first_occurrence rest
      in
      {player with hand = remove_first_occurrence player.hand}
    else
      failwith "Card is not playable"

  let has_won (player : t) : bool =
    List.is_empty player.hand
end