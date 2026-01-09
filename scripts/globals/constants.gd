extends Node;

## A constant for limiting gravity acceleration in gravity equations. Used in VelocityComponent, but there may be other uses.
var GRAV_CONSTANT: float = 0.3625;

## The AppID for the game on Steam. The default is 480. Replace this once the game actually has a Steam page.
var APP_ID: String = "480";

## The packet read limit. This is how many packets of data a server can read at a time.
var PACKET_READ_LIMIT: int = 32;

## The colors for our game.
var GAME_COLORS: Dictionary = {
	"control": Color((25.0 / 256.0), (163.0 / 256.0), (255.0 / 256.0), 1.0),
	"experimental": Color((255.0 / 256.0), (213.0 / 256.0), (25.0 / 256.0), 1.0),
	"light_gray": Color((196.0 / 256.0), (193.0 / 256.0), (192.0 / 256.0), 1.0),
	"gray": Color((139.0 / 256.0), (137.0 / 256.0), (137.0 / 256.0), 1.0),
	"dark_gray": Color((67.0 / 256.0), (66.0 / 256.0), (65.0 / 256.0), 1.0), ## You suck Manogna how did you get 67 in here
};


## The super secret code
var SUPER_SECRET_CODE: String = "eXp3r1MEn7";
