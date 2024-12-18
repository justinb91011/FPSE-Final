open Core
open Uno_card

module Algorithm = struct
  

  let rank_card card ~hand ~opponents ~top_card =
  if UnoCard.is_playable (UnoCardInstance.get_color card) (UnoCardInstance.get_value card)
    (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card) then
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
      else if UnoCard.equal_value DrawFour (UnoCardInstance.get_value top_card) then 7 
      else 6

    | WildValue ->
      if List.length hand > 3 then 3
      else if List.length hand < 3 then 5
      else 4
  else
    0

    (* We may want to use the is_minimizing parameter if we find that we cannot get to a sound
       medium difficulty through altering between easy and hard difficulties. *)
  let minimax hand top_card opponent_counts = 
    if List.is_empty hand then
      failwith "No cards left to play. Won the game."
    else
      let scored_cards =
        List.map ~f:
          (fun card ->
            let rank = rank_card card ~hand ~opponents:opponent_counts ~top_card in
            (card, rank))
        hand
      in
      let sorted = 
        (* Was List.sort ~compare:(fun (_, rank1) (_, rank2) -> if is_maximizing then rank2 - rank1 else rank1 - rank2) scored_cards. *)
        List.sort ~compare:(fun (_, rank1) (_, rank2) -> rank2 - rank1) scored_cards
      in
      fst (List.hd_exn sorted)
end