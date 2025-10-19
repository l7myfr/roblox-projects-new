-- @ScriptType: ModuleScript
return function(Boid) 
	local separationVelocity = Vector3.zero
	local separationBoids = Boid.VisibleBoids.Separation
	for _, OtherBoid in separationBoids do
		local BoidPosition = Boid.Position
		local OtherBoidPosition = OtherBoid.Position
		local displacement = BoidPosition - OtherBoidPosition
		local Distance = (BoidPosition- OtherBoidPosition).Magnitude
		local TravelDir = displacement.Unit
		local VelocityWeight = TravelDir / Distance
		separationVelocity += VelocityWeight
	end
	local NumseparationBoids = #separationBoids
	if NumseparationBoids > 0 then
		separationVelocity /= NumseparationBoids
		separationVelocity *= Boid.Settings.SeperationFactor
	end
	return separationVelocity
end
