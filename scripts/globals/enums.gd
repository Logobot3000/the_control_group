extends Node;

## An enum for the types of movement modes the VelocityComponent supports.
enum MovementMode {
	## Allows for free movement in both the X and Y axes.
	FREEFLYING,
	## Allows for free movement in the X axis, while the Y axis is affected by gravity.
	PLATFORMER
};

## An enum for the type of group each player can be in.
enum PlayerGroups {
	## The experimental group.
	EXPERIMENTAL,
	## The control group.
	CONTROL
};

## An enum for the possible types of game states. Controls the logic of the game.
enum GameState {
	## This state is when the player is in the main menu.
	MAIN_MENU,
	## This state is when all players are in the lobby.
	LOBBY,
	## This state is when the groups are assigned to the players.
	GROUP_ASSIGNMENT,
	## This state is when modifiers are being chosen.
	MODIFIER_SELECTION,
	## This state is when a minigame is about to start.
	MINIGAME_START,
	## This state is when a minigame is being played.
	MINIGAME_ACTIVE,
	## This state is when a minigame just ended.
	MINIGAME_END
};

## An enum for the possible types of hooks in the fishing minigame.
enum HookType {
	## This is the default hook.
	DEFAULT,
	## This is the "upgraded hook" modifier hook, or a double hook.
	DOUBLE,
	## This is the "upgraded lure" modifier hook.
	LURE,
	## This is the "antivenom hook" modifier hook.
	ANTIVENOM
};
