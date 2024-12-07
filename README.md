# Progress for Code Checkpoint

With respect to what is working/complete on the backend, we have implemented all the modules (with the exception of algorithm, as we're still finalizing our approach, more on this later) that we will need. We have also tested our modules for 100% coverage (card.ml & uno_card.ml have types that aren't tested but for some reason the [@@coverage off] macro isn't working as expected) and we will be looking to implement even more extensive tests later. We created a generic library, card.ml, that can be extrapolated and used on any card game. We have our specialized UNO functor in the uno_card.ml. We tested our libraries a lot, however we did not write tests for our game.ml file because we use this in run_game.ml which is the backend. These are just the functions we use for the backend and these were heavility tested on Postman. We did this kind of last minute of putting all the functions in game.ml to make our run_game.ml file look cleaner so we didn't have time to write tests for game.ml. We will have them done for the final submission.

More on the backend. :

"/" GET Request:  You can now run the backend server. First run a dune build and then travel to the src foulder. Then run the command:
dune exec ./run_game.exe. This will run the backend server on http://localhost:8080. Now we haven't connected the backend to the frontend yet, but we will do so soon. For now we can play an easy game on the backendserver but you will have to use Postman in order to make the API calls. Now there are different API calls that you need to make. The game is already initialized with a get request when you do: dune exec ./run_game.exe.
On Postman you can do a get request to http://localhost:8080. The response back should be Welcome to UNO! It should also tell you what the Player's(You) hand/cards are at the start of the game and it will tell you the top card of the discard pile(this is the card that you have to match it with), now it doesn't tell you but the two CPU's you will be playing against will also be given their hands as well(this is not a response in the original get request because you shouldn't know the CPU's hand because that would be cheating).

"/play?card_index=#" Post Request: Now we made it so the Player will always start off the game. For the Player to play a card it will be a POST request(http://localhost:8080/play)) and it will take a parameter called card_index. The card_index parameter you must pass is associated with the card you wanna play. The first card in your hand will have card_index=0, and the last card(at the start of the game) will have card_index =6. So the card_index you pass  will play the card that has that card_index. There are different scenarios that can happen when you play a card: You play a card and its valid, the response you get back "Card played successfully!". Now lets say you try playing a card and its not playable but you still have a playable card in your hand it will return - "Card is not playable. Please choose a different card." Now lets say you don't have a playable card in your deck. Still send in a post request send in card_index=0. This will activate another case where you have to draw the card. Now if the card that you drew can be played you will get the message - "No playable card in your hand; you drew %s and played it! Top card: %s", if the card that you drew cannot be played you will get the message - "No playable card in your hand; you drew %s and kept it. Turn ends." We also did some error checking if you try sending in an invalid card_index you will get a 400 Bad Request saying "Invalid card index". Also once a player has played a card or drew a card his turn will be up and then the next turn will be the CPU's. We made is so if you try to do 2 play Post Requests the second request will return a 400 Bad Request with the message - "Not your turn to place a card".

"/cpu_turn" POST request: Here, this is the request that actually handles a cpu turn. It handles one cpu per request, so it would have to send at most 2 post requests to get back to the player turn. Each call handles a cpu turn logically, such that it can only play valid cards, and if it has no cards that are playable in the hand, then it will draw a card and proceed to the next player in the turn cycle. It also depends on the difficulty selected, because if its easy, then the cpu will randomly choose from the playable cards with no strategy. If its medium, it will do a mix of the two algorithms, and for the hard algorithm, it will choose based on a complex ranking system. There is some error handling including a message that pops up saying "its the players turn" if its the players turn and a post request is attempting to be made for a cpu_turn. When a cpu turn is completed successfully, a message will show saying "CPU turn completed." when the cpu has made a successful move. For the actual implementation, we use a function called play_cpu_turn, and this will call upon the cpu.ml file to choose a valid card if it exists, and then it will update the deck and discard pile accordingly. Then the post request portion of the code manages the state, and calls the play_cpu_turn function.

"/cpu_hands" GET request: This is a fairly simple get request that gets the hand of both cpu players, and the main point of it is for testing. We want to see what the before and after of the hand is to make sure that the cpu is playing cards correctly. If the game hasnt started yet, then it will output "Game has not been initialized.", which makes sense because there are no hands to look at before the game starts. We use the List.map for the cpu hands so that we can easily get the color of the card and value of the card, then add it to the list for hand representation. If it is successful, it will output something like this:
 CPU1's hand: WildColor WildValue, Blue Reverse, Green (Number 3), Blue Reverse, Green Reverse, Red (Number 9), Yellow (Number 9)`<br>`CPU2's hand: Blue (Number 9), Yellow (Number 5), Red Skip, Blue (Number 8), WildColor WildValue, Yellow DrawTwo, Yellow (Number 3)



We ran into an error in the last minute of implementing the WildCards that is the normal WildCard that changes the color and also the Draw Four. Like everything works except the top of the discard pile isn't being changed to the color that was chosen. We will soon figure out what this error is. However everything else surrounding the game and the game logic should work. So we can almost fully run a game on the backend.



More on the frontend:

So for right now the backend and the frontend are not connected to each other. However we have done work on our frontend as well. In order to start the frontend you need to travel to the uno-fpse-final folder. Once you are here download all the dependencies you will need by doing npm install. Sometimes the dependencies won't be downloaded correctly so before you can run the frontend you should do: npx rescript clean and then npx rescript build. In order to run the frontend you will need to npm run dev. Open the localhost link you get from this and open it on any browser(Recommend Firefox Developer Edition). This will take you to the homepage of the frontend of our application. There is a start Game on the homepage that you can click on and it will open up a form that will ask the user to select their difficulty level. Once you have chosen to the Difficulty Level click on Start. This will you take to the /game/{Difficulty Level}. For right now we don't have the backend and frontend connected so we can't run the game visually. We have added a Quit Button to the bottom left of the Screen. When this is clicked it will ask the User again if its sure it wants to quit. If no is clicked the game will continue, if yes is clicked the user will be brought back to the initial frontend homepage.

Moving on to what's not working/complete on the backend, we are still needing to finalize our algorithm. Currently, we have the easy implementation of the algorithm finished and can be found in cpu.ml lines 28 - 52. However, in order to implement the Medium difficulty, we need the Hard difficulty first as the Medium level will make use of both the Hard and Easy levels with certain and intricate probabilities.

# Overview

Group Members: Justin Bravo, Robert Velez, Griffin Montalvo

We are going to make a digital version of the card game UNO. The user will play against other computer-generated players, and the game will enforce the rules of UNO (e.g., skip turns, reverse order, and draw cards). Our particular implementation will have three difficulties:

- Easy
- Medium
- Hard

The medium and hard difficulties will make use of an algorithm we are planning to build from the ground up using our very own ranking system.

We will also create a front-end for the game that includes the options to save and load games.

# More on the Algorithm:

We are attempting to create an UNO AI algorithm where the CPU players will make the most optimal moves in order to win the game. The difficulty in creating this algorithm, is that it is not as “straightforward” or well documented as ones written for games like Chess. Thus, we are looking to develop our own default ranking system for cards with the room to change based on the game state and other players. We will then feed this into a minimax algorithm that we will tailor to work with our ranking system. OCaml will work with this because of its functional nature, strong type system, and efficient handling of recursive structures, thus making it ideal for both designing our ranking system and implementing the minimax algorithm. We can try a similar approach as we did in Assignment 5 where we memoized computations stored in a map and used them later, if and when needed. The AI will be built to make decisions quickly, allowing for smooth gameplay. For example, in a situation where only one card is playable, it will choose that card. However, in a case where many cards are playable, the AI will choose the card which maximizes it’s chances of winning the game in the long-run or thwarts another player from winning.

# Possible List of Libraries:

- Core:
  - An extension of Base w/ additional functionality.
  - Gives us the robust data structures & utilities.
- OUnit2 (Testing):
  - Allows to write and run unit tests for modules.
- Dune (Build System):
  - Building & managing our project efficiently.
- ReScript: (HAS BEEN DOWNLOADED)
  - To write the frontend for UNO, compiles to JS and is operable with OCaml.
- React: (HAS BEEN DOWNLOADED)
  - ReScript bindings to React can be used to create an interactive UI.
- bs-css:
  - To style the front-end with CSS-in-JS solutions directly in Rescript.
- Dream:
  - For the backend.
- Lwt:
  - Handling asynchronous tasks (API calls or WebSocket communication in backend).
- Bisect
  - Demonstrate coverage for Code Checkpoint and Demo & Final Code Submissions.

# Implementation Plan

- [~1 day] We will look to implement a few more .mli files which we don't already have but will need. These could look like: gamestate.mli, ai.mli, and saveload.mli.
- [~2-4 days] We will then start creating implementations for the easiest/simplest of the .mli files, starting with card, followed by deck, and lastly player.
- [~2-4 days] We will implement the .ml files for the remaining .mli files, such as gamestate.ml, ai.ml, and saveload.ml.
- [~3-5 days] We will now move onto implementing the more involved and bulk of our project, the UNO AI with our very own ranking system.
- [~2-4 days] We will test and tweak/tune the AI to make sure it works as expected in respective difficulties.
- [~1-2 days] We will settle on a final design/look for the front-end and begin implementing it.
- [~2-4 days] We will wrap up our front-end and try to have it work with out back-end.
- [~3-6 days] We will undergo extensive test-runs to make sure our game is running as we expect.

# UNO Draft

Here, the pictures shown in UNO Draft.pdf will be explained.

- First Picture: The first picture is a mockup of what our home page will be. We are wanting to include a dropdown where the player selects a
  difficulty from easy, medium, and hard. Once a difficulty is chosen, then the player may press the Play Game button and begin the game.
- Second Picture: The second picture depicts the start state of the game where every player has 7 cards, and there is a deck in the middle.
- Third Picture: The third picture depicts the wining state of the game where one player is completely out of cards. A You Won message will be
  displayed when the win condition is met, or a You Lost message will be displayed if an opponent wins instead.
