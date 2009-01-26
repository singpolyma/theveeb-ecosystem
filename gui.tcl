package require Tk
catch {package require tile}
if [catch {ttk::setTheme aqua}] {
	if [catch {ttk::setTheme tilegtk}] {
		catch {ttk::setTheme tileqt}
	}
}
catch {namespace import -force ttk::*}
source scrollable.tcl

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
set description [label ${tabArea}.label -text "Package Description"]
set reviews [frame ${tabArea}.review]
set feedback [frame ${tabArea}.feedback]

$tabArea add $description -text "Package Description" -sticky news
$tabArea add $reviews -text "Reviews" -state disabled -sticky news
$tabArea add $feedback -text "Feedback" -state disabled -sticky news

pack $tabArea -fill both -expand 1 -side top

set pkgs [split [exec search/search ""] "\n"]
puts $pkgs

set i 0
set highlightedrow 0
foreach {item} $pkgs {
	regexp {^(.)\s+(.+?)\s+(.+?)\s+(.+)$} $item matches status pkg version desc
	canvas ${canvas}.frame.row$i -highlightbackground #abc -highlightthickness 0
	grid ${canvas}.frame.row$i -pady 2 -sticky nwe -row $i

	set cb [checkbutton ${canvas}.frame.row${i}.check -variable check$i]
	set icon [canvas $canvas.frame.row$i.icon -height 24 -width 24 -background blue]
	set name [label ${canvas}.frame.row$i.desc -text $pkg -anchor w -font TkHeadingFont]
	set desc [label ${canvas}.frame.row$i.longer -text $desc -anchor w]

	# Should get longer info from search eventually
	set handler "$description configure -text $pkg
	             ${canvas}.frame.row\$highlightedrow configure -highlightthickness 0
	             set highlightedrow $i
	             ${canvas}.frame.row$i configure -highlightthickness 2
	             "
	bind ${canvas}.frame.row$i <ButtonPress-1> $handler
	bind $name <ButtonPress-1> $handler
	bind $icon <ButtonPress-1> $handler
	bind $desc <ButtonPress-1> $handler

	if {$status == "U" || $status == "I"} {$cb invoke}

	grid $cb -column 0 -rowspan 2 -padx 5 -row $i
	grid $icon -column 1 -rowspan 2 -padx 5 -row $i
	grid $name -column 2 -padx 5 -pady 2 -sticky nwe -row $i
	grid $desc -column 2 -padx 5 -pady 2 -sticky nwe -row [expr {1+$i}]

	grid columnconfigure ${canvas}.frame.row$i 2 -weight 1

	incr i 2
}
