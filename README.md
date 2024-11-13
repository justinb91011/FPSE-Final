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
    - To style the front-end with CSS-in-JS solutions directly in Rescript
- Dream:
    - For the backend
- Lwt:
    - Handling asynchronous tasks (API calls or WebSocket communication in backend)


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
