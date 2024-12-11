@react.component
let make = (~difficulty: string) => {
  Js.log("This will be a " ++ difficulty ++ " game");

  // State to track if the quit confirmation form should be displayed
  let (showQuitForm, setShowQuitForm) = React.useState(() => false);

  // State to store the fetched game information
  let (playerInfo, setPlayerInfo) = React.useState(() => None);

  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/gamecolor.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ~position="relative", /* Allows positioning the button */
    ()
  );

  // Fetch game information from the backend
  React.useEffect(() => {
    let fetchGameInfo = () => {
      let url = "http://localhost:8080/";
      Fetch.fetch(url)
      |> Js.Promise.then_(response =>
           if (response->Fetch.Response.ok) {
             Fetch.Response.json(response)
           } else {
             Js.Promise.reject(Js.Exn.raiseError("Failed to fetch game information"))
           }
         )
      |> Js.Promise.then_(data => {
           // Parse the JSON response
           let json = data->Js.Json.decodeObject;
           switch json {
           | Some(obj) =>
             let player_name = obj->Js.Dict.get("player_name")->Belt.Option.getExn->Js.Json.decodeString->Belt.Option.getExn;
             let hand = obj->Js.Dict.get("hand")->Belt.Option.getExn->Js.Json.decodeArray->Belt.Option.getExn
               |> Array.map(item => item->Js.Json.decodeString->Belt.Option.getExn);
             let top_discard = obj->Js.Dict.get("top_discard")->Belt.Option.getExn->Js.Json.decodeString->Belt.Option.getExn;
             setPlayerInfo(_ => Some((player_name, Array.to_list(hand), top_discard)));
           | None => Js.log("Invalid JSON format");
           };
           Js.Promise.resolve();
         })
      |> Js.Promise.catch(_ => {
           Js.log("Error fetching game information");
           Js.Promise.resolve();
         })
      |> ignore;
    };

    fetchGameInfo();
    None;
  }, []);

  let handleYesClick = () => {
    RescriptReactRouter.push("/");
  };

  let handleNoClick = () => {
    setShowQuitForm(_ => false);
  };

  <div style=backgroundStyle>
    {
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
        <>
          <Button
            onClick={_ => setShowQuitForm(_ => true)}
            className="absolute bottom-4 left-4 px-4 py-2 bg-yellow-400 text-black font-bold rounded"
          >
            {React.string("Quit")}
          </Button>
          <h1 style=ReactDOM.Style.make(~color="white", ~textAlign="center", ())>
            {React.string("Game Page for " ++ difficulty ++ " Difficulty")}
          </h1>
          {
            switch playerInfo {
            | None => <p style=ReactDOM.Style.make(~color="white", ())> {React.string("Loading game information...")} </p>
            | Some((player_name, hand, top_discard)) =>
              <>
                <div style=ReactDOM.Style.make(
                  ~color="white",
                  ~textAlign="center",
                  ~position="absolute",
                  ~top="50%",
                  ~left="50%",
                  ~transform="translate(-50%, -50%)",
                  ())>
                  <h3> {React.string("Top of Discard Pile: " ++ top_discard)} </h3>
                </div>
                <div style=ReactDOM.Style.make(
                  ~position="absolute",
                  ~bottom="20px",
                  ~left="50%",
                  ~transform="translateX(-50%)",
                  ~color="white",
                  ~textAlign="center",
                  ())>
                  <h3> {React.string(player_name ++ "'s Hand:")} </h3>
                  <ul>
                    {
                      React.array(
                        hand
                        |> List.map(card => <li key=card> {React.string(card)} </li>)
                        |> Belt.List.toArray
                      )
                    }
                  </ul>
                </div>
              </>
            }
          }
        </>
      )
    }
  </div>;
};