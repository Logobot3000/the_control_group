extends Node

## An enum for the types of movement modes the VelocityComponent supports
enum MovementMode {
	## Allows for free movement in both the X and Y axes
	FREEFLYING,
	## Allows for free movement in the X axis, while the Y axis is affected by gravity
	PLATFORMER
};
