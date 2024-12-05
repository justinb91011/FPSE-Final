open Core
open Uno_card
open Deck 

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
  
      let choose_card (cpu : t) (top_card : UnoCardInstance.t) (deck : Deck.t) : UnoCardInstance.t * Deck.t * t =
          match cpu.diff with
          | Easy ->
            let playable_cards =
              List.filter ~f:(fun card ->
                  UnoCard.is_playable
                    (UnoCardInstance.get_color card) (UnoCardInstance.get_value card)
                    (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card))
                cpu.hand
            in
            if List.is_empty playable_cards then
              (* Draw a card if no playable cards *)
              let drawn_card, updated_deck = Deck.draw_card deck in
              let updated_cpu = { cpu with hand = drawn_card :: cpu.hand } in
              (drawn_card, updated_deck, updated_cpu) (* Return drawn card and the new deck *)
            else
            (* Play a random playable card *)
              let chosen_card = List.random_element_exn playable_cards in
              (chosen_card, deck, cpu)
            | Medium ->
            failwith "Medium difficulty not implemented yet."
            | Hard ->
            failwith "Hard difficulty not implemented yet."
        

  let has_won (cpu : t) : bool =
    List.is_empty cpu.hand

end
