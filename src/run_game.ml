open Core
open Uno_card
open Deck
open Player
open Cpu
open Game

let () = Game.initialize_game ()

let () =
  Dream.run
    ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ Dream.router [

    (* Handle the player's turn *)
    Dream.post "/play" (fun request ->
      match !Game.game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        if state.current_player_index <> 0 then
          Dream.html "Not your turn to place a card"
        else
          match Dream.query request "card_index" with
          | None -> Dream.html "No card selected."
          | Some card_index_str ->
            match Int.of_string_opt card_index_str with
            | None ->
              Dream.html ~code:400 "Invalid card index."
            | Some card_index ->
              let player_name, player = List.hd_exn state.players in
              let top_discard = List.hd_exn state.discard_pile in
              let hand = Player.get_hand player in

              if Game.any_playable_card hand top_discard then
                begin
                  if card_index < 0 || card_index >= List.length hand then
                    Dream.html ~code:400 "Invalid card index."
                  else
                    let card = List.nth_exn hand card_index in
                    if UnoCard.is_playable
                         (UnoCardInstance.get_color card) (UnoCardInstance.get_value card)
                         (UnoCardInstance.get_color top_discard) (UnoCardInstance.get_value top_discard)
                    then
                      let player = Player.play_card player card top_discard in
                      let discard_pile = card :: state.discard_pile in
                      let state = { state with
                        discard_pile;
                        players = [(player_name, player)];
                        current_player_index = 1;
                      } in
                      Game.game_state := Some state;

                      let state = Game.handle_skip_card (Option.value_exn !Game.game_state) card in
                      Game.game_state := Some state;

                      let state = Game.handle_reverse_card (Option.value_exn !Game.game_state) card 0 in
                      Game.game_state := Some state;

                      let (state, draw_msg) = Game.handle_draw_two (Option.value_exn !Game.game_state) card in
                      Game.game_state := Some state;
                      
                      let state = 
                        match UnoCardInstance.get_value card with
                        | UnoCard.WildValue | UnoCard.DrawFour ->
                          let chosen_color_opt = Dream.query request "chosen_color" in
                          (match Game.handle_wild_card state card chosen_color_opt with
                           | None ->
                             Dream.html ~code:400 "You must choose a valid color for the wild card."
                             |> ignore;
                             state  (* Preserve state if error *)
                           | Some new_state -> new_state)
                        | _ -> state
                      in

                      let _, player = List.hd_exn state.players in
                      if Player.has_won player then
                        Dream.html "Player1 has won the game. Game over."
                      else
                        (* If draw_msg is Some, print both lines, else just "Card played successfully!" *)
                        (match draw_msg with
                         | Some m ->
                           Dream.html (Printf.sprintf "Card played successfully!\n%s" m)
                         | None ->
                           Dream.html "Card played successfully!")
                    else
                      Dream.html ~code:400 "Card is not playable. Please choose a different card."
                end
              else
                (* No playable cards, draw one *)
                let (drawn_card, new_deck) = Deck.draw_card state.deck in
                let player = Player.add_cards player [drawn_card] in
                let state = { state with deck = new_deck } in

                let drawn_color = UnoCardInstance.get_color drawn_card in
                let drawn_value = UnoCardInstance.get_value drawn_card in
                let drawn_card_str =
                  Printf.sprintf "%s %s"
                    (Sexp.to_string (UnoCard.sexp_of_color drawn_color))
                    (Sexp.to_string (UnoCard.sexp_of_value drawn_value))
                in

                if UnoCard.is_playable
                     (UnoCardInstance.get_color drawn_card) (UnoCardInstance.get_value drawn_card)
                     (UnoCardInstance.get_color top_discard) (UnoCardInstance.get_value top_discard)
                then
                  let player = Player.play_card player drawn_card top_discard in
                  let discard_pile = drawn_card :: state.discard_pile in
                  let state = { state with
                    discard_pile;
                    players = [(player_name, player)];
                    current_player_index = 1;
                  } in
                  Game.game_state := Some state;

                  let state = Game.handle_skip_card (Option.value_exn !Game.game_state) drawn_card in
                  Game.game_state := Some state;

                  let state = Game.handle_reverse_card (Option.value_exn !Game.game_state) drawn_card 0 in
                  Game.game_state := Some state;

                  let (state, draw_msg) = Game.handle_draw_two (Option.value_exn !Game.game_state) drawn_card in
                  Game.game_state := Some state;

                  let _, player = List.hd_exn state.players in
                  if Player.has_won player then
                    Dream.html "Player1 has won the game. Game over."
                  else
                    (match draw_msg with
                     | Some m ->
                       (* Print both messages *)
                       Dream.html (Printf.sprintf "Card played successfully!\n%s" m)
                     | None ->
                       let top_discard = List.hd_exn state.discard_pile in
                       let top_color = UnoCardInstance.get_color top_discard in
                       let top_value = UnoCardInstance.get_value top_discard in
                       let top_card_str =
                         Printf.sprintf "%s %s"
                           (Sexp.to_string (UnoCard.sexp_of_color top_color))
                           (Sexp.to_string (UnoCard.sexp_of_value top_value))
                       in
                       Dream.html (Printf.sprintf
                         "No playable card in your hand; you drew %s and played it! Top card: %s"
                         drawn_card_str top_card_str))
                else
                  let state = { state with
                    players = [(player_name, player)];
                    current_player_index = 1;
                  } in
                  Game.game_state := Some state;
                  Dream.html (Printf.sprintf
                    "No playable card in your hand; you drew %s and kept it. Turn ends."
                    drawn_card_str));

    Dream.get "/" (fun _ ->
      match !Game.game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        let top_discard = List.hd_exn state.discard_pile in
        let top_color = UnoCardInstance.get_color top_discard in
        let top_value = UnoCardInstance.get_value top_discard in
        let top_card_str =
          Printf.sprintf "%s %s"
            (Sexp.to_string (UnoCard.sexp_of_color top_color))
            (Sexp.to_string (UnoCard.sexp_of_value top_value))
        in

        let player_name, player = List.hd_exn state.players in
        let hand = Player.get_hand player in
        let hand_str = String.concat ~sep:", " (
          List.map hand ~f:(fun card ->
            let color = UnoCardInstance.get_color card in
            let value = UnoCardInstance.get_value card in
            Printf.sprintf "%s %s"
              (Sexp.to_string (UnoCard.sexp_of_color color))
              (Sexp.to_string (UnoCard.sexp_of_value value))
          )
        ) in
        Dream.html (Printf.sprintf
          "Welcome to UNO, %s!<br>Your hand: %s<br>Top of Discard Pile: %s"
          player_name hand_str top_card_str)
    );

    Dream.post "/cpu_turn" (fun _ ->
      match !Game.game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        if state.current_player_index = 0 then
          Dream.html "It's the player's turn."
        else
          let (new_state, chosen_card, cpu_index) = Game.play_cpu_turn state in
          Game.game_state := Some new_state;

          let new_top = List.hd_exn new_state.discard_pile in
          if UnoCardInstance.equal chosen_card new_top then
            let state = Game.handle_skip_card (Option.value_exn !Game.game_state) chosen_card in
            Game.game_state := Some state;

            let state = Game.handle_reverse_card (Option.value_exn !Game.game_state) chosen_card cpu_index in
            Game.game_state := Some state;

            let (state, draw_msg) = Game.handle_draw_two (Option.value_exn !Game.game_state) chosen_card in
            Game.game_state := Some state;

            let (_, updated_cpu) = List.nth_exn state.cpus (cpu_index - 1) in
            if CPU.has_won updated_cpu then
              Dream.html (Printf.sprintf "CPU%d has won the game. Game over." cpu_index)
            else
              let played_color = UnoCardInstance.get_color chosen_card in
              let played_value = UnoCardInstance.get_value chosen_card in
              let played_card_str =
                Printf.sprintf "%s %s"
                  (Sexp.to_string (UnoCard.sexp_of_color played_color))
                  (Sexp.to_string (UnoCard.sexp_of_value played_value))
              in
              (match draw_msg with
               | Some m ->
                 Dream.html (Printf.sprintf "CPU%d turn completed. Played: %s\n%s" cpu_index played_card_str m)
               | None ->
                 Dream.html (Printf.sprintf "CPU%d turn completed. Played: %s" cpu_index played_card_str))
          else
            Dream.html (Printf.sprintf "CPU%d turn completed. Drew a card." cpu_index)
    );

    Dream.get "/cpu_hands" (fun _ ->
      match !Game.game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        let cpu_hands =
          List.map state.cpus ~f:(fun (name, cpu) ->
            let hand = CPU.get_hand cpu in
            let hand_str = String.concat ~sep:", " (
              List.map hand ~f:(fun card ->
                let color = UnoCardInstance.get_color card in
                let value = UnoCardInstance.get_value card in
                Printf.sprintf "%s %s"
                  (Sexp.to_string (UnoCard.sexp_of_color color))
                  (Sexp.to_string (UnoCard.sexp_of_value value))
              )
            ) in
            Printf.sprintf "%s's hand: %s" name hand_str
          )
        in
        Dream.html (String.concat ~sep:"<br>" cpu_hands)
    );
  ]