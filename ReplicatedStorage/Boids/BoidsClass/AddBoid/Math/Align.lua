-- @ScriptType: ModuleScript
return function(Boid) 
	local AlignmentVelocity = Vector3.zero
	local AlignmentBoids = Boid.VisibleBoids.Alignment
	for _, OtherBoid in AlignmentBoids do
		AlignmentVelocity += OtherBoid.Velocity
	end
	local NumAlignmentBoids = #AlignmentBoids
	if NumAlignmentBoids > 0 then
		AlignmentVelocity /= NumAlignmentBoids
		AlignmentVelocity *= Boid.Settings.AlignmentFactor
	end
	return AlignmentVelocity
end
