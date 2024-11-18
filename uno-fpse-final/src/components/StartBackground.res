@react.component
let make = () => {
  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/background.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ~display="flex", /* Use flexbox */
    ~justifyContent="center", /* Center horizontally */
    ~alignItems="center", /* Center vertically */
    ()
  )

  <div style=backgroundStyle>
    <div>
      <h1 className="text-4xl font-bold text-white mb-6"> </h1>
      <Button onClick={_ => Js.log("Button Clicked!")}>
        {React.string("Start Game")}
      </Button>
    </div>
  </div>
}