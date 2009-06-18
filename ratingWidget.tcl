
# The instructions for how to do this were found at http://wiki.tcl.tk/1146
proc ratingWidget {path args} {
	# This builds the Canvas
	eval canvas $path $args
	# Make the canvas be 20x20 and green
	$path configure -background green -height 20 -width 20
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
