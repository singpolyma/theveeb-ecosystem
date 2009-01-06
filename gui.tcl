package require Tk
catch {package require tile}
if [catch {ttk::setTheme tilegtk}] {
	catch {ttk::setTheme tileqt}
}
#catch {namespace import -force ttk::*}
source scrollable.tcl

# Get the main scrollable canvas
set canvas [scrollableThing .can]
$canvas configure -yscrollcommand {.yscroll set}
scrollbar .yscroll -orient vertical -command {$canvas yview}

# Get scrollable view area
set viewarea [scrollableThing .viewarea]
$viewarea configure -yscrollcommand {.viewyscroll set}
scrollbar .viewyscroll -orient vertical -command {$viewarea yview}

# Grid the canvas an scrollbar
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

# Add label to viewarea
set viewlabel [label ${viewarea}.frame.label -text "Package Description"]
pack $viewlabel -fill both

set pkgs [split [exec search/search ""] "\n"]
puts $pkgs

set i 0
foreach {item} $pkgs {
	regexp {^(.)\s+(.+?)\s+(.+?)\s+(.+)$} $item matches status pkg version desc
	frame ${canvas}.frame.row$i -highlightbackground "#abc" -highlightthickness 2
	grid ${canvas}.frame.row$i -sticky nw -row $i

	set cb [checkbutton ${canvas}.frame.row${i}.check -variable check$i]
	set icon [canvas $canvas.frame.row$i.icon -height 24 -width 24 -background blue]
	set name [label ${canvas}.frame.row$i.desc -text $pkg]
	set desc [label ${canvas}.frame.row$i.longer -text $desc]

	# Should get longer info from search eventually
	set handler "$viewlabel configure -text $pkg"
	bind ${canvas}.frame.row$i <ButtonPress-1> $handler
	bind $name <ButtonPress-1> $handler
	bind $icon <ButtonPress-1> $handler
	bind $desc <ButtonPress-1> $handler

	if {$status == "U" || $status == "I"} {$cb invoke}

	grid $cb -column 0 -rowspan 2 -padx 5 -row $i
	grid $icon -column 1 -rowspan 2 -padx 5 -row $i
	grid $name -column 2 -padx 5 -sticky nw -row $i
	grid $desc -column 2 -padx 5 -sticky nw -row [expr {1+$i}]

	incr i 2
}
