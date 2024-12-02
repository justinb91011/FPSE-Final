// Game.res
@react.component
let make = (~difficulty: string) => {
  Js.log("This will be a " ++ difficulty ++ " game")

  // State to track if the quit confirmation form should be displayed
  let (showQuitForm, setShowQuitForm) = React.useState(() => false)

  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/gamecolor.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ~position="relative", /* Allows positioning the button */
    ()
  )

  let handleYesClick = () => {
    RescriptReactRouter.push("/")
  }

  let handleNoClick = () => {
    setShowQuitForm(_ => false)
  }

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
        </>
      )
    }
  </div>
}