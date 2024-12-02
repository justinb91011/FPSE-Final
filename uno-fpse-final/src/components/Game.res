// Game.res
@react.component
let make = (~difficulty: string) => {
  Js.log("This will be a " ++ difficulty ++ " game")

  <div>
    {React.string("Game Page for " ++ difficulty ++ " Difficulty")}
  </div>
}