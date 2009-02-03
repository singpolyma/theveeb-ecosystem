package require Tk
catch {package require tile}
if [catch {ttk::setTheme aqua}] {
	if [catch {ttk::setTheme tilegtk}] {
		catch {ttk::setTheme tileqt}
	}
}
catch {namespace import -force ttk::*}
source scrollable.tcl

proc clearScrollableThing {widget} {
	foreach item [grid slaves ${widget}.frame] {
		grid forget $item
		destroy $item
	}
}

proc drawPackageList {destination data} {
	global highlightedrow
	set i 0
	set highlightedrow 0
	foreach {item} $data {
		regexp {^(.)\s+(.+?)\s+(.+?)\s+(.+)$} $item matches status pkg version descText

		canvas ${destination}.frame.row$i -highlightbackground #abc -highlightthickness 0
		grid ${destination}.frame.row$i -pady 2 -sticky nwe -row $i

		set cb [checkbutton ${destination}.frame.row${i}.check -variable check$i]
		set icon [canvas $destination.frame.row$i.icon -height 24 -width 24 -background blue]
		set name [label ${destination}.frame.row$i.desc -text $pkg -anchor w -font TkHeadingFont]
		set desc [label ${destination}.frame.row$i.longer -text $descText -anchor w]

		# Should get longer info from search eventually
		set handler "set currentPackage(title) {$pkg}
								 set currentPackage(caption) {$descText}
								 set currentPackage(longText) {This is where the long description of the package should go.\n For example:\n This pacakge is $pkg, it is a $descText}
								 ${destination}.frame.row\$highlightedrow configure -highlightthickness 0
								 set highlightedrow $i
								 ${destination}.frame.row$i configure -highlightthickness 2
								 "
		bind ${destination}.frame.row$i <ButtonPress-1> $handler
		bind $name <ButtonPress-1> $handler
		bind $icon <ButtonPress-1> $handler
		bind $desc <ButtonPress-1> $handler

		#This had to be changed, invoke was toggling it, which worked the first time, but toggled every time after that.
		if {$status == "U" || $status == "I"} {
			$cb select
		} else {
			$cb deselect
		}

		grid $cb -column 0 -rowspan 2 -padx 5 -row $i
		grid $icon -column 1 -rowspan 2 -padx 5 -row $i
		grid $name -column 2 -padx 5 -pady 2 -sticky nwe -row $i
		grid $desc -column 2 -padx 5 -pady 2 -sticky nwe -row [expr {1+$i}]

		grid columnconfigure ${destination}.frame.row$i 2 -weight 1

		incr i 2
	}
}

# Get the main scrollable canvas
set canvas [scrollableThing .can]
$canvas configure -yscrollcommand {.yscroll set}
scrollbar .yscroll -orient vertical -command {$canvas yview}

# Get scrollable view area
set viewarea [scrollableThing .viewarea]
$viewarea configure -yscrollcommand {.viewyscroll set}
scrollbar .viewyscroll -orient vertical -command {$viewarea yview}

# Grid the canvas and scrollbar
grid $canvas .yscroll
grid $canvas -sticky news
grid .yscroll -sticky ns

# Grid the viewarea and scrollbar
grid $viewarea .viewyscroll
grid $viewarea -sticky news
grid .viewyscroll -sticky ns

# Make grid fill window
grid rowconfigure . 0 -weight 1
grid columnconfigure . 0 -weight 1

# And make rows fill canvas
grid columnconfigure ${canvas}.frame 0 -weight 1

# Add label to viewarea
set tabArea [ttk::notebook ${viewarea}.frame.tabArea]

set description [frame ${tabArea}.description]
set description.title [label ${description}.title -textvariable currentPackage(title) -font TkHeadingFont -justify left]
set description.caption [label ${description}.caption -textvariable currentPackage(caption) -justify left]
set description.longText [label ${description}.longText -textvariable currentPackage(longText) -justify left]
grid ${description.title} -sticky nw
grid ${description.caption} -sticky nw
grid ${description.longText} -sticky nwes

set reviews [frame ${tabArea}.review]
set feedback [frame ${tabArea}.feedback]

$tabArea add $description -text "Package Description" -sticky news
$tabArea add $reviews -text "Reviews" -state disabled -sticky news
$tabArea add $feedback -text "Feedback" -state disabled -sticky news

pack $tabArea -fill both -expand 1 -side top

set pkgs [split [exec search/search ""] "\n"]
puts $pkgs

drawPackageList $canvas $pkgs
