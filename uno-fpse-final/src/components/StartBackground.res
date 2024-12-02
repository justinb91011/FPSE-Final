@react.component
let make = () => {
  // State to track if the form should be displayed
  let (showForm, setShowForm) = React.useState(() => false)

  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/background.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ~display="flex", /* Use flexbox */
    ~justifyContent="center", /* Center horizontally */
    ~alignItems="flex-end", /* Position content lower on the page */
    ~paddingBottom="16vh", /* Add spacing from the bottom of the page */
    ()
  )

  let handleStartClick = () => {
    setShowForm(_ => true) /* Correctly updates the state */
  }

  <div style=backgroundStyle>
    <div style=ReactDOM.Style.make(~textAlign="center", ())>
      <h1 className="text-4xl font-bold text-white mb-6"> </h1>
      <Button onClick={_ => handleStartClick()}>
        {React.string("Start Game")}
      </Button>
    </div>
    {
      showForm ? (
        <div style=ReactDOM.Style.make(
          ~position="absolute",
          ~top="50%",
          ~left="50%",
          ~transform="translate(-50%, -50%)",
          ~backgroundColor="white",
          ~padding="20px",
          ~borderRadius="8px",
          ~boxShadow="0 4px 6px rgba(0, 0, 0, 0.1)",
          ())>
          <h2 className="text-2xl font-semibold mb-4"> {React.string("Select Your Difficulty Level")} </h2>
          <div className="flex flex-col gap-4">
            <Button onClick={_ => Js.log("Easy Selected!")}>
              {React.string("Easy")}
            </Button>
            <Button onClick={_ => Js.log("Medium Selected!")}>
              {React.string("Medium")}
            </Button>
            <Button onClick={_ => Js.log("Hard Selected!")}>
              {React.string("Hard")}
            </Button>
          </div>
        </div>
      ) : React.null
    }
  </div>
}