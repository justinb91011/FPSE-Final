// Game.res
@react.component
let make = (~difficulty: string) => {
  Js.log("This will be a " ++ difficulty ++ " game")

  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/gamecolor.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ~position="relative", /* Allows positioning the button */
    ()
  )

  let handleQuitClick = () => {
    RescriptReactRouter.push("/")
  }

  <div style=backgroundStyle>
    <Button
      onClick={_ => handleQuitClick()}
      className="absolute bottom-4 left-4 px-4 py-2 bg-yellow-400 text-black font-bold rounded"
    >
      {React.string("Quit")}
    </Button>
    <h1 style=ReactDOM.Style.make(~color="white", ~textAlign="center", ())>
      {React.string("Game Page for " ++ difficulty ++ " Difficulty")}
    </h1>
  </div>
}