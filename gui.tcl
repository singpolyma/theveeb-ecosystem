package require Tk
catch {package require tile}
if [catch {ttk::setTheme aqua}] {
	if [catch {ttk::setTheme tilegtk}] {
		catch {ttk::setTheme tileqt}
	}
}
catch {namespace import -force ttk::*}
source scrollable.tcl
source textvariable.tcl

proc clearScrollableThing {widget} {
	foreach item [grid slaves ${widget}.frame] {
		grid forget $item
		destroy $item
	}
}

proc drawPackageList {destination data} {
	global highlightedrow
	global selectedPackages
	set i 0
	set highlightedrow 0
	foreach {item} $data {
		array set temp $item

		canvas ${destination}.frame.row$i -highlightbackground #abc -highlightthickness 0
		grid ${destination}.frame.row$i -pady 2 -sticky nwe -row $i

		# When reading the database, only use its value if we haven't already picked one
		# This fixes the problem where anytime the list is reread it would clobber your selection changes.
		if {![info exists selectedPackages($temp(package))]} {
			if {$temp(status) != "not installed"} {
				set selectedPackages($temp(package)) 1
			} else {
				set selectedPackages($temp(package)) 0
			}
		}

		set cb [checkbutton ${destination}.frame.row${i}.check -variable selectedPackages($temp(package)) -command [list checkChanged $temp(package)]]
		set icon [canvas $destination.frame.row$i.icon -height 24 -width 24 -background blue]
		set name [label ${destination}.frame.row$i.desc -text $temp(title) -anchor w -font TkHeadingFont]
		set desc [label ${destination}.frame.row$i.longer -text $temp(descText) -anchor w]
		set price [label ${destination}.frame.row$i.price -text $temp(price) -anchor e]

		# Should get longer info from search eventually
		set handler "set currentPackage(title) {$temp(title)}
								 set currentPackage(caption) {$temp(descText)}
								 set currentPackage(longText) {$temp(longDesc)}
								 set currentPackage(price) {$temp(price)}
								 set currentPackage(package) {$temp(package)}
								 ${destination}.frame.row\$highlightedrow configure -highlightthickness 0
								 \$tabArea tab \$feedback -state normal
								 set highlightedrow $i
								 ${destination}.frame.row$i configure -highlightthickness 2
								 "
		bind ${destination}.frame.row$i <ButtonPress-1> $handler
		bind $name <ButtonPress-1> $handler
		bind $icon <ButtonPress-1> $handler
		bind $desc <ButtonPress-1> $handler

		grid $cb -column 0 -rowspan 2 -padx 5 -row $i
		grid $icon -column 1 -rowspan 2 -padx 5 -row $i
		grid $name -column 2 -padx 5 -pady 2 -sticky nwe -row $i
		grid $desc -column 2 -padx 5 -pady 2 -sticky nwe -row [expr {1+$i}]
		grid $price -column 3 -sticky e -row $i

		grid columnconfigure ${destination}.frame.row$i 2 -weight 1

		incr i 2
	}
}

proc lineTrim {words} {
	upvar $words temp
	set temp [string trim $temp]
	regsub {\s*\n\s*} $temp \n temp
}

proc getPackList {text category} {
	set command [list search/search -v]
	if {$category !=""} {
		lappend command "-i$category"
	}
	lappend command $text
	if {[catch {eval "exec $command"} rawOutput]!=0} {
		if {[string match "*database may not exist*" $rawOutput]} {
			tk_messageBox -message "We seem to be having trouble finding the database.\nMake sure the environment is set up properly, and the database file exists."
		} else {
			# If we have nothing more important to say
			# Print out the error raw.
			tk_messageBox -message "Internal Error:\n$rawOutput" -type ok
		}
		exit
	}
	set output [split [string map [list "\n\n" \0] $rawOutput] \0]

	set packList [list]
	foreach pack $output {
		array set temp [list]

		#This part runs all of the parses, and if any of them fail the error part runs
		if {!(
			[regexp {Package: ([^\n]*)\n} $pack mat temp(package)] && 
			[regexp {Status: ([^\n]*)\n} $pack mat temp(status)] &&
			[regexp {Description: ([^\n]*)\n(.*)} $pack mat temp(descText) temp(longDesc)]
			)
		} {
			# ERROR
			puts "Package parse error: \n$rawOutput"
			return [list]
		}
		lineTrim temp(longDesc)

		#If it exists (It doesn't have to), fill in the name
		if {[regexp {Name: ([^\n]*)\n} $pack mat temp(name)]} {
			#There is a name
			set temp(title) $temp(name)
		} else {
			#There is no name, show the package name instead
			set temp(title) $temp(package)
		}

		if {![regexp {Price: ([^\n]*)\n} $pack mat temp(price)]} { 
			#If no price
			#Free
			set temp(price) "Free"
		}

		lappend packList [array get temp]
	}
	return $packList
}

