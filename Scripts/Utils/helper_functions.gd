extends Node

class_name HelperFunctions

# static -> be able to call this from anywhere
static func ClientInterpolate(global_position, target_position, delta, lerp_speed = 25):
	if target_position == Vector2.INF:
		return global_position
	
	# if the position is too far away because it didnt sync, be teleported there
	# length is a very expensive calculation compared to length_squared
	if (global_position - target_position).length_squared() > 100 * 100:
		return target_position
	
	return lerp(target_position, global_position, pow(0.5, delta * lerp_speed))
