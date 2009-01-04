package require Tk

# This function makes a canvas at path and a frame inside it.
# It returns the path to the canvas.
# The frame is at $path.frame
proc scrollableThing {path} {
	canvas $path
	set frame [frame $path.frame]
	$path create window 0 0 -tags CONTENTS -window $frame -anchor nw
	# This assumes that everything is in the frame and it's rendered
	# by 100ms from now
	after 100 "
		set height \[winfo reqheight $frame\]
		set width \[winfo reqwidth $frame\]
		$path configure -scrollregion \[list 0 0 \$width \$height\]
		$path itemconfigure CONTENTS -height \$height -width \$width
	"
	return $path
}
