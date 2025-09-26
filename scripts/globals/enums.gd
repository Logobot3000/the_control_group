extends Node;

## An enum for the types of movement modes the VelocityComponent supports.
enum MovementMode {
	## Allows for free movement in both the X and Y axes.
	FREEFLYING,
	## Allows for free movement in the X axis, while the Y axis is affected by gravity.
	PLATFORMER
};

## An enum for the current state in the minigame process
enum GameState {
	## The players are currently in the lobby waiting for the next minigame.
	LOBBY,
	## The players are getting assigned/choosing their modifiers for the game after being assigned their roles.
	MODIFIER_SELECTION,
	## A minigame is currently being played.
	MINIGAME_ACTIVE,
	## The results of the minigame are being shown to the players.
	RESULTS
};

## An enum for the two groups in the game.
enum PlayerGroup {
	## A member of the experimental group.
	EXPERIMENTAL,
	## A member of the control group.
	CONTROL
};
