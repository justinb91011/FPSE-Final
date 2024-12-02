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

  let play_card (player : t) (card : UnoCardInstance.t) : t =
    if UnoCard.is_playable (UnoCardInstance.get_color card) (UnoCardInstance.get_value card) (UnoCardInstance.get_color card) (UnoCardInstance.get_value card) then
      player
    else
      player

  let choose_card (_player : t) (options : UnoCardInstance.t list) : UnoCardInstance.t =
    match options with
    | [] -> failwith "No playable cards available."
    | card :: _ -> card

  let has_won (player : t) : bool =
    List.is_empty player.hand
end