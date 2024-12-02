open Core
open Uno_card

module CPU = struct
  type difficulty = Easy | Medium | Hard

  type t = {
    diff : difficulty;
    hand : UnoCardInstance.t list
  }

  let create (diff : difficulty) : t =
    { diff; hand = [] }

  let get_hand (cpu : t) : UnoCardInstance.t list = 
    cpu.hand

  let add_cards (cpu : t) (cards : UnoCardInstance.t list) : t =
    { cpu with hand = cpu.hand @ cards }

  let play_card (cpu : t) (card : UnoCardInstance.t) : t =
    if UnoCard.is_playable (UnoCardInstance.get_color card) (UnoCardInstance.get_value card) (UnoCardInstance.get_color card) (UnoCardInstance.get_value card) then
      cpu
    else
      cpu
      (* FILLER IMPLEMENTATION, might not need *)
  
  let choose_card (cpu : t) (options : UnoCardInstance.t list) =
    match cpu.diff with
    | Easy ->
      if List.is_empty options then
        failwith "No playable cards available."
      else
        List.random_element_exn options
    | Medium ->
      if Random.bool () then
        List.random_element_exn options
      else
        List.hd_exn options
        (* HERE IS WHERE WE WOULD USE OUR ALGORITHM *)
    | Hard ->
      if List.is_empty options then
        failwith "No playable cards available."
      else
        List.hd_exn options
        (* HERE IS WHERE WE WOULD USE OUR ALGORITHM *)

  let has_won (cpu : t) : bool =
    List.is_empty cpu.hand

end