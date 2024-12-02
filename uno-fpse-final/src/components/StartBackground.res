@react.component
let make = () => {
  // State to track if the form should be displayed
  let (showForm, setShowForm) = React.useState(() => false)
  // State to track selected difficulty level
  let (selectedDifficulty, setSelectedDifficulty) = React.useState(() => None)

  let backgroundStyle = ReactDOM.Style.make(
    ~backgroundImage="url('/background.jpg')",
    ~backgroundSize="cover",
    ~backgroundPosition="center",
    ~height="100vh",
    ~width="100vw",
    ~display="flex",
    ~justifyContent="center",
    ~alignItems="flex-end",
    ~paddingBottom="16vh",
    ()
  )

  let handleStartClick = () => {
    setShowForm(_ => true)
  }

  let handleCancelClick = () => {
    setShowForm(_ => false)
  }

  let handleFormStartClick = () => {
    switch selectedDifficulty {
    | Some(difficulty) => {
        RescriptReactRouter.push("/game/" ++ difficulty)
      }
    | None => {
        Js.log("Please select a difficulty level")
      }
    }
  }

  // Function to check if a difficulty is selected
  let isSelected = (difficulty: string) =>
    switch selectedDifficulty {
    | Some(selected) => selected == difficulty
    | None => false
    }

  <div style=backgroundStyle>
    <div style=ReactDOM.Style.make(~textAlign="center", ())>
      {
        showForm ? React.null : (
          <Button onClick={_ => handleStartClick()}>
            {React.string("Start Game")}
          </Button>
        )
      }
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
          ~textAlign="center",
          ())>
          <h2 className="text-2xl font-semibold mb-4">
            {React.string("Select Your Difficulty Level")}
          </h2>
          <div className="flex flex-col gap-4">
            <Button
              onClick={_ => setSelectedDifficulty(_ => Some("Easy"))}
              className={
                if isSelected("Easy") {
                  "px-4 py-2 bg-blue-500 text-white font-bold rounded"
                } else {
                  "px-4 py-2 bg-yellow-400 text-black rounded"
                }
              }
            >
              {React.string("Easy")}
            </Button>
            <Button
              onClick={_ => setSelectedDifficulty(_ => Some("Medium"))}
              className={
                if isSelected("Medium") {
                  "px-4 py-2 bg-blue-500 text-white font-bold rounded"
                } else {
                  "px-4 py-2 bg-yellow-400 text-black rounded"
                }
              }
            >
              {React.string("Medium")}
            </Button>
            <Button
              onClick={_ => setSelectedDifficulty(_ => Some("Hard"))}
              className={
                if isSelected("Hard") {
                  "px-4 py-2 bg-blue-500 text-white font-bold rounded"
                } else {
                  "px-4 py-2 bg-yellow-400 text-black rounded"
                }
              }
            >
              {React.string("Hard")}
            </Button>
          </div>
          <div className="flex justify-between mt-6">
            <Button
              onClick={_ => handleCancelClick()}
              className="px-4 py-2 bg-red-500 text-white font-bold rounded"
            >
              {React.string("Cancel")}
            </Button>
            <Button
              onClick={_ => handleFormStartClick()}
              className="px-4 py-2 bg-green-500 text-white font-bold rounded"
            >
              {React.string("Start")}
            </Button>
          </div>
        </div>
      ) : React.null
    }
  </div>
}