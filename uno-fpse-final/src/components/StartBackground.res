@react.component
let make = () => {
  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/background.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ()
  )

  <div style=backgroundStyle>
    <h1> {React.string("Welcome to UNO!")} </h1>
  </div>
}