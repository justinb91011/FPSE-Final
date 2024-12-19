/* 
# Uno Card Game

For the Functional Programming project, our group decided to make an Uno card game from scratch. This project has a frontend and backend implementation that are seamlessly integrated with eachother. The game features three difficulties, easy, medium, and hard that the player can choose from. Once the player chooses a difficulty, they can click start game and begin to play against two cpu players. For the backend we used Ocaml and dream, and for the frontend, we used react and rescript. 

# How to Run the Project
To begin, you must have two terminals open, one for the frontend and one for the backend. Starting with the backend, once you are in the projcect folder, run a dune build, and then navigate to the src folder. Once you are there run the command "dune exec ./run_game.exe". That will initialize the backend, and you can now switch to your other terminal and navigate to the uno-fpse-final and run the command "npm install". This will install all the neccessary packages and dependencies. Then run the command "npx rescript build", which compiles the code. Finally, run 
"npm run dev". When this finishes running, a link will appear, and this is the link to the game page. At this point, the frontend and backend should be fully working, and the game can be played. If you want to reset the game, you must restart the backend and the frontend. It is crucial that the backend is ran before the frontend. Directly start in the local directory, ie: http://localhost:5173/ , or whatever the port says.

# Other Notes
plus 2's and plus 4's are supposed to stack

we played 300 games, 100 per difficulty and saw that 58/100 games were won against the easy difficulty, 54 were won against the medium difficulty, and 49 were won against the hard difficulty. Obviously this is just a rough estimate of how well people will do against the difficulty's but we think it gives a good validation on the difficulty differences.




# Frontend Information

Our implementation of the frontend uses rescript. We use react to manage the states in the game, and this ranges from handling whose turn it is, to managing the home screen. We made a card map that maps every string that codes for a card to a png of the appropriate card. Our cardImageUrl function then actually makes the image appear on screen.

With the initializeGame function it sends a post request back to the backend to start the game. We use a promise to check that the request was sent ok and if it was, it will proceed, if it didn't, then it will break the chain and give out an error message. there is then a useEffect to initialize the game once and only once.

The fetchGameInfo function is very important because it helps keep track of the state of the game at all times. It fetches the state of the game from the basic '/' GET request path in the backend, which returns the player, the player's hand, top of the discard pile, and the current turn. We have a promise to ge the data and if its ok then it goes through, and if its not it stops. It then parses through the JSON and grabs all the important info and stores it into variables to be used later in the code.

FetchCpuInfo operates similarly to fetchGameInfo except it requests and fetches the data from the /cpu_hands endpoint in the code. This fetches the number of cards in the cpu_hands and the turn of the cpu's. We then have state management that will call fetchGameInfo and then call the fetchCpuInfo function given that the player info has been filled out.

Then we have the handleYesClick and handleNoClick function that handles the yes and no buttons of the quit screen.

Next is the handleCpuTurn that obviously deals with playing cards on the cpu turns. We have it setup so that it runs on a 3 second timeout, so that a turn is completed after 3 seconds passes. We pass a POST request to the backend with the promise chain, and if its ok, we refetch the cpu info and game info so that the game continues to the next persons turn. Errors will be handled accordingly depending on the phase of the promise the error is caught on.

Lastly for the functions, we have the handleCardClick function that first has a function that deals with the case of a wildcard showing up. The way our backend works, there is a second parameter when playing wildcards called chosen_color. When the user wants to play a wild card, they have to fill out a box that asks for what color they want to have for the wild card. If its a wild card, it will change it to an 8 of that color, and if its a plus 4, then it will change it to the approporiately colored plus 4. So we handle that accordingly at the beginning of the function, and then based on what card you click, it will get the index of the card and send that in the POST request to the backend to play the card. 

The rest of the code is ui handling. It is mostly just styling to make everything look the way it does on the screen. In the UI, we also manage certain states in order to display whose turn it is at the top of the screen. It will also use info from the json messages to display the proper number of cards for the cpu players, and the proper cards in the players hand.




# Backend Implementation

"/" GET Request:  You can now run the backend server. First run a dune build and then travel to the src foulder. Then run the command:
dune exec ./run_game.exe. This will run the backend server on http://localhost:8080. Now we haven't connected the backend to the frontend yet, but we will do so soon. For now we can play an easy game on the backendserver but you will have to use Postman in order to make the API calls. Now there are different API calls that you need to make. The game is already initialized with a get request when you do: dune exec ./run_game.exe.
On Postman you can do a get request to http://localhost:8080. The response back should be Welcome to UNO! It should also tell you what the Player's(You) hand/cards are at the start of the game and it will tell you the top card of the discard pile(this is the card that you have to match it with), now it doesn't tell you but the two CPU's you will be playing against will also be given their hands as well(this is not a response in the original get request because you shouldn't know the CPU's hand because that would be cheating).

"/play?card_index=#" Post Request: Now we made it so the Player will always start off the game. For the Player to play a card it will be a POST request(http://localhost:8080/play)) and it will take a parameter called card_index. The card_index parameter you must pass is associated with the card you wanna play. The first card in your hand will have card_index=0, and the last card(at the start of the game) will have card_index =6. So the card_index you pass  will play the card that has that card_index. There are different scenarios that can happen when you play a card: You play a card and its valid, the response you get back "Card played successfully!". Now lets say you try playing a card and its not playable but you still have a playable card in your hand it will return - "Card is not playable. Please choose a different card." Now lets say you don't have a playable card in your deck. Still send in a post request send in card_index=0. This will activate another case where you have to draw the card. Now if the card that you drew can be played you will get the message - "No playable card in your hand; you drew %s and played it! Top card: %s", if the card that you drew cannot be played you will get the message - "No playable card in your hand; you drew %s and kept it. Turn ends." We also did some error checking if you try sending in an invalid card_index you will get a 400 Bad Request saying "Invalid card index". Also once a player has played a card or drew a card his turn will be up and then the next turn will be the CPU's. We made is so if you try to do 2 play Post Requests the second request will return a 400 Bad Request with the message - "Not your turn to place a card".

"/cpu_turn" POST request: Here, this is the request that actually handles a cpu turn. It handles one cpu per request, so it would have to send at most 2 post requests to get back to the player turn. Each call handles a cpu turn logically, such that it can only play valid cards, and if it has no cards that are playable in the hand, then it will draw a card and proceed to the next player in the turn cycle. It also depends on the difficulty selected, because if its easy, then the cpu will randomly choose from the playable cards with no strategy. If its medium, it will do a mix of the two algorithms, and for the hard algorithm, it will choose based on a complex ranking system. There is some error handling including a message that pops up saying "its the players turn" if its the players turn and a post request is attempting to be made for a cpu_turn. When a cpu turn is completed successfully, a message will show saying "CPU turn completed." when the cpu has made a successful move. For the actual implementation, we use a function called play_cpu_turn, and this will call upon the cpu.ml file to choose a valid card if it exists, and then it will update the deck and discard pile accordingly. Then the post request portion of the code manages the state, and calls the play_cpu_turn function.

"/cpu_hands" GET request: This is a fairly simple get request that gets the hand of both cpu players, and the main point of it is for testing. We want to see what the before and after of the hand is to make sure that the cpu is playing cards correctly. If the game hasnt started yet, then it will output "Game has not been initialized.", which makes sense because there are no hands to look at before the game starts. We use the List.map for the cpu hands so that we can easily get the color of the card and value of the card, then add it to the list for hand representation. If it is successful, it will output something like this:
 CPU1's hand: WildColor WildValue, Blue Reverse, Green (Number 3), Blue Reverse, Green Reverse, Red (Number 9), Yellow (Number 9)`<br>`CPU2's hand: Blue (Number 9), Yellow (Number 5), Red Skip, Blue (Number 8), WildColor WildValue, Yellow DrawTwo, Yellow (Number 3)


# Overview

Group Members: Justin Bravo, Robert Velez, Griffin Montalvo

We made a digital version of the card game UNO. The user will play against other computer-generated players, and the game will enforce the rules of UNO (e.g., skip turns, reverse order, and draw cards). Our particular implementation has three difficulties:

- Easy
- Medium
- Hard

The medium and hard difficulties will make use of an algorithm we built from the ground up using our very own ranking system.


# Algorithm:

We are attempting to create an UNO AI algorithm where the CPU players will make the most optimal moves in order to win the game. The difficulty in creating this algorithm, is that it is not as “straightforward” or well documented as ones written for games like Chess. Thus, we are looking to develop our own default ranking system for cards with the room to change based on the game state and other players. We will then feed this into a minimax algorithm that we will tailor to work with our ranking system. OCaml will work with this because of its functional nature, strong type system, and efficient handling of recursive structures, thus making it ideal for both designing our ranking system and implementing the minimax algorithm. We can try a similar approach as we did in Assignment 5 where we memoized computations stored in a map and used them later, if and when needed. The AI will be built to make decisions quickly, allowing for smooth gameplay. For example, in a situation where only one card is playable, it will choose that card. However, in a case where many cards are playable, the AI will choose the card which maximizes it’s chances of winning the game in the long-run or thwarts another player from winning.


