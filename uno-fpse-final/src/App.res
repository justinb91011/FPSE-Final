@react.component
let make = () => {
  let url = RescriptReactRouter.useUrl()

  switch url.path {
  | list{} => <StartBackground />
  | list{"game", _difficulty} => <Game _difficulty />
  | _ => <div>{React.string("Page Not Found")}</div>
  }
}