proc filter {listWidget text category} {
	clearScrollableThing $listWidget
	drawPackageList $listWidget [getPackList $text $category]
}

proc categoryUpdate {path} {
	global filterCategory
	global filterCategoryDisplayNameMap
	# Get the data from the comboBox
	# Convert from the view value to the data value
	set filterCategory $filterCategoryDisplayNameMap([$path get])
	# If the value is "All"
	if {$filterCategory == ""} {
		# Set the value to be "Category"
		$path set "Category"
		$path selection clear
	}
	# Filter
	getDataAndFilter
}

proc getDataAndFilter {} {
	global canvas 
	global searchQuery
	global filterCategory
	filter $canvas $searchQuery $filterCategory
}

# This function does all that's needed to quit
proc safeQuit {} {
	# For now, just quit
	exit
}

# This function is called when a checkbutton is clicked
# It manages the "original" thing
proc checkChanged {package} {
	global originalValues
	global selectedPackages

	if {[info exists originalValues($package)]} {
		# There's already a value here
		if {$selectedPackages($package) == $originalValues($package)} {
			# If the new value is the same as the original, get rid of that entry in the original
			unset originalValues($package)
		}
	} else {
		# We don't have an original, so we can only guess it's the opposite of the current
		if {$selectedPackages($package) == 0} {
			set originalValues($package) 1
		} else {
			set originalValues($package) 0
		}
	}
}

# This function gets a list of all packages to be changed
# The output list is a list of lists
# Each element is the packages name and the operation, either "1" for install, or "0" for uninstall
proc getDiff {} {
	global originalValues
	global selectedPackages
	set result [list]
	# Go through each entry in originalValues, use the selectedValue
	foreach {package} [array names originalValues] {
		lappend result [list $package $selectedPackages($package)]
	}

	return $result
}

# This is the command of the "Do It" button
proc DoIt {} {
	puts [getDiff]
}

# This is the command to send feedback
proc sendFeedback {textWindow typeWindow} {
	global tcl_platform
	global currentPackage

	if {![info exists currentPackage(package)]} {
		tk_messageBox -message "You must select a package before you can send feedback about it" -type ok
		return
	}
	set feedback(body) [$textWindow get 1.0 end]
	$textWindow delete 1.0 end

	set feedback(type) [$typeWindow get]

	set feedback(package) $currentPackage(package)

	set feedback(os) $tcl_platform(os)
	set feedback(osVersion) $tcl_platform(osVersion)
	set feedback(machine) $tcl_platform(machine)
	set feedback(platform) $tcl_platform(platform)

	puts [array get feedback]
}

# Get the main scrollable canvas
set canvas [scrollableThing .can]
$canvas configure -yscrollcommand {.yscroll set}
scrollbar .yscroll -orient vertical -command {$canvas yview}

# Get scrollable view area
set viewarea [frame .viewarea]

# Make the top area.
set topBar [frame .topBar]

# Make the category box
set categoryArea [frame .categoryArea]

# Set the map that maps from display name to data name
array set filterCategoryDisplayNameMap [list Action actiongame Adventure adventuregame Arcade arcadegame "Board Game" boardgame "Blocks Game" blocksgame "Card Game" cardgame "Kids" kidsgame "Logic" logicgame "Role Playing" roleplaying Simulation simulation Sports sportsgame Strategy strategy]

# Then get the sorted list of categories, with "All" at the start
set categoryList [concat All [lsort [array names filterCategoryDisplayNameMap]]]

# Add the mapping form "All" to the filter
set filterCategoryDisplayNameMap(All) ""

# Find the required width of the combobox
set categoryMaxWidth 0
foreach item [concat "Category" $categoryList] {
	if {[string length $item] > $categoryMaxWidth} {
		set categoryMaxWidth [string length $item]
	}
}
# Make the actual box
set categoryCombo [ttk::combobox ${topBar}.categoryCombo -value $categoryList -width $categoryMaxWidth]
# Set the categoryCombo boxes value to Category
$categoryCombo set "Category"
# Set up the binding
bind $categoryCombo <<ComboboxSelected>> {categoryUpdate %W}

