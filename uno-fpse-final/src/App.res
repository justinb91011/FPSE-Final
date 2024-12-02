// App.res
@react.component
let make = () => {
  let url = RescriptReactRouter.useUrl()

  switch url.path {
  | list{} => <StartBackground />
  | list{"game", difficulty} => <Game difficulty />
  | _ => <div>{React.string("Page Not Found")}</div>
  }
}