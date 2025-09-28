extends Node;

## The name of the current minigame that is active. If this is an empty string, there is no chosen minigame.
var current_minigame: String = "";
## The steam/local ID of the current experimental group player. -1 means there is none.
var current_experimental_group: int = -1;
## An array of the steam/local IDs of the current control group players. An empty array means there are none.
var current_control_group: Array = [];
## A dictionary of the modifiers applied to the playres. An empty dictionary means there are none.
var current_modifiers: Dictionary = {};
## A dictionary of the current scores for the players. An empty dictionary means there are none.
var current_scores: Dictionary = {};
## The array of the names of all available minigames. UPDATE THIS WHENEVER A MINIGAME IS ADDED.
var available_minigames: Array = [
	"test_minigame",
];
## The modifier definitions for each available minigame. UPDATE THIS WHENEVER A MINIGAME IS ADDED.
var minigame_modifiers: Dictionary = {
	"test_minigame": {
		"experimental": [
			{"name": "Experimental Modifier 1", "description": "Experimental Modifier 1 Description"},
			{"name": "Experimental Modifier 2", "description": "Experimental Modifier 2 Description"},
			{"name": "Experimental Modifier 3", "description": "Experimental Modifier 3 Description"}
		],
		"control": [
			{"name": "Control Modifier 1", "description": "Control Modifier 1 Description"},
			{"name": "Control Modifier 2", "description": "Control Modifier 2 Description"},
			{"name": "Control Modifier 3", "description": "Control Modifier 3 Description"}
		]
	},
};


## Handles updates in game state.
func handle_game_state_update(new_game_state: Enums.GameState) -> void:
	match new_game_state:
		Enums.GameState.LOBBY:
			print("STATE UPDATE: LOBBY");
			current_experimental_group = -1;
			current_control_group.clear();
			current_modifiers.clear();
			current_scores.clear();
			
			current_minigame = available_minigames[randi() % (available_minigames.size())];
			
			## Add narrator dialogue and tv logic here
			
			var door: MinigameDoor = get_tree().current_scene.get_node("MinigameDoor");
			if door: door.open_door();
