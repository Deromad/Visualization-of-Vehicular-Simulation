extends Node3D
func rotatio(lat:float, long :float):
	var X_achse = $x_achse
	rotate_x(deg_to_rad(lat))
	X_achse.rotate_z(deg_to_rad(long))
