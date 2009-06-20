
# The instructions for how to do this were found at http://wiki.tcl.tk/1146
proc ratingWidget {path args} {
	global ratingWidgetOptions
	# Set some default options that will probably be configurable later.

	# This is the number stars
	set ratingWidgetOptions($path,numStars) 5
	# This is the number of points on the star
	set ratingWidgetOptions($path,numPoints) 5
	# This is the colour that is used for a star that aren't filled by data
	set ratingWidgetOptions($path,emptyColour) white
	# This is the colour of the stars that represent the community average rating
	set ratingWidgetOptions($path,averageColour) yellow
	# This is the colour of the stars that represent the user's rating
	set ratingWidgetOptions($path,userColour) red
	# This option is the radius from the centre of the star to its extremities (in px)
	set ratingWidgetOptions($path,pointRadius) 10
	# This option is the square size 
	set ratingWidgetOptions($path,troughRadius) 5
	# This is the width of the border
	set ratingWidgetOptions($path,borderWidth) 1
	# This is the padding between stars
	set ratingWidgetOptions($path,starPadding) 5
	# This is the value of the widget
	set ratingWidgetOptions($path,value) 0
	# This is the average value of the widget
	set ratingWidgetOptions($path,averageValue) 0
	# This sets whether or not the widget is readonly
	set ratingWidgetOptions($path,readonly) 0

	# Now, pull out our options, and pass the rest on to the canvas
	set screenedArgs [ratingWidgetConfiguration $path $args]

	# This is the square size of each star (Mostly a convenience)
	set ratingWidgetOptions($path,starSize) [expr $ratingWidgetOptions($path,pointRadius) * 2]

	# This builds the Canvas
	eval canvas $path $screenedArgs
	# Make the canvas the right size
	set canWidth [expr {$ratingWidgetOptions($path,starPadding) * ($ratingWidgetOptions($path,numStars)-1) + $ratingWidgetOptions($path,numStars) * $ratingWidgetOptions($path,starSize)}]
	$path configure -height $ratingWidgetOptions($path,starSize) -width $canWidth
	# This algorithm finds the points of the star, relative to the centre of the star
	set centredCoords [list]
	set angleInterval [expr {4*acos(0)/$ratingWidgetOptions($path,numPoints)}]
	for {set i 0} {$i < $ratingWidgetOptions($path,numPoints)} {incr i} {
		# Find the angle of the trough and point
		set point [expr $i * $angleInterval]
		set trough [expr {$point + ($angleInterval / 2)}]

		# I've switched around the X and Y, on purpose.
		# I wanted the first point to always be the top, so I transposed the image

		# X of point
		lappend centredCoords [expr {sin($point) * $ratingWidgetOptions($path,pointRadius)}]
		# Y of point
		lappend centredCoords [expr {cos($point) * $ratingWidgetOptions($path,pointRadius)}]

		# X of trough
		lappend centredCoords [expr {sin($trough) * $ratingWidgetOptions($path,troughRadius)}]
		# Y of trough
		lappend centredCoords [expr {cos($trough) * $ratingWidgetOptions($path,troughRadius)}]
	}

	#Now draw each star
	for {set i 0; set x $ratingWidgetOptions($path,pointRadius)} {$x < $canWidth} {incr i; set x [expr {$x + $ratingWidgetOptions($path,starSize) + $ratingWidgetOptions($path,starPadding)}]} {
		# Convert from our centred template to the current position
		set adjustedCoords [list]
		foreach {cX cY} $centredCoords {
			lappend adjustedCoords [expr $x - $cX]
			lappend adjustedCoords [expr $ratingWidgetOptions($path,pointRadius) - $cY]
		}
		set tag "star$i"
		$path create polygon $adjustedCoords -tag $tag -fill $ratingWidgetOptions($path,emptyColour) -outline black -width $ratingWidgetOptions($path,borderWidth) 
		if {!$ratingWidgetOptions($path,readonly)} {
			$path bind $tag <Enter> [list ratingWidgetEnter $path $tag]
			$path bind $tag <Leave> [list ratingWidgetLeave $path $tag]
			$path bind $tag <Button-1> [list ratingWidgetButton1 $path $tag]
		}
	}

	# This hides the Canvas's default command.
	interp hide {} $path
	# Then make our command aliased to that path
	interp alias {} $path {} ratingWidgetCommand $path
	# Then return the path
	return $path
}

# This command handles the Enter binding.
proc ratingWidgetEnter {widget tag} {
	global ratingWidgetOptions
	set value [expr [string range $tag 4 end] + 1]
	ratingWidgetDraw $widget $ratingWidgetOptions($widget,userColour) $value
}

# This handles the Leave binding
proc ratingWidgetLeave {widget tag} {
	ratingWidgetDrawBaseState $widget
}

# This handles the Button-1 binding. (Click)
proc ratingWidgetButton1 {widget tag} {
	set value [expr [string range $tag 4 end] + 1]
	$widget set $value
}

# This command draws the widget in a given colour to be a given value
proc ratingWidgetDraw {path colour value} {
	global ratingWidgetOptions
	for {set i 0} {$i < $ratingWidgetOptions($path,numStars)} {incr i} {
		if {$i < $value} {
			$path itemconfigure star$i -fill $colour
		} else {
			$path itemconfigure star$i -fill $ratingWidgetOptions($path,emptyColour)
		}
	}
}

# This command draws the widget in it's base state, whatever that may be
proc ratingWidgetDrawBaseState {widget} {
	global ratingWidgetOptions
	if {$ratingWidgetOptions($widget,value) == 0} {
		ratingWidgetDraw $widget $ratingWidgetOptions($widget,averageColour) $ratingWidgetOptions($widget,averageValue)
	} else {
		ratingWidgetDraw $widget $ratingWidgetOptions($widget,userColour) $ratingWidgetOptions($widget,value)
	}
}

# This command parses and sets configuration options from a list
# It returns all pairs that it doesn't understand
proc ratingWidgetConfiguration {widget argList} {
	global ratingWidgetOptions 

	set passThrough [list]
	foreach {opt val} [split $argList " "] {
		switch -- $opt {
			-numStars - 
			-numPoints - 
			-emptyColour - 
			-userColour - 
			-averageColour - 
			-pointRadius - 
			-troughRadius - 
			-borderWidth - 
			-starPadding - 
			-readonly {
				# Recognize these ones
				set ratingWidgetOptions($widget,[string range $opt 1 end]) $val
			}
			default {
				# Don't know this one, pass it through
				lappend passThrough $opt $val
			}
		}
	}
	return [join $passThrough]
}

# This is the command that is run when using the widget's name
proc ratingWidgetCommand {self cmd args} {
	global ratingWidgetOptions
	switch -- $cmd {
		set {
			# This command both set the value
			set ratingWidgetOptions($self,value) $args
			ratingWidgetDrawBaseState $self
			event generate $self <<Rate>> -root $self -data $args
		}
		avgSet {
			# This command will set the average value
			set ratingWidgetOptions($self,averageValue) $args
			ratingWidgetDrawBaseState $self
		}
		get {
			# This command returns the value
			return $ratingWidgetOptions($self,value)
		}
		avgGet {
			# This commnd returns the current average value
			return $ratingWidgetOptions($self,averageValue)
		}
		default { return [uplevel 1 [list interp invokehidden {} $self $cmd] $args] }
	}
}
