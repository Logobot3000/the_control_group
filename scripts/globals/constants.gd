extends Node

## A constant for limiting gravity acceleration in gravity equations. Used in VelocityComponent, but there may be other uses.
var GRAV_CONSTANT: float = 0.3625;

## The AppID for the game on Steam. The default is 480. Replace this once the game actually has a Steam page.
var APP_ID: String = "480";

## The packet read limit. This is how many packets of data a server can read at a time.
var PACKET_READ_LIMIT: int = 32;
