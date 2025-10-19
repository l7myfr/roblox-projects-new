-- @ScriptType: ModuleScript
return function(Boid) 
	local CohesionVelocity = Vector3.zero
	local VelocityTowards = Vector3.zero
	local CohesionBoids = Boid.VisibleBoids.Cohesion
	for _, OtherBoid in CohesionBoids do
		VelocityTowards += OtherBoid.Position
	end
	local NumAlignmentBoids = #CohesionBoids
	if NumAlignmentBoids > 0 then
		VelocityTowards /= NumAlignmentBoids
		local Dir = VelocityTowards - Boid.Position
		Dir = Dir.Unit
		CohesionVelocity = Dir * Boid.Settings.CohesionFactor
	end
	return CohesionVelocity
end
