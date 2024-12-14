open Core
open Uno_card

module Algorithm = struct
  (* Helper function to count cards of a specific color in a given hand. *)
  (* let count_color hand color =
    List.fold_left hand ~f:(fun acc card -> 
      if UnoCard.equal_color color (UnoCardInstance.get_color card) then acc + 1 else acc) ~init:0 *)
  
  (* Helper function to determine the color with the most cards in a given hand. *)
  (* let dominant_color hand =
    let colors = [UnoCard.Red; Blue; Green; Yellow] in
    List.fold_left colors ~f:(fun (max_color, max_count) color ->
      let count = count_color hand color in
      if count > max_count then (color, count) else (max_color, max_count))
      ~init:(UnoCard.Red, 0)
  |> fst *)

  let rank_card card ~hand ~opponents ~top_card =
  if UnoCard.equal_color (UnoCardInstance.get_color top_card) (UnoCardInstance.get_color card) || 
     UnoCard.equal_value (UnoCardInstance.get_value top_card) (UnoCardInstance.get_value card) then
    match UnoCardInstance.get_value card with
    | Number _ -> 1

    | Reverse ->
      let front = List.hd_exn opponents in
      let back = List.hd_exn (List.rev opponents) in
      if abs (front - back) = 1 then 2
      else if front > back then 1
      else 3
    
    | Skip ->
      let front = List.hd_exn opponents in
      let second_front = List.nth_exn opponents 1 in
      if front <= 3 then 4
      else if front >= 3 && second_front <= 3 then 2
      else 3

    | DrawTwo ->
      let front = List.hd_exn opponents in
      if front < 3 then 5 else 4

    | DrawFour ->
      let front = List.hd_exn opponents in
      if (List.length hand > 3 || front > 3) then 5
      else if List.exists ~f:(fun c -> UnoCard.equal_value (UnoCardInstance.get_value c) UnoCard.DrawFour) hand then 7
      else 6

    | WildValue ->
      if List.length hand > 3 then 3
      else if List.length hand < 3 then 5
      else 4
  else
    0

  let minimax hand top_card opponent_counts depth is_maximizing = 
    if depth = 0 || List.length hand = 0 then
      match hand with
      | [] -> failwith "No cards left to play. Won the game."
      | card :: _ -> card
    else
      let scored_cards =
        List.map ~f:
          (fun card ->
            let rank = rank_card card ~hand ~opponents:opponent_counts ~top_card in
            (card, rank))
        hand
      in
      let sorted = 
        List.sort ~compare:(fun (_, rank1) (_, rank2) -> if is_maximizing then rank2 - rank1 else rank1 - rank2) scored_cards
      in
      fst (List.hd_exn sorted)
end