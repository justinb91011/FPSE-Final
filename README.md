# FPSE-Final

Group Members: Justin Bravo, Robert Velez, Griffin Montalvo

We are going to make a digital version of the card game UNO. The user will play against other computer-generated players, and the game will enforce the rules of UNO (e.g., skip turns, reverse order, and draw cards).

Potential Ideas:
	1.	Command-line app with persistence: The focus will be on complex user interaction through the command line, allowing players to save and resume games. The app will manage game states and the sequence of player turns, while providing clear visual cues through terminal output.
	2.	Web interface app: The focus will be on creating an interactive UI where users can play the game via a web browser. This would allow for a more visually engaging experience, potentially supporting multiplayer modes and a smooth card-drawing interface.

Potential Libraries:
Core: For handling the core logic of the game.
Lwt: If we go with web-based interaction, for managing asynchronous behavior.
Dream or Cohttp: For building the web server if we choose the web interface route.
Yojson/Sexp: For persistence (storing game state) in the command-line version.


