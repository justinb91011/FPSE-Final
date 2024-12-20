@bs.val external prompt: string => Js.Nullable.t<string> = "prompt"
@bs.val external alert: string => unit = "alert"

@react.component
let make = (~_difficulty: string) => {
  

  let (showQuitForm, setShowQuitForm) = React.useState(() => false);
  let (playerInfo, setPlayerInfo) = React.useState(() => None);
  let (cpuPlayers, setCpuPlayers) = React.useState(() => []);
  let (_, setIsCpuTurn) = React.useState(() => false);
  let (currentTurn, setCurrentTurn) = React.useState(() => "Loading turn...");


  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/gamecolor.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ~position="relative",
    ~overflow="hidden",
    ()
  );

  let cardMap = Js.Dict.fromArray([
    ("Blue (Number 0)", "/card_images/blue-0-card.png"),
    ("Blue (Number 1)", "/card_images/blue-1-card.png"),
    ("Blue (Number 2)", "/card_images/blue-2-card.png"),
    ("Blue (Number 3)", "/card_images/blue-3-card.png"),
    ("Blue (Number 4)", "/card_images/blue-4-card.png"),
    ("Blue (Number 5)", "/card_images/blue-5-card.png"),
    ("Blue (Number 6)", "/card_images/blue-6-card.png"),
    ("Blue (Number 7)", "/card_images/blue-7-card.png"),
    ("Blue (Number 8)", "/card_images/blue-8-card.png"),
    ("Blue (Number 9)", "/card_images/blue-9-card.png"),

    ("Blue Reverse", "/card_images/blue-reverse-card.png"),
    ("Blue Skip", "/card_images/blue-skip-card.png"),
    ("Blue DrawTwo", "/card_images/blue-draw-two-card.png"),

    ("Red (Number 0)", "/card_images/red-0-card.png"),
    ("Red (Number 1)", "/card_images/red-1-card.png"),
    ("Red (Number 2)", "/card_images/red-2-card.png"),
    ("Red (Number 3)", "/card_images/red-3-card.png"),
    ("Red (Number 4)", "/card_images/red-4-card.png"),
    ("Red (Number 5)", "/card_images/red-5-card.png"),
    ("Red (Number 6)", "/card_images/red-6-card.png"),
    ("Red (Number 7)", "/card_images/red-7-card.png"),
    ("Red (Number 8)", "/card_images/red-8-card.png"),
    ("Red (Number 9)", "/card_images/red-9-card.png"),

    ("Red Reverse", "/card_images/red-reverse-card.png"),
    ("Red Skip", "/card_images/red-skip-card.png"),
    ("Red DrawTwo", "/card_images/red-draw-two-card.png"),

    ("Yellow (Number 0)", "/card_images/yellow-0-card.png"),
    ("Yellow (Number 1)", "/card_images/yellow-1-card.png"),
    ("Yellow (Number 2)", "/card_images/yellow-2-card.png"),
    ("Yellow (Number 3)", "/card_images/yellow-3-card.png"),
    ("Yellow (Number 4)", "/card_images/yellow-4-card.png"),
    ("Yellow (Number 5)", "/card_images/yellow-5-card.png"),
    ("Yellow (Number 6)", "/card_images/yellow-6-card.png"),
    ("Yellow (Number 7)", "/card_images/yellow-7-card.png"),
    ("Yellow (Number 8)", "/card_images/yellow-8-card.png"),
    ("Yellow (Number 9)", "/card_images/yellow-9-card.png"),

    ("Yellow Reverse", "/card_images/yellow-reverse-card.png"),
    ("Yellow Skip", "/card_images/yellow-skip-card.png"),
    ("Yellow DrawTwo", "/card_images/yellow-draw-two-card.png"),

    ("Green (Number 0)", "/card_images/green-0-card.png"),
    ("Green (Number 1)", "/card_images/green-1-card.png"),
    ("Green (Number 2)", "/card_images/green-2-card.png"),
    ("Green (Number 3)", "/card_images/green-3-card.png"),
    ("Green (Number 4)", "/card_images/green-4-card.png"),
    ("Green (Number 5)", "/card_images/green-5-card.png"),
    ("Green (Number 6)", "/card_images/green-6-card.png"),
    ("Green (Number 7)", "/card_images/green-7-card.png"),
    ("Green (Number 8)", "/card_images/green-8-card.png"),
    ("Green (Number 9)", "/card_images/green-9-card.png"),

    ("Green Reverse", "/card_images/green-reverse-card.png"),
    ("Green Skip", "/card_images/green-skip-card.png"),
    ("Green DrawTwo", "/card_images/green-draw-two-card.png"),

    ("WildColor DrawFour", "/card_images/wild-draw-four-card.png"),
    ("WildColor WildValue", "/card_images/wild-card.png"),
    ("Green DrawFour", "/card_images/green-draw-four-card.png"),
    ("Red DrawFour", "/card_images/red-draw-four-card.png"),
    ("Blue DrawFour", "/card_images/blue-draw-four-card.png"),
    ("Yellow DrawFour", "/card_images/yellow-draw-four-card.png"),
  ]);

  let cardImageUrl = (card: string) =>
    switch (Js.Dict.get(cardMap, card)) {
    | Some(url) => url
    | None => "/card_images/unknown-card.png"
    };


  let initializeGame = () => {
    let url = "http://localhost:8080/init_game?difficulty=" ++ _difficulty

    let postInit = Obj.magic({
        "method": "POST",
    });

    Fetch.fetchWithInit(url, postInit)
    |> Js.Promise.then_(response =>
        if (response->Fetch.Response.ok) {
          Js.Promise.resolve()
        } else {
          Js.Promise.reject(Js.Exn.raiseError("Failed to initialize game"))
        }
      )
    |> Js.Promise.then_(_ => {
        /* Re-fetch game info after initialization */
        Js.Promise.resolve()
      })
    |> Js.Promise.catch(_ => {
        Js.log("Error initializing game")
        Js.Promise.resolve()
      })
    |> ignore
  }

  React.useEffect(() => {
    initializeGame()
    None
  }, [])


  /* Function to re-fetch the game state after a move */
  let fetchGameInfo = () => {
    Fetch.fetch("http://localhost:8080/")
    |> Js.Promise.then_(response =>
        if (response->Fetch.Response.ok) {
          Fetch.Response.json(response)
        } else {
          Js.Promise.reject(Js.Exn.raiseError("Failed to fetch game information"))
        }
      )
    |> Js.Promise.then_(data => {
        let json = data->Js.Json.decodeObject
        switch json {
        | Some(obj) =>
          let player_name = obj->Js.Dict.get("player_name")
            ->Belt.Option.getExn
            ->Js.Json.decodeString
            ->Belt.Option.getExn

          let hand = obj->Js.Dict.get("hand")
            ->Belt.Option.getExn
            ->Js.Json.decodeArray
            ->Belt.Option.getExn
            |> Array.map(item => item->Js.Json.decodeString->Belt.Option.getExn)

          let top_discard = obj->Js.Dict.get("top_discard")
            ->Belt.Option.getExn
            ->Js.Json.decodeString
            ->Belt.Option.getExn

          /* Update current turn */
          let currentTurnOpt = obj->Js.Dict.get("current_turn")
            ->Belt.Option.flatMap(item => item->Js.Json.decodeString)

          switch currentTurnOpt {
          | Some(turn) =>
            setCurrentTurn(_ => turn) /* Update turn state */
          | None =>
            Js.log("Error: Missing current_turn in JSON response")
          }

          setPlayerInfo(_ => Some((player_name, Array.to_list(hand), top_discard)))
        | None =>
          Js.log("Invalid JSON format")
        }

        Js.Promise.resolve()
    })
    |> Js.Promise.catch(_ => {
        Js.log("Error fetching game information")
        Js.Promise.resolve()
      })
    |> ignore
  }


  /* Function to re-fetch CPU info */
  let fetchCpuInfo = () => {
    Fetch.fetch("http://localhost:8080/cpu_hands")
    |> Js.Promise.then_(response =>
         if (response->Fetch.Response.ok) {
           Fetch.Response.json(response)
         } else {
           Js.Promise.reject(Js.Exn.raiseError("Failed to fetch CPU information"))
         }
       )
    |> Js.Promise.then_(data => {
         let json = data->Js.Json.decodeObject
         switch json {
         | Some(obj) =>
           let cpu_hands = obj->Js.Dict.get("cpu_hands")
             ->Belt.Option.getExn
             ->Js.Json.decodeArray
             ->Belt.Option.getExn

           let cpus =
             cpu_hands
             |> Array.map(cpuJson => {
                  let cpuObj = cpuJson->Js.Json.decodeObject->Belt.Option.getExn
                  let cpuName = cpuObj->Js.Dict.get("name")
                    ->Belt.Option.getExn
                    ->Js.Json.decodeString
                    ->Belt.Option.getExn
                  let num_cards_float = cpuObj->Js.Dict.get("num_cards")
                    ->Belt.Option.getExn
                    ->Js.Json.decodeNumber
                    ->Belt.Option.getExn

                  let num_cards_str = Js.Float.toString(num_cards_float)
                  let num_cards = int_of_string(num_cards_str)
                  (cpuName, num_cards)
                })

           setCpuPlayers(_ => cpus)
         | None =>
           Js.log("Invalid JSON for CPU hands")
         }

         Js.Promise.resolve()
    })
    |> Js.Promise.catch(_ => {
         Js.log("Error fetching CPU information")
         Js.Promise.resolve()
       })
    |> ignore
  }

  // Initial fetch of game info
  React.useEffect(() => {
    fetchGameInfo()
    None
  }, [])

  // Fetch CPU info once we have player info
  React.useEffect(() => {
    switch playerInfo {
    | None => ()
    | Some(_) => fetchCpuInfo()
    }
    None
  }, [playerInfo])

  let handleYesClick = () => {
    RescriptReactRouter.push("/")
  }

  let handleNoClick = () => {
    setShowQuitForm(_ => false)
  }

  /* Function to handle CPU turn */
  let handleCpuTurn = (~cpuName: string) => {

    /* Add a 3-second delay before playing the turn */
    ignore(Js.Global.setTimeout(() => {
      let url = "http://localhost:8080/cpu_turn";

      /* Create a POST request init */
      let postInit = Obj.magic({
        "method": "POST",
      });

      Fetch.fetchWithInit(url, postInit)
      |> Js.Promise.then_(response =>
          if response->Fetch.Response.ok {
            Fetch.Response.text(response)
          } else {
            Js.Promise.reject(Js.Exn.raiseError("Failed to process CPU turn"))
          }
        )
      |> Js.Promise.then_(_ => {
          /* Re-fetch game state to determine the next turn */
          fetchGameInfo();
          fetchCpuInfo();

          Js.Promise.resolve();
        })
      |> Js.Promise.catch(err => {
          Js.log("Error during " ++ cpuName ++ "'s turn:");
          Js.log(err);
          setIsCpuTurn(_ => false);
          Js.Promise.resolve();
        })
      |> ignore;
    }, 3000)); /* 3-second delay */
    ();
  };





  /* Handle card click */
  let handleCardClick = (index: int, card: string) => {
    let isWild =
      card == "WildColor DrawFour" || card == "WildColor WildValue"

    let chosenColor =
      if isWild {
        prompt("Choose a color: Blue, Red, Green, Yellow")
      } else {
        Js.Nullable.null
      }

    let chosenColorOpt = chosenColor->Js.Nullable.toOption

    let chosenColorParam =
      if isWild {
        switch chosenColorOpt {
        | None => {
            Js.log("No color chosen, aborting play.")
            None
          }
        | Some(color) =>
          let trimmedColor = Js.String.trim(color)
          if trimmedColor == "Blue" || trimmedColor == "Red" || trimmedColor == "Green" || trimmedColor == "Yellow" {
            Some("&chosen_color=" ++ trimmedColor)
          } else {
            alert("Invalid color chosen. Must be Blue, Red, Green, or Yellow.")
            None
          }
        }
      } else {
        None
      }

    switch chosenColorParam {
    | None =>
      if isWild {
        () // User cancelled or invalid color choice
      } else {
        let url = "http://localhost:8080/play?card_index=" ++ string_of_int(index)

        let postInit = Obj.magic({
          "method": "POST"
        })

        Fetch.fetchWithInit(url, postInit)
        |> Js.Promise.then_(response => Fetch.Response.json(response))
        |> Js.Promise.then_(data => {
             let dataObj = data->Js.Json.decodeObject
             switch dataObj {
             | Some(obj) =>
               switch Js.Dict.get(obj, "error") {
               | Some(errorVal) =>
                 let errStr = errorVal->Js.Json.decodeString->Belt.Option.getExn
                 alert("Error: " ++ errStr)
               | None =>
                 /* Success */
                 switch Js.Dict.get(obj, "message") {
                 | Some(msgVal) =>
                   let msgStr = msgVal->Js.Json.decodeString->Belt.Option.getExn
                   alert(msgStr)
                 | None => ()
                 }

                 /* Re-fetch state */
                 fetchGameInfo();
                 fetchCpuInfo();

                 /* Switch to CPU turn */
                 setIsCpuTurn(_ => true);
               }
             | None => ()
             }
             Js.Promise.resolve()
        })
        |> Js.Promise.catch(_ => {
             alert("Failed to play card.");
             Js.Promise.resolve()
           })
        |> ignore
      }

    | Some(colorParam) =>
      let url = "http://localhost:8080/play?card_index=" ++ string_of_int(index) ++ colorParam
      let postInit = Obj.magic({
        "method": "POST"
      })

      Fetch.fetchWithInit(url, postInit)
      |> Js.Promise.then_(response => Fetch.Response.json(response))
      |> Js.Promise.then_(data => {
           let dataObj = data->Js.Json.decodeObject
           switch dataObj {
           | Some(obj) =>
             switch Js.Dict.get(obj, "error") {
             | Some(errorVal) =>
               let errStr = errorVal->Js.Json.decodeString->Belt.Option.getExn
               alert("Error: " ++ errStr)
             | None =>
               /* Success */
               switch Js.Dict.get(obj, "message") {
               | Some(msgVal) =>
                 let msgStr = msgVal->Js.Json.decodeString->Belt.Option.getExn
                 alert(msgStr)
               | None => ()
               }

               /* Re-fetch state */
               fetchGameInfo();
               fetchCpuInfo();

               /* Switch to CPU turn */
               setIsCpuTurn(_ => true);
             }
           | None => ()
           }
           Js.Promise.resolve()
      })
      |> Js.Promise.catch(_ => {
           alert("Failed to play card.");
           Js.Promise.resolve()
         })
      |> ignore
    }
  }

  /* Trigger CPU turn when isCpuTurn changes */
  React.useEffect(() => {
    switch currentTurn {
    | "CPU1" => {
        setIsCpuTurn(_ => true);
        handleCpuTurn(~cpuName="CPU1");
      }
    | "CPU2" => {
        setIsCpuTurn(_ => true);
        handleCpuTurn(~cpuName="CPU2");
      }
    | _ => {
        setIsCpuTurn(_ => false);
      }
    };
    None;
  }, [currentTurn]);


  <div style=backgroundStyle>
    {
      //quit screen
      showQuitForm ? (
        <div style=ReactDOM.Style.make(
          ~position="absolute",
          ~top="50%",
          ~left="50%",
          ~transform="translate(-50%, -50%)",
          ~backgroundColor="white",
          ~padding="20px",
          ~borderRadius="8px",
          ~boxShadow="0 4px 6px rgba(0, 0, 0, 0.1)",
          ~textAlign="center",
          ())>
          <h2 className="text-2xl font-semibold mb-4">
            {React.string("Are you sure you want to quit?")}
          </h2>
          <div className="flex justify-between mt-6">
            <Button
              onClick={_ => handleYesClick()}
              className="px-10 py-2 bg-red-500 text-white font-bold rounded"
            >
              {React.string("Yes")}
            </Button>
            <Button
              onClick={_ => handleNoClick()}
              className="px-10 py-2 bg-green-500 text-white font-bold rounded"
            >
              {React.string("No")}
            </Button>
          </div>
        </div>
      ) : (
        switch playerInfo {
        | None =>
          <>
            <Button
              onClick={_ => setShowQuitForm(_ => true)}
              className="absolute bottom-4 left-4 px-4 py-2 bg-yellow-400 text-black font-bold rounded"
            >
              {React.string("Quit")}
            </Button>
            <p style=ReactDOM.Style.make(~color="white", ())>
              {React.string("Loading game information...")}
            </p>
          </>

        | Some((player_name, hand, top_discard)) =>
          <>
          //Turn display at the top of screen
            <div style=ReactDOM.Style.make(
              ~position="absolute",
              ~top="10px",
              ~left="50%",
              ~transform="translateX(-50%)",
              ~color="white",
              ~textAlign="center",
              ~fontSize="20px",
              ~fontWeight="bold",
              ()
            )>
              <h2>{React.string(currentTurn ++ "'s Turn")}</h2>
            </div>

            //Cpu player display
            <div style=ReactDOM.Style.make(
              ~display="flex",
              ~justifyContent="space-between",
              ~alignItems="flex-start",
              ~width="100%",
              ~paddingLeft="80px",
              ~paddingRight="80px",
              ()
            )>
              {
                React.array(
                  cpuPlayers
                  |> Array.map(((cpuName, cardCount)) =>
                    <div
                      key=cpuName
                      style=ReactDOM.Style.make(
                        ~color="white",
                        ~textAlign="center",
                        ~flexShrink="0",
                        ~flexBasis="100px",
                        ()
                      )>
                      //name
                      <h2 style=ReactDOM.Style.make(
                        ~margin="0",
                        ~paddingBottom="10px",
                        ()
                      )>
                        {React.string(cpuName)}
                      </h2>
                      <ul style=ReactDOM.Style.make(
                        ~listStyle="none",
                        ~padding="0",
                        ~display="flex",
                        ~flexDirection="column",
                        ~gap="2px",
                        ~justifyContent="center",
                        ~alignItems="center",
                        ()
                      )>
                        {
                          React.array(
                            Belt.Array.range(0, cardCount - 1)
                            |> Array.map(i => {
                              let baseWidth = 70.0;
                              
                              /* Shrink by 30% when cardCount > 7 */
                              let width =
                                if cardCount > 7 {
                                  baseWidth *. 0.7 /* Reduce width by 30% */
                                } else {
                                  baseWidth
                                };

                              <li key=string_of_int(i)>
                                <img
                                  src="/card_images/back-card.png"
                                  alt="Card Back"
                                  style=ReactDOM.Style.make(
                                    ~width=Js.Float.toString(width) ++ "px", 
                                    ~transform="rotate(90deg)",
                                    ()
                                  )
                                />
                              </li>
                            })
                          )
                        }
                      </ul>
                    </div>
                  )
                )
              }
            </div>

            //quit button
            <Button
              onClick={_ => setShowQuitForm(_ => true)}
              className="absolute bottom-4 left-4 px-4 py-2 bg-yellow-400 text-black font-bold rounded"
            >
              {React.string("Quit")}
            </Button>

            
            // displays the top of the discard pile
            <div style=ReactDOM.Style.make(
              ~position="absolute",
              ~top="50%",
              ~left="50%",
              ~transform="translate(-50%, -50%)",
              ~textAlign="center",
              ())>
              <img
                src={cardImageUrl(top_discard)}
                alt={top_discard}
                style=ReactDOM.Style.make(~width="80px", ())
              />
            </div>

            //show "player1s hand"
            <div style=ReactDOM.Style.make(
              ~position="absolute",
              ~bottom="20px",
              ~left="50%",
              ~transform="translateX(-50%)",
              ~color="white",
              ~textAlign="center",
              ())>
              <h3> {React.string(player_name ++ "'s Hand:")} </h3>
              //Display the hand of the player
              <ul style=ReactDOM.Style.make(
                ~listStyle="none",
                ~padding="0",
                ~display="flex",
                ~gap="1px",
                ~justifyContent="center",
                ()
              )>
                {
                  React.array(
                    hand
                    |> List.mapi((index, card) =>
                        <li key=card>
                          <img
                            src={cardImageUrl(card)}
                            alt={card}
                            style=ReactDOM.Style.make(~width="80px", ())
                            onClick={_ => handleCardClick(index, card)}
                          />
                        </li>
                      )
                    |> Belt.List.toArray
                  )
                }
              </ul>
            </div>
          </>
        }
      )
    }
  </div>;
};
