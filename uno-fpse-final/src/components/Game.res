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
    ()
  )

  <div style=backgroundStyle>
    <h1 style=ReactDOM.Style.make(~color="white", ~textAlign="center", ())>
      {React.string("Game Page for " ++ difficulty ++ " Difficulty")}
    </h1>
  </div>
}