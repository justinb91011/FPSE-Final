open Core
open Uno_card
open Deck
open Player
open Cpu

module Game = struct
  type game_state = {
    deck : Deck.t;
    discard_pile : UnoCardInstance.t list;
    players : (string * Player.t) list;
    cpus : (string * CPU.t) list;
    current_player_index : int;
    direction : int;  (* 1 for clockwise, -1 for counterclockwise *)
  }
  let game_state = ref None

  (* Getter functions to access players and cpus *)
  let get_players state = state.players
  let get_cpus state = state.cpus

  let is_valid_initial_card card =
    match UnoCardInstance.get_value card with
    | DrawTwo | DrawFour | WildValue -> false
    | _ -> true

  let any_playable_card hand top_card =
    List.exists hand ~f:(fun c ->
      UnoCard.is_playable
        (UnoCardInstance.get_color c) (UnoCardInstance.get_value c)
        (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card)
    )
    
  let initialize_game difficulty =
    Random.self_init ();
    let deck = Deck.create_deck () |> Deck.shuffle in
    
    let player = Player.create "Player1" in
    let cpu1 = CPU.create difficulty in
    let cpu2 = CPU.create difficulty in
    
    let player_cards, deck = Deck.draw_cards 7 deck in
    let player = Player.add_cards player player_cards in
    
    let cpu1_cards, deck = Deck.draw_cards 7 deck in
    let cpu1 = CPU.add_cards cpu1 cpu1_cards in
    
    let cpu2_cards, deck = Deck.draw_cards 7 deck in
    let cpu2 = CPU.add_cards cpu2 cpu2_cards in
    
    (* Function to draw a valid initial top card *)
    let rec draw_valid_top_card current_deck attempts =
      if attempts > 100 then
        failwith "Unable to draw a valid initial top card after 100 attempts." (* Will probably never happen *) [@coverage off]
      else
        let top_card, remaining_deck = Deck.draw_card current_deck in
        if is_valid_initial_card top_card then
          (top_card, remaining_deck)
        else
          (* Place the invalid card back into the deck and reshuffle *)
          let reshuffled_deck = Deck.add_card top_card remaining_deck |> Deck.shuffle in
          draw_valid_top_card reshuffled_deck (attempts + 1)
    in
    
    let top_card, deck = draw_valid_top_card deck 0 in
    let discard_pile = [top_card] in
    
    let initial_state = {
      deck;
      discard_pile;
      players = [("Player1", player)];
      cpus = [("CPU1", cpu1); ("CPU2", cpu2)];
      current_player_index = 0;
      direction = 1;
    } in
    
    game_state := Some initial_state

  let next_player_index state =
    let num_players = List.length state.players + List.length state.cpus in
    (state.current_player_index + state.direction + num_players) mod num_players

  let handle_skip_card state played_card =
    let value = UnoCardInstance.get_value played_card in
    match value with
    | Skip ->
      (* Skip the next player's turn by advancing once more *)
      { state with current_player_index = next_player_index state }
    | _ ->
      (* If not a skip card, do nothing *)
      state

  let handle_reverse_card state played_card who_played =
    let value = UnoCardInstance.get_value played_card in
    match value with
    | Reverse ->
      (* Determine new direction and next turn based on who played and current direction *)
      let new_direction, new_turn =
        if state.direction = 1 then
          (* Currently clockwise *)
          match who_played with
          | 0 (* Player1 played Reverse *) -> (-1, 2)  (* direction = -1, turn = CPU#2 (index 2) *)
          | 1 (* CPU1 played Reverse *) -> (-1, 0)    (* direction = -1, turn = Player1 (index 0) *)
          | 2 (* CPU2 played Reverse *) -> (-1, 1)    (* direction = -1, turn = CPU#1 (index 1) *)
          | _ -> (state.direction, state.current_player_index) [@coverage off]
        else
          (* Currently counterclockwise (direction = -1) *)
          match who_played with
          | 0 (* Player1 played Reverse *) -> (1, 1)  (* direction = 1, turn = CPU#1 (index 1) *)
          | 1 (* CPU1 played Reverse *) -> (1, 2)     (* direction = 1, turn = CPU#2 (index 2) *)
          | 2 (* CPU2 played Reverse *) -> (1, 0)     (* direction = 1, turn = Player1 (index 0) *)
          | _ -> (state.direction, state.current_player_index) [@coverage off]
      in
      { state with direction = new_direction; current_player_index = new_turn }
    | _ ->
      (* If not a reverse card, do nothing *)
      state

  let get_opponents_card_counts state cpu_index =
    let current_cpu_pos = cpu_index - 1 in
    let other_cpus = List.filteri state.cpus ~f:(fun i _ -> i <> current_cpu_pos) in
    let cpu_card_counts = List.map other_cpus ~f:(fun (_, cpu) -> List.length (CPU.get_hand cpu)) in
    let player_card_counts = List.map state.players ~f:(fun (_, player) -> List.length (Player.get_hand player)) in
    cpu_card_counts @ player_card_counts

  let play_cpu_turn state =
    let cpu_index = state.current_player_index in
    let (_, current_cpu) = List.nth_exn state.cpus (cpu_index - 1) in
    let top_discard = List.hd_exn state.discard_pile in
  
    let difficulty = CPU.get_difficulty current_cpu in
    let card_selection_result =
      match difficulty with
      | CPU.Easy ->
        (* CPU chooses a card using the existing Easy difficulty function *)
        CPU.choose_card current_cpu top_discard state.deck
      | CPU.Hard ->
        (* Gather opponents' card counts *)
        let opponents_card_counts = get_opponents_card_counts state cpu_index in
        (* CPU chooses a card using the Hard difficulty function *)
        CPU.choose_card_hard current_cpu top_discard state.deck opponents_card_counts
      | CPU.Medium ->
        let rand = Random.float 1.0 in
        if Float.(rand < 0.75) then
          (* 80% probability to act as Easy *)
          CPU.choose_card current_cpu top_discard state.deck
        else
          (* 20% probability to act as Hard *)
          let opponents_card_counts = get_opponents_card_counts state cpu_index in
          CPU.choose_card_hard current_cpu top_discard state.deck opponents_card_counts
        
    in
    
    let card, new_deck, updated_cpu, color_chosen = card_selection_result in

  
    (* Determine if CPU played the card *)
    let card_played = not (List.exists (CPU.get_hand updated_cpu) ~f:(UnoCardInstance.equal card)) in
  
    (* Update discard pile only if card was actually played *)
    let new_discard_pile =
      if card_played then
        card :: state.discard_pile
      else
        state.discard_pile
    in
  
    let updated_cpus =
      List.mapi state.cpus ~f:(fun i (name, cpu) ->
        if i = cpu_index - 1 then (name, updated_cpu)
        else (name, cpu))
    in
  
    let new_state = { state with
      deck = new_deck;
      discard_pile = new_discard_pile;
      cpus = updated_cpus;
      current_player_index = next_player_index state
    } in

    (match color_chosen with
    | Some color -> Printf.printf "CPU %d chose the color: %s\n" cpu_index color
    | None -> ());
  
    (new_state, card, cpu_index, color_chosen)

  let remove_card_from_player p card =
    let hand = Player.get_hand p in
    let filtered = List.filter hand ~f:(fun c -> not (UnoCardInstance.equal c card)) in
    let name = Player.get_name p in
    let p' = Player.create name in
    Player.add_cards p' filtered  
  
  let remove_card_from_cpu c card =
    let hand = CPU.get_hand c in
    let filtered = List.filter hand ~f:(fun cc -> not (UnoCardInstance.equal cc card)) in
    let diff = CPU.get_difficulty c in
    let c' = CPU.create diff in
    CPU.add_cards c' filtered  

  let handle_draw_two state played_card =
    let value = UnoCardInstance.get_value played_card in
    match value with
    | DrawTwo ->
      let rec resolve_draw_two state stack =
        let current_index = state.current_player_index in
        let is_player = (current_index = 0) in
        let current_hand =
          if is_player then
            Player.get_hand (snd (List.hd_exn state.players))
          else
            CPU.get_hand (snd (List.nth_exn state.cpus (current_index - 1)))
        in
        let draw_two_cards = List.filter current_hand ~f:(fun c ->
          match UnoCardInstance.get_value c with DrawTwo -> true | _ -> false
        ) in
  
        if List.is_empty draw_two_cards then
          (* No DrawTwo -> draw stack cards and skip turn *)
          let (drawn_cards, new_deck) = Deck.draw_cards stack state.deck in
          let state =
            if is_player then
              let (pname, p) = List.hd_exn state.players in
              let p = Player.add_cards p drawn_cards in
              { state with players = [(pname, p)]; deck = new_deck }
            else
              let i = current_index - 1 in
              let (cname, c) = List.nth_exn state.cpus i in
              let c = CPU.add_cards c drawn_cards in
              let cpus = List.mapi state.cpus ~f:(fun idx (nm, cc) ->
                if idx = i then (cname, c) else (nm, cc)
              ) in
              { state with cpus; deck = new_deck }
          in
          let state = { state with current_player_index = next_player_index state } in
          let player_name_str =
            if is_player then "Player1"
            else if current_index = 1 then "CPU1" else "CPU2"
          in
          (state, Some (Printf.sprintf "%s drew %d cards and turn skipped." player_name_str stack))
        else
          (* They have a DrawTwo -> stack it *)
          let chosen = List.hd_exn draw_two_cards in
          let state =
            if is_player then
              let (pname, p) = List.hd_exn state.players in
              let p' = remove_card_from_player p chosen in
              { state with
                players = [(pname, p')];
                discard_pile = chosen :: state.discard_pile
              }
            else
              let i = current_index - 1 in
              let (cname, c) = List.nth_exn state.cpus i in
              let c' = remove_card_from_cpu c chosen in
              let cpus = List.mapi state.cpus ~f:(fun idx (nm, cc) ->
                if idx = i then (cname, c') else (nm, cc)
              ) in
              { state with cpus; discard_pile = chosen :: state.discard_pile }
          in
          let stack = stack + 2 in
          let state = { state with current_player_index = next_player_index state } in
          resolve_draw_two state stack
      in
      resolve_draw_two state 2
    | _ -> (state, None)

    let handle_wild_card state played_card chosen_color_opt =
      let value = UnoCardInstance.get_value played_card in
      match value with
      | WildValue->
        (match chosen_color_opt with
         | None -> 
           (* Optionally, you can default to a color or return an error *) 
           None [@coverage off]
         | Some chosen_color ->
           let valid_color = match String.lowercase chosen_color with
             | "red" -> UnoCard.Red
             | "blue" -> UnoCard.Blue
             | "green" -> UnoCard.Green
             | "yellow" -> UnoCard.Yellow
             | _ -> UnoCard.WildColor  (* Alternatively, handle invalid colors more gracefully *) [@coverage off]
           in
           let updated_card = UnoCardInstance.create valid_color (Number 8) in
           let new_discard_pile = updated_card :: (List.tl_exn state.discard_pile) in
           let new_state = { state with
             discard_pile = new_discard_pile
             (* Do NOT change current_player_index for WildValue *)
           } in
           Some new_state)
      | DrawFour ->
        (match chosen_color_opt with
         | None -> 
           (* Optionally, you can default to a color or return an error *)
           None [@coverage off]
         | Some chosen_color ->
           let valid_color = match String.lowercase chosen_color with
             | "red" -> UnoCard.Red
             | "blue" -> UnoCard.Blue
             | "green" -> UnoCard.Green
             | "yellow" -> UnoCard.Yellow
             | _ -> UnoCard.WildColor  (* Alternatively, handle invalid colors more gracefully *) [@coverage off]
           in
           let updated_card = UnoCardInstance.create valid_color DrawFour in
           let new_discard_pile = updated_card :: (List.tl_exn state.discard_pile) in
    
           (* Recursive function to handle stacking of DrawFour *)
           let rec resolve_draw_four state stack =
             let target_index = state.current_player_index in
             let is_player = (target_index = 0) in
             let current_hand =
               if is_player then
                 Player.get_hand (snd (List.hd_exn state.players))
               else
                 CPU.get_hand (snd (List.nth_exn state.cpus (target_index - 1)))
             in
             let draw_four_cards = List.filter current_hand ~f:(fun c ->
               match UnoCardInstance.get_value c with
               | DrawFour -> true
               | _ -> false
             ) in
    
             if List.is_empty draw_four_cards then
               (* No DrawFour to stack: target player draws the total stack and skips their turn *)
               let (drawn_cards, new_deck) = Deck.draw_cards stack state.deck in
               let new_state =
                 if is_player then
                   let (pname, p) = List.hd_exn state.players in
                   let p = Player.add_cards p drawn_cards in
                   { state with
                     players = [(pname, p)];
                     discard_pile = new_discard_pile;
                     deck = new_deck;
                     current_player_index = next_player_index state
                   }
                 else
                   let (_, cpu) = List.nth_exn state.cpus (target_index - 1) in
                   let cpu = CPU.add_cards cpu drawn_cards in
                   let cpus = List.mapi state.cpus ~f:(fun i (nm, cc) ->
                     if i = target_index - 1 then (nm, cpu) else (nm, cc)
                   ) in
                   { state with
                     cpus;
                     discard_pile = new_discard_pile;
                     deck = new_deck;
                     current_player_index = next_player_index state
                   }
               in
               new_state
             else
               (* Target player can stack a DrawFour *)
               let chosen = List.hd_exn draw_four_cards in
               let state =
                 if is_player then
                   let (pname, p) = List.hd_exn state.players in
                   let p' = remove_card_from_player p chosen in
                   { state with
                     players = [(pname, p')];
                     discard_pile = chosen :: new_discard_pile
                   }
                 else
                   let (_, cpu) = List.nth_exn state.cpus (target_index - 1) in
                   let c' = remove_card_from_cpu cpu chosen in
                   let cpus = List.mapi state.cpus ~f:(fun i (nm, cc) ->
                     if i = target_index - 1 then (nm, c') else (nm, cc)
                   ) in
                   { state with cpus; discard_pile = chosen :: new_discard_pile }
               in
               let new_stack = stack + 4 in
               let new_current_player_index = next_player_index state in
               let state = { state with current_player_index = new_current_player_index } in
               resolve_draw_four state new_stack
           in
    
           (* Start resolving with initial stack of 4 *)
           let final_state = resolve_draw_four { state with discard_pile = new_discard_pile } 4 in
           Some final_state)
      | _ -> Some state
  end