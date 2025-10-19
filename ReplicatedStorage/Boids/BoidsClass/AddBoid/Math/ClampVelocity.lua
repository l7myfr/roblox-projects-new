-- @ScriptType: ModuleScript


return function(boid)
	local Velo = boid.Velocity
	local Dir = Velo.Unit
	local speed = Velo.magnitude
	if Dir ~= Dir then
		boid.Velocity = Vector3.zero
	else
		speed = math.clamp(speed, boid.Settings.MinSpeed, boid.Settings.MaxSpeed);
		boid.Velocity = Dir * speed
	end
end
