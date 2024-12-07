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

  let any_playable_card hand top_card =
    List.exists hand ~f:(fun c ->
      UnoCard.is_playable
        (UnoCardInstance.get_color c) (UnoCardInstance.get_value c)
        (UnoCardInstance.get_color top_card) (UnoCardInstance.get_value top_card)
    )
    
  let initialize_game () =
    let deck = Deck.create_deck () |> Deck.shuffle in
  
    let player = Player.create "Player1" in
    let cpu1 = CPU.create CPU.Easy in
    let cpu2 = CPU.create CPU.Easy in
  
    let player_cards, deck = Deck.draw_cards 7 deck in
    let player = Player.add_cards player player_cards in
  
    let cpu1_cards, deck = Deck.draw_cards 7 deck in
    let cpu1 = CPU.add_cards cpu1 cpu1_cards in
  
    let cpu2_cards, deck = Deck.draw_cards 7 deck in
    let cpu2 = CPU.add_cards cpu2 cpu2_cards in
  
    let top_card, deck = Deck.draw_card deck in
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
          | _ -> (state.direction, state.current_player_index)
        else
          (* Currently counterclockwise (direction = -1) *)
          match who_played with
          | 0 (* Player1 played Reverse *) -> (1, 1)  (* direction = 1, turn = CPU#1 (index 1) *)
          | 1 (* CPU1 played Reverse *) -> (1, 2)     (* direction = 1, turn = CPU#2 (index 2) *)
          | 2 (* CPU2 played Reverse *) -> (1, 0)     (* direction = 1, turn = Player1 (index 0) *)
          | _ -> (state.direction, state.current_player_index)
      in
      { state with direction = new_direction; current_player_index = new_turn }
    | _ ->
      (* If not a reverse card, do nothing *)
      state

  let play_cpu_turn state =
    let cpu_index = state.current_player_index in
    let (_, current_cpu) = List.nth_exn state.cpus (cpu_index - 1) in
    let top_discard = List.hd_exn state.discard_pile in
  
    (* CPU chooses a card *)
    let card, new_deck, updated_cpu = CPU.choose_card current_cpu top_discard state.deck in
  
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
  
    (new_state, card, cpu_index)

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
      | WildValue ->
        (match chosen_color_opt with
        | None -> None
        | Some chosen_color ->
          let valid_color = match String.lowercase chosen_color with
            | "red" -> UnoCard.Red
            | "blue" -> UnoCard.Blue
            | "green" -> UnoCard.Green
            | "yellow" -> UnoCard.Yellow
            | _ -> UnoCard.WildColor
          in
          let updated_card = UnoCardInstance.create valid_color WildValue in
          let new_discard_pile = updated_card :: state.discard_pile in
          let new_state = { state with
            discard_pile = new_discard_pile;
            current_player_index = next_player_index state
          } in
          Some new_state)
      | DrawFour ->
        (match chosen_color_opt with
        | None -> None
        | Some chosen_color ->
          let valid_color = match String.lowercase chosen_color with
            | "red" -> UnoCard.Red
            | "blue" -> UnoCard.Blue
            | "green" -> UnoCard.Green
            | "yellow" -> UnoCard.Yellow
            | _ -> UnoCard.WildColor
          in
          let updated_card = UnoCardInstance.create valid_color DrawFour in
          let new_discard_pile = updated_card :: state.discard_pile in
          let next_index = next_player_index state in
          let (drawn_cards, new_deck) = Deck.draw_cards 4 state.deck in

          (* Update the next player's hand *)
          let new_state =
            if next_index = 0 then
              let (pname, p) = List.hd_exn state.players in
              let p = Player.add_cards p drawn_cards in
              { state with
                players = [(pname, p)];
                discard_pile = new_discard_pile;
                deck = new_deck;
                current_player_index = next_player_index state
              }
            else
              let (cname, cpu) = List.nth_exn state.cpus (next_index - 1) in
              let cpu = CPU.add_cards cpu drawn_cards in
              let cpus = List.mapi state.cpus ~f:(fun i (nm, cc) ->
                if i = next_index - 1 then (cname, cpu) else (nm, cc)
              ) in
              { state with
                cpus;
                discard_pile = new_discard_pile;
                deck = new_deck;
                current_player_index = next_player_index state
              }
          in
          Some new_state)
      | _ -> Some state
  end