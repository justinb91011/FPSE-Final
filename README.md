# Overview

Group Members: Justin Bravo, Robert Velez, Griffin Montalvo

We are going to make a digital version of the card game UNO. The user will play against other computer-generated players, and the game will enforce the rules of UNO (e.g., skip turns, reverse order, and draw cards). Our particular implementation will have three difficulties:

- Easy
- Medium
- Hard

The medium and hard difficulties will make use of an algorithm we are planning to build from the ground up using our very own ranking system.

We will also create a front-end for the game that includes the options to save and load games.

Possible List of Libraries:

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