# Make seach Bar
set searchBar [entry ${topBar}.bar -width 20 -textvariable searchQuery]
set searchButton [button ${topBar}.button -text "Search" -command getDataAndFilter]
bind $searchBar <Return> "$searchButton invoke"
grid $categoryCombo $searchBar $searchButton
grid $searchBar -sticky ew
grid $searchButton -sticky e
# Make the seach box expand when the window does
grid columnconfigure $topBar 1 -weight 1

# Grid the top bar
grid $topBar -sticky ew

# Grid the canvas and scrollbar
grid $canvas .yscroll
grid $canvas -sticky news
grid .yscroll -sticky ns

# Grid the viewarea
grid $viewarea -
grid $viewarea -sticky news

# Make grid fill window
grid rowconfigure . 1 -weight 1
grid rowconfigure . 2 -weight 2
grid columnconfigure . 0 -weight 1

# And make rows fill canvas
grid columnconfigure ${canvas}.frame 0 -weight 1

# Add label to viewarea
set tabArea [ttk::notebook ${viewarea}.tabArea]

set description [frame ${tabArea}.description]
set description.topLine [frame ${description}.topLine]
set description.title [label ${description.topLine}.title -textvariable currentPackage(title) -font TkHeadingFont -justify left]
set description.caption [label ${description}.caption -textvariable currentPackage(caption) -justify left]
set description.longText [text ${description}.longText -wrap word]
set description.price [label ${description.topLine}.price -textvariable currentPackage(price) -justify right]

# Set up the scrolling
set description.scrollbar [scrollbar ${description}.scrollbar -command "${description.longText} yview"]
${description.longText} configure -yscrollcommand "${description.scrollbar} set"

# Set up the text box to update when the variable's changed.
textvariable ${description.longText} currentPackage(longText)

# Layout the top line
grid ${description.title} ${description.price}
grid ${description.title} -sticky nw
grid ${description.price} -sticky ne
# And set price to expand to fill its size 
grid columnconfigure ${description.topLine} 1 -weight 1

grid ${description.topLine} -sticky ew
grid ${description.caption} -sticky nw
grid ${description.longText} ${description.scrollbar}

grid ${description.longText} -sticky news
grid ${description.scrollbar} -sticky ns

grid columnconfigure $description 0 -weight 1
grid rowconfigure $description 2 -weight 1

set reviews [frame ${tabArea}.review]

# Setup Feedback page
set feedback [frame ${tabArea}.feedback]
# Type box
set feedback.typeBox [frame ${feedback}.typeBox]
set feedback.typeLabel [label ${feedback.typeBox}.typeLabel -text "Type: "]
set feedback.type [ttk::combobox ${feedback.typeBox}.type -value [list "Report Bug" "Request Feature" "Other"]]
${feedback.type} set "Other"
grid ${feedback.typeLabel} ${feedback.type}

# Main Feedback form
set feedback.box [text ${feedback}.box]
set feedback.scroll [scrollbar ${feedback}.scroll -command [list ${feedback.box} yview]]
${feedback.box} configure -yscrollcommand [list ${feedback.scroll} set]
# And send button
set feedback.send [button ${feedback}.send -text "Send" -command [list sendFeedback ${feedback.box} ${feedback.type}]]
grid ${feedback.typeBox} -sticky w
grid ${feedback.box} ${feedback.scroll} -sticky news
grid ${feedback.send} -sticky n
grid columnconfigure $feedback 0 -weight 1
grid rowconfigure $feedback 1 -weight 1

$tabArea add $description -text "Package Description" -sticky news
$tabArea add $reviews -text "Reviews" -state disabled -sticky news
$tabArea add $feedback -text "Feedback" -state disabled -sticky news

pack $tabArea -fill both -expand 1 -side top

# Set up the bottom bar
set bottomBar [frame .buttonBar]

set quitButton [button ${bottomBar}.quit -text "Quit" -command safeQuit]
set commitButton [button ${bottomBar}.commit -text "Do it" -command DoIt]

grid $quitButton $commitButton
grid $bottomBar

# Initialize Filter
set searchQuery ""
set filterCategory ""

set pkgs [getPackList "" ""]

drawPackageList $canvas $pkgs
