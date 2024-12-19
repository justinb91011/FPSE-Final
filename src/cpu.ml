open Core
open Uno_card
open Deck
open Algorithm  (* Ensure that Algorithm module is accessible *)

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

  (* Helper function to remove the first occurrence of a card from the hand *)
  let remove_first_occurrence hand card =
    let rec aux acc = function
      | [] -> List.rev acc  (* Should not happen if card is in hand *)
      | c :: rest ->
        if UnoCardInstance.equal c card then
          List.rev_append acc rest
        else
          aux (c :: acc) rest
    in
    aux [] hand

  (* Helper function to count the number of cards of a specific color in the CPU's hand *)
  let count_color hand color =
    List.count hand ~f:(fun c -> UnoCard.equal_color (UnoCardInstance.get_color c) color)

  (* Helper function to determine the dominant color in the CPU's hand *)
  let dominant_color hand =
    let colors = [UnoCard.Red; UnoCard.Blue; UnoCard.Green; UnoCard.Yellow] in
    let color_counts = List.map colors ~f:(fun color -> (color, count_color hand color)) in
    let max_count = 
      List.fold color_counts ~init:0 ~f:(fun acc (_, count) -> if count > acc then count else acc)
    in
    let dominant_colors = 
      List.filter color_counts ~f:(fun (_, count) -> count = max_count)
      |> List.map ~f:fst
    in
    match dominant_colors with
    | [color] -> color  (* Single dominant color *)
    | _ -> List.random_element_exn colors  (* Multiple dominant colors or no cards: choose randomly *)

  (* Existing choose_card function for Easy difficulty *)
  let choose_card (cpu : t) (top_card : UnoCardInstance.t) (deck : Deck.t) : UnoCardInstance.t * Deck.t * t * string option =
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
          (* Drawn card is playable *)
          if UnoCard.equal_value (UnoCardInstance.get_value drawn_card) UnoCard.WildValue ||
              UnoCard.equal_value (UnoCardInstance.get_value drawn_card) UnoCard.DrawFour
          then 
            let color_chosen = List.random_element_exn ["Blue"; "Red"; "Green"; "Yellow"] in
            (drawn_card, updated_deck, cpu, Some color_chosen)
          else 
          (drawn_card, updated_deck, cpu, None)
        else
          (* Drawn card is not playable; add it to the CPU's hand *)
          let updated_cpu = { cpu with hand = drawn_card :: cpu.hand } in
          (drawn_card, updated_deck, updated_cpu, None)
      else
        (* There is at least one playable card in hand, choose one at random *)
        let chosen_card = List.random_element_exn playable_cards in
        let updated_hand = remove_first_occurrence cpu.hand chosen_card in
        let updated_cpu = { cpu with hand = updated_hand } in
        if UnoCard.equal_color (UnoCardInstance.get_color chosen_card) UnoCard.WildColor then
          let color_chosen = List.random_element_exn ["Blue"; "Red"; "Green"; "Yellow"] in
          (chosen_card, deck, updated_cpu, Some color_chosen)
        else
          (chosen_card, deck, updated_cpu, None)

  
  (* New function for Hard difficulty *)
  let choose_card_hard (cpu : t) (top_card : UnoCardInstance.t) (deck : Deck.t) (opponents : int list) : UnoCardInstance.t * Deck.t * t * string option =
    (* Implementing Hard CPU logic *)
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
        if UnoCard.equal_value (UnoCardInstance.get_value drawn_card) UnoCard.WildValue ||
            UnoCard.equal_value (UnoCardInstance.get_value drawn_card) UnoCard.DrawFour
        then
          let color_chosen = List.random_element_exn ["Blue"; "Red"; "Green"; "Yellow"] in
          (drawn_card, updated_deck, cpu, Some color_chosen)
        else
        (drawn_card, updated_deck, cpu, None)
      else
        (* Drawn card is not playable; add it to the CPU's hand *)
        let updated_cpu = { cpu with hand = drawn_card :: cpu.hand } in
      (drawn_card, updated_deck, updated_cpu, None)
    else
      (* There are playable cards; rank them using rank_card *)
      let ranked_cards =
        List.map playable_cards ~f:(fun card ->
          let rank = 
            Algorithm.rank_card card ~hand:cpu.hand ~opponents ~top_card 
        in
          (card, rank)
        )
      in
      (* Find the maximum rank *)
      let max_rank =
        List.fold ranked_cards ~init:0 ~f:(fun acc (_, rank) ->
        if rank > acc then rank else acc
        )
        in
        (* Gather all cards with the maximum rank *)
      let top_ranked_cards =
        List.filter ranked_cards ~f:(fun (_, rank) -> rank = max_rank)
        |> List.map ~f:fst
      in
      (* Separate Wild cards from other top-ranked cards *)
      let wild_cards, non_wild_cards =
      List.partition_tf top_ranked_cards ~f:(fun card ->
          UnoCard.equal_value (UnoCardInstance.get_value card) UnoCard.WildValue ||
          UnoCard.equal_value (UnoCardInstance.get_value card) DrawFour
      )
      in
      (* Function to choose a card based on color dominance *)
      let choose_based_on_color cards =
      (* Determine the dominant color in CPU's hand *)
      let dominant = dominant_color cpu.hand in
      (* Filter cards matching the dominant color *)
      let matching_color_cards =
        List.filter cards ~f:(fun card ->
        UnoCard.equal_color (UnoCardInstance.get_color card) dominant
        )
      in
      match matching_color_cards with
      | [] -> List.random_element_exn cards  (* No matching color; choose randomly *)
      | c :: _ -> c  (* Choose the first matching color card *)
      in
      (* Determine the chosen card *)
      let chosen_card =
        match non_wild_cards, wild_cards with
      | [], [] -> failwith "No playable cards found." [@coverage off] (* Will never reach this case*)
      | _, [] ->
        (* Only non-wild top-ranked cards *)
        choose_based_on_color non_wild_cards
      | [], _ ->
        (* Only wild cards among top-ranked cards *)
        List.random_element_exn wild_cards
      | non_wild, wild ->
        (* Both non-wild and wild cards have top rank *)
        (* Prefer non-wild cards over wild cards *)
        if List.length non_wild >= List.length wild then
          choose_based_on_color non_wild
        else
          List.random_element_exn wild
        in
      (* Remove the chosen card from the CPU's hand *)
      let updated_hand = remove_first_occurrence cpu.hand chosen_card in
      let updated_cpu = { cpu with hand = updated_hand } in
      (* Determine the color to choose if the card is a Wild or Draw Four *)
    if UnoCard.equal_value (UnoCardInstance.get_value chosen_card) UnoCard.WildValue ||
        UnoCard.equal_value (UnoCardInstance.get_value chosen_card) DrawFour then
    begin
      let colors = [UnoCard.Red; UnoCard.Blue; UnoCard.Green; UnoCard.Yellow] in
      let color_counts = List.map colors ~f:(fun color -> (color, count_color cpu.hand color)) in
      let max_count = 
        List.fold color_counts ~init:0 ~f:(fun acc (_, count) ->
          if count > acc then count else acc
        )
      in
      let dominant_colors =
        List.filter color_counts ~f:(fun (_, count) -> count = max_count)
        |> List.map ~f:fst
      in
      (* Determine the color to choose *)
      let color_chosen =
        match List.length dominant_colors with
        | 0 -> List.random_element_exn ["Blue"; "Red"; "Green"; "Yellow"]  (* No cards: choose randomly *)
        | 1 -> 
          (match List.hd_exn dominant_colors with
          | Red -> "Red"
          | Blue -> "Blue"
          | Green -> "Green"
          | Yellow -> "Yellow"
          | WildColor -> "Blue")  (* Default to Blue if somehow WildColor *)
        | _ -> 
          (* Multiple colors with the same max count; choose randomly *)
          let color = List.random_element_exn dominant_colors in
          match color with
          | Red -> "Red"
          | Blue -> "Blue"
          | Green -> "Green"
          | Yellow -> "Yellow"
          | WildColor -> "Blue"  (* Default to Blue if somehow WildColor *) [@coverage off]
      in
      (chosen_card, deck, updated_cpu, Some color_chosen)
    end
  else
    (chosen_card, deck, updated_cpu, None)

  let has_won (cpu : t) : bool =
    List.is_empty cpu.hand
end