# This function is intended to connect a text box to a variable
# It's intended to be for display purposes only
proc textvariable {textWindow variable} {
	# Get the variable
	upvar #0 $variable innerVar

	# This is just an optimization
	# If we're going to be setting this with a variable, turn off undo
	$textWindow configure -undo 0

	# Add the trace
	trace add variable innerVar write [list changeTextValue $textWindow]
}

# This is the function that gets called everytime the variable is changed
proc changeTextValue {window name1 name2 op} {
	# Get the value of the variable
	if {$name2 == ""} {
		upvar 1 $name1 innerVar
	} else {
		upvar 1 $name1 arrayVar
		upvar 0 arrayVar($name2) innerVar
	}

	# Unlock the output box
	$window configure -state normal

	# Clear the output box
	$window delete 1.0 end

	# Insert the new text
	$window insert 1.0 $innerVar

	# Lock the output box again
	$window configure -state disabled
}
