package require Tk

# This function updates the size of the frame
proc updateScrollableThing {path} {
	set frame ${path}.frame
	set canHeight [winfo height $path]
	set height [winfo reqheight $frame ]

	if {$canHeight > $height} {
		set height $canHeight
	}

	set canWidth [winfo width $path]
	set width [winfo reqwidth $frame]

	if {$canWidth > $width} {
		set width $canWidth
	}

	$path configure -scrollregion [list 0 0 $width $height]
	$path itemconfigure CONTENTS -height $height -width $width
}

# This function makes a canvas at path and a frame inside it.
# It returns the path to the canvas.
# The frame is at $path.frame
proc scrollableThing {path} {
	canvas $path 
	set frame [frame ${path}.frame -background white ]
	$path create window 0 0 -tags CONTENTS -window $frame -anchor nw
	# This assumes that everything is in the frame and it's rendered
	# by 100ms from now
	after 100 "
		[list updateScrollableThing $path]
		[list bind $path <Configure> [list updateScrollableThing $path]]
		[list bind $frame <Configure> [list updateScrollableThing $path]]
	"

	return $path
}
