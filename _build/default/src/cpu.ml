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

  let get_difficulty (cpu : t) : difficulty =
    cpu.diff

  let get_hand (cpu : t) : UnoCardInstance.t list = 
    cpu.hand

  let add_cards (cpu : t) (cards : UnoCardInstance.t list) : t =
    { cpu with hand = cpu.hand @ cards }

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
        (* No playable card in hand, draw a card from the deck *)
        let drawn_card, updated_deck = Deck.draw_card deck in
        (* Check if the drawn card is playable *)
        if UnoCard.is_playable
             (UnoCardInstance.get_color drawn_card) (UnoCardInstance.get_value drawn_card)
             (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card)
        then
          (* Drawn card is playable; play it immediately without adding to hand *)
          (drawn_card, updated_deck, cpu)
        else
          (* Drawn card is not playable; add it to the CPU's hand *)
          let updated_cpu = { cpu with hand = drawn_card :: cpu.hand } in
          (drawn_card, updated_deck, updated_cpu)
      else
        (* There is at least one playable card in hand, choose one at random *)
        let chosen_card = List.random_element_exn playable_cards in
        let rec remove_first_occurrence hand =
          match hand with
          | [] -> failwith "Card must be in hand. Should not be reached."
          | c :: rest ->
            if UnoCardInstance.equal c chosen_card then rest
            else c :: remove_first_occurrence rest
        in
        let updated_cpu = {cpu with hand = remove_first_occurrence cpu.hand} in
        (chosen_card, deck, updated_cpu)

    | Medium ->
      failwith "Medium difficulty not implemented yet." [@coverage off]
    | Hard ->
      failwith "Hard difficulty not implemented yet." [@coverage off]

  let has_won (cpu : t) : bool =
    List.is_empty cpu.hand

end