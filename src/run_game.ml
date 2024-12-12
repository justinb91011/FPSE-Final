open Core
open Uno_card
open Deck
open Player
open Cpu
open Game

let add_cors_headers next_handler request =
  let%lwt response = next_handler request in
  Dream.set_header response "Access-Control-Allow-Origin" "*";
  Dream.set_header response "Access-Control-Allow-Methods" "GET, POST, OPTIONS";
  Dream.set_header response "Access-Control-Allow-Headers" "Content-Type";
  Lwt.return response


let () = Game.initialize_game ()

let () =
  Dream.run
    ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger
  @@ add_cors_headers
  @@ Dream.router [

    (* Handle the player's turn *)
    Dream.post "/play" (fun request ->
      match !Game.game_state with
      | None -> 
        let json_response = `Assoc [("error", `String "Game not initialized.")] in
        Dream.json ~code:500 (Yojson.Safe.to_string json_response)
      | Some state ->
        if state.current_player_index <> 0 then
          let json_response = `Assoc [("error", `String "Not your turn to place a card")] in
          Dream.json ~code:400 (Yojson.Safe.to_string json_response)
        else
          match Dream.query request "card_index" with
          | None -> 
            let json_response = `Assoc [("error", `String "No card selected")] in (* This error should never occur on the frontend only if you ever run the game specifically on the backend *)
            Dream.json ~code:400 (Yojson.Safe.to_string json_response)
          | Some card_index_str ->
            match Int.of_string_opt card_index_str with
            | None ->
              let json_response = `Assoc [("error", `String "Invalid card index")] in (* This error should never occur on the frontend only if you ever run the game specifically on the backend *)
              Dream.json ~code:400 (Yojson.Safe.to_string json_response)
            | Some card_index ->
              let player_name, player = List.hd_exn state.players in
              let top_discard = List.hd_exn state.discard_pile in
              let hand = Player.get_hand player in

              if Game.any_playable_card hand top_discard then
                begin
                  if card_index < 0 || card_index >= List.length hand then
                    let json_response = `Assoc [("error", `String "Invalid card index")] in
                    Dream.json ~code:400 (Yojson.Safe.to_string json_response)
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
                      
                      let state, color_msg = 
                        match UnoCardInstance.get_value card with
                        | UnoCard.WildValue | UnoCard.DrawFour ->
                          let chosen_color_opt = Dream.query request "chosen_color" in
                          (match Game.handle_wild_card state card chosen_color_opt with
                           | None ->
                             let json_response = `Assoc [("error", `String "You must choose a valid color for the wild card")] in
                             Dream.json ~code:400 (Yojson.Safe.to_string json_response)
                             |> ignore;
                             (state, None)  (* Preserve state if error *)
                           | Some new_state -> 
                            let chosen_color = Option.value_exn chosen_color_opt in
                            (new_state, Some(Printf.sprintf "Color changed to %s." chosen_color)))
                        | _ -> (state, None)
                      in
                      Game.game_state := Some state;
                      let _, player = List.hd_exn state.players in
                      if Player.has_won player then
                        let json_response = `Assoc [("message", `String "Player1 has won the game. Game over.")] in
                        Dream.json (Yojson.Safe.to_string json_response);
                      else
                        (* Respond with appropriate message *)
                        let base_msg = "Card played successfully!" in
                        let response_msg =
                          match draw_msg, color_msg with
                          | Some draw, Some color -> Printf.sprintf "%s\n%s\n%s" base_msg draw color
                          | Some draw, None -> Printf.sprintf "%s\n%s" base_msg draw
                          | None, Some color -> Printf.sprintf "%s\n%s" base_msg color
                          | None, None -> base_msg
                        in
                        let json_response = `Assoc [("message", `String response_msg)] in
                        Dream.json (Yojson.Safe.to_string json_response);
                    else
                      let json_response = `Assoc [("error", `String "Card is not playable. Please choose a different card")] in
                      Dream.json ~code:400 (Yojson.Safe.to_string json_response);
                      
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
                    let json_response = `Assoc [("message", `String "Player1 has won the game. Game over.")] in
                    Dream.json (Yojson.Safe.to_string json_response);
                  else
                    (match draw_msg with
                     | Some m ->
                       let json_response = `Assoc [("message", `String (Printf.sprintf "Card played successfully!\n%s" m))] in
                       Dream.json (Yojson.Safe.to_string json_response);
                     | None ->
                       let top_discard = List.hd_exn state.discard_pile in
                       let top_color = UnoCardInstance.get_color top_discard in
                       let top_value = UnoCardInstance.get_value top_discard in
                       let top_card_str =
                         Printf.sprintf "%s %s"
                           (Sexp.to_string (UnoCard.sexp_of_color top_color))
                           (Sexp.to_string (UnoCard.sexp_of_value top_value))
                       in
                       let json_response = `Assoc [("message", `String (Printf.sprintf
                       "No playable card in your hand; you drew %s and played it! Top card: %s"
                       drawn_card_str top_card_str))] in
                       Dream.json (Yojson.Safe.to_string json_response))
                else
                  let state = { state with
                    players = [(player_name, player)];
                    current_player_index = 1;
                  } in
                  Game.game_state := Some state;
                  let json_response = `Assoc [("message", `String (Printf.sprintf
                  "No playable card in your hand; you drew %s and kept it. Turn ends."
                  drawn_card_str))] in
                  Dream.json (Yojson.Safe.to_string json_response));
                  

    Dream.get "/" (fun _ ->
      match !Game.game_state with
      | None -> 
        let json_response = `Assoc [("error", `String "Game not initialized.")] in
        Dream.json ~code:500 (Yojson.Safe.to_string json_response)
        
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
        let hand_list = List.map hand ~f:(fun card ->
          let color = UnoCardInstance.get_color card in
          let value = UnoCardInstance.get_value card in
          Printf.sprintf "%s %s"
            (Sexp.to_string (UnoCard.sexp_of_color color))
            (Sexp.to_string (UnoCard.sexp_of_value value))
        ) in
        let json_response =
          `Assoc [
            ("player_name", `String player_name);
            ("hand", `List (List.map hand_list ~f:(fun card -> `String card)));
            ("top_discard", `String top_card_str);
          ]
        in
        Dream.json (Yojson.Safe.to_string json_response)
    );

    Dream.post "/cpu_turn" (fun _ ->
      match !Game.game_state with
      | None -> Dream.html "Game not initialized."
      | Some state ->
        if state.current_player_index = 0 then
          Dream.html "It's the player's turn."
        else
          let (new_state, chosen_card, cpu_index, color_chosen) = Game.play_cpu_turn state in
          Game.game_state := Some new_state;

          let new_top = List.hd_exn new_state.discard_pile in
          if UnoCardInstance.equal chosen_card new_top then
            let state = Game.handle_skip_card (Option.value_exn !Game.game_state) chosen_card in
            Game.game_state := Some state;

            let state = Game.handle_reverse_card (Option.value_exn !Game.game_state) chosen_card cpu_index in
            Game.game_state := Some state;

            let (state, draw_msg) = Game.handle_draw_two (Option.value_exn !Game.game_state) chosen_card in
            Game.game_state := Some state;

            let state, _ = 
              match UnoCardInstance.get_value chosen_card with
              | UnoCard.WildValue | UnoCard.DrawFour ->
                (match Game.handle_wild_card state chosen_card color_chosen with
                  | None ->
                    Dream.html ~code:400 "You must choose a valid color for the wild card."
                    |> ignore;
                    (state, None)  (* Preserve state if error *)
                  | Some new_state -> 
                  let chosen_color = Option.value_exn color_chosen in
                  (new_state, Some(Printf.sprintf "Color changed to %s." chosen_color)))
              | _ -> (state, None)
            in
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
      | None -> 
        (* Return an error JSON if the game is not initialized *)
        let json_response = `Assoc [("error", `String "Game not initialized.")] in
        Dream.json ~code:500 (Yojson.Safe.to_string json_response)
      | Some state ->
        (* Construct a list of CPU hands with their names, hands, and number of cards *)
        let cpu_hands = 
          List.map state.cpus ~f:(fun (name, cpu) ->
            let hand = CPU.get_hand cpu in
            let hand_list = List.map hand ~f:(fun card ->
              let color = UnoCardInstance.get_color card in
              let value = UnoCardInstance.get_value card in
              Printf.sprintf "%s %s"
                (Sexp.to_string (UnoCard.sexp_of_color color))
                (Sexp.to_string (UnoCard.sexp_of_value value))
            ) in
            `Assoc [
              ("name", `String name);
              ("hand", `List (List.map hand_list ~f:(fun card_str -> `String card_str)));
              ("num_cards", `Int (List.length hand))
            ]
          )
        in
        (* Create the final JSON response *)
        let json_response = `Assoc [("cpu_hands", `List cpu_hands)] in
        Dream.json (Yojson.Safe.to_string json_response)
    );
  ]