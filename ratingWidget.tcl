
# The instructions for how to do this were found at http://wiki.tcl.tk/1146
proc ratingWidget {path args} {
	# Set some default options that will probably be configurable later.

	# This is the number stars
	set option(numStars) 5
	# This is the number of points on the star
	set option(numPoints) 5
	# This is the colour that is used for a star that aren't filled by data
	set option(emptyColour) white
	# This is the colour of the stars that represent the community average rating
	set option(averageColour) yellow
	# This is the colour of the stars that represent the user's rating
	set option(userColour) red
	# This option is the radius from the centre of the star to its extremities (in px)
	set option(pointRadius) 10
	# This option is the square size 
	set option(troughRadius) 5
	# This is the square size of each star (Mostly a convenience)
	set option(starSize) [expr $option(pointRadius) * 2]
	# This is the width of the border
	set option(borderWidth) 1
	# This is the padding between stars
	set option(starPadding) 5
	# This builds the Canvas
	eval canvas $path $args
	# Make the canvas the right size
	set canWidth [expr {$option(starPadding) * ($option(numStars)-1) + $option(numStars) * $option(starSize)}]
	$path configure -height $option(starSize) -width $canWidth
	# This algorithm finds the points of the star, relative to the centre of the star
	set centredCoords [list]
	set angleInterval [expr {4*acos(0)/$option(numPoints)}]
	for {set i 0} {$i < $option(numPoints)} {incr i} {
		# Find the angle of the trough and point
		set point [expr $i * $angleInterval]
		set trough [expr {$point + ($angleInterval / 2)}]

		# I've switched around the X and Y, on purpose.
		# I wanted the first point to always be the top, so I transposed the image

		# X of point
		lappend centredCoords [expr {sin($point) * $option(pointRadius)}]
		# Y of point
		lappend centredCoords [expr {cos($point) * $option(pointRadius)}]

		# X of trough
		lappend centredCoords [expr {sin($trough) * $option(troughRadius)}]
		# Y of trough
		lappend centredCoords [expr {cos($trough) * $option(troughRadius)}]
	}

	#Now draw each star
	for {set x $option(pointRadius)} {$x < $canWidth} {set x [expr {$x + $option(starSize) + $option(starPadding)}]} {
		# Convert from our centred template to the current position
		set adjustedCoords [list]
		foreach {cX cY} $centredCoords {
			lappend adjustedCoords [expr $x - $cX]
			lappend adjustedCoords [expr $option(pointRadius) - $cY]
		}
		$path create polygon $adjustedCoords -fill $option(emptyColour) -outline black -width $option(borderWidth) 
	}

	# This hides the Canvas's default command.
	interp hide {} $path
	# Then make our command aliased to that path
	interp alias {} $path {} ratingWidgetCommand $path
	# Then return the path
	return $path
}

# This is the command that is run when using the widget's name
proc ratingWidgetCommand {self cmd args} {
	switch -- $cmd {
		default { return [uplevel 1 [list interp invokehidden {} $self $cmd] $args] }
	}
}
