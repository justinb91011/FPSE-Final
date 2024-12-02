open Core
open Uno_card

module Deck = struct
  type t = UnoCardInstance.t list

  let create_deck () : t =
    let rec deck_creator acc values curr_color =
      match curr_color, values with
      | _, [] -> acc
      | UnoCard.WildColor, x :: xs ->
        if (UnoCard.equal_value x WildValue || UnoCard.equal_value x DrawFour) then
          deck_creator ((UnoCardInstance.create curr_color x) :: acc) xs curr_color
        else
          deck_creator acc xs curr_color
      | _, x :: xs ->
        if (UnoCard.equal_value x WildValue || UnoCard.equal_value x DrawFour) then
          deck_creator acc xs curr_color
        else
          deck_creator ((UnoCardInstance.create curr_color x) :: acc) xs curr_color
      in
    let color = [UnoCard.Red; UnoCard.Yellow; UnoCard.Green; UnoCard.Blue; UnoCard.WildColor] in
    let numbers =
      List.concat_map
        ~f:(fun x ->
          if x > 0 then [UnoCard.Number x; Number x]
          else [Number x])
        (List.init 10 ~f:(fun x -> x))
    in
    let special_values = [UnoCard.Skip; Skip; Reverse; Reverse; 
                          DrawTwo; DrawTwo; 
                          DrawFour; DrawFour; DrawFour; DrawFour; 
                          WildValue; WildValue; WildValue; WildValue] in
    let values = numbers @ special_values in
    List.fold_left ~init:[] colors ~f:(fun acc color -> deck_creator acc values color)

  let shuffle (deck : t) : t = 
    List.permute deck
  
  let draw_card (deck : t) : UnoCardInstance.t * t =
    match deck with
    | [] -> failwith "Cannot draw from an empty deck."
    | top_card :: rest -> (top_card, rest)

  let draw_cards n (deck : t) : UnoCardInstance.t list * t =
    let rec draw acc n deck = 
      if n = 0 then (List.rev acc, deck)
      else
        match deck with
        | [] -> failwith "Not enough cards to draw."
        | top_card :: rest -> draw (top_card :: acc) (n - 1) rest
    in
    draw [] n deck

  let add_card (card : UnoCardInstance.t) (deck : t) : t =
    deck @ [card]

  let remaining_cards (deck : t) : int =
    List.length deck
end