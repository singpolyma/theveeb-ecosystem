package require Tk
catch {package require tile}
if [catch {ttk::setTheme tilegtk}] {
	catch {ttk::setTheme tileqt}
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

set pkgs [split [exec search/search ""] "\n"]

set i 0
foreach {item} $pkgs {
	regexp {^(.)\s+(.+?)\s+(.+?)\s+(.+)$} $item matches status name version desc
	set cb [checkbutton ${canvas}.frame.check$i]
	set icon [canvas $canvas.frame.icon$i -height 24 -width 24 -background blue]
	set name [label ${canvas}.frame.desc$i -text $name]
	set desc [label ${canvas}.frame.longer$i -text $desc]
	# Invoke may be ttk only... may need to catch that
	if {$status == "U" || $status == "I"} {$cb invoke}
	grid $cb -column 0 -rowspan 2 -padx 5 -row $i
	grid $icon -column 1 -rowspan 2 -padx 5 -row $i
	grid $name -column 2 -padx 5 -sticky nw -row $i
	grid $desc -column 2 -padx 5 -sticky nw -row [expr {1+$i}]
	incr i 2
}

# Add label to viewarea
set viewlabel [label ${viewarea}.frame.label -text "Package Description"]
pack $viewlabel -fill both
