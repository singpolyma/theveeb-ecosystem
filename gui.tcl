#!/usr/bin/wish

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
source ratingWidget.tcl

proc findTVEbinary {script {prefix tve-}} {
	global argv0
	set localpath [file join [file dirname $argv0] $script $script]
	if [file readable $localpath] {
		return $localpath
	} else {
		return $prefix$script
	}
}

proc findTVEscript {script {prefix tve-}} {
	global argv0
	set localpath [file join [file dirname $argv0] ${script}.sh]
	if [file readable $localpath] {
		return $localpath
	} else {
		return $prefix$script
	}
}

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
		set price [label ${destination}.frame.row$i.price -text "$temp(price) ¤" -anchor e]
		set rating [ratingWidget ${destination}.frame.row$i.rating -readonly 1 -pointRadius 8 -troughRadius 3]
		$rating avgSet $temp(rating)

		# If this package has been purchased, make the price's background greenish
		if {[info exists temp(owns)] && [string length [string trim $temp(owns)]] != 0} {
			$price configure -background "#AAFFAA"
		}

		# Should get longer info from search eventually
		set handler "set currentPackage(title) {$temp(title)}
								 set currentPackage(caption) {$temp(descText)}
								 set currentPackage(longText) {$temp(longDesc)}
								 set currentPackage(price) {$temp(price) ¤}
								 set currentPackage(package) {$temp(package)}
								 ${destination}.frame.row\$highlightedrow configure -highlightthickness 0
								 \$tabArea tab \$feedback -state normal
								 grid \${description.rating}
								 \${description.rating} avgSet $temp(rating)
								 if {\[info exists packageRating($temp(package))\]} {
									\${description.rating} set \$packageRating($temp(package))
								 } else {
								 	\${description.rating} set 0
								 }
								 set highlightedrow $i
								 ${destination}.frame.row$i configure -highlightthickness 2
								 "
		bind ${destination}.frame.row$i <ButtonPress-1> $handler
		bind $name <ButtonPress-1> $handler
		bind $icon <ButtonPress-1> $handler
		bind $desc <ButtonPress-1> $handler
		bind $rating <ButtonPress-1> $handler

		grid $cb -column 0 -rowspan 2 -padx 5 -row $i
		grid $icon -column 1 -rowspan 2 -padx 5 -row $i
		grid $name -column 2 -padx 5 -pady 2 -sticky nwe -row $i
		grid $desc -column 2 -padx 5 -pady 2 -sticky nwe -row [expr {1+$i}]
		grid $price -column 3 -sticky e -row $i
		grid $rating -column 3 -sticky e -row [expr {$i+1}]

		grid columnconfigure ${destination}.frame.row$i 2 -weight 1

		incr i 2
	}

	# Update the scrollable thing after giving it time to figure out it's dimensions
	after 100 [list updateScrollableThing $destination]
}

proc lineTrim {words} {
	upvar $words temp
	set temp [string trim $temp]
	regsub {\s*\n\s*} $temp \n temp
}

proc getPackList {text category} {
	set command [list [findTVEbinary search] -v]
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
			[regexp {Description: ([^\n]+)(?:\n(.*))?} $pack mat temp(descText) temp(longDesc)]
			)
		} {
			# ERROR
			tk_messageBox -message "Package parse error: \n$rawOutput"
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

		if {![regexp {Rating: ([^\n]*)\n} $pack mat temp(rating)]} {
			#If not rating
			set temp(rating) 0
		}

		if {![regexp {UserOwns: ([^\n]*)\n} $pack mat temp(owns)]} {
			set temp(owns) ""
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
	global offlineMode

	if {$offlineMode && ![info exists originalValues($package)] && $selectedPackages($package)} {
		# We're in offline mode, and they're trying to check a box that they haven't already unchecked.
		# Stop them
		set selectedPackages($package) 0
		tk_messageBox -message "You can't select packages for install in offline mode\nSwitch to online mode to install packages"
		# Then get out of here
		return
	}

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

# This function clears the selection state, so that all "installed / removed" state is pulled from the database again.
proc clearState {} {
	global selectedPackages
	global originalValues

	array unset selectedPackages
	array unset originalValues
}

# This command will run the message box only if there's data in the list.
proc Report {message list title} {
	if {[string length [string trim $list]] != 0} {
		tk_messageBox -message "$message $list" -title $title
	}
}

# This calculates the cost of commpleting a given diff (As output by getDiff)
proc getCost {diff} {
	set apps [list]

	foreach p $diff {
		set pStatus [lindex $p 1]
		set pName [lindex $p 0]
		if {$pStatus == 1} {
			# This is to be installed
			lappend apps $pName
		}
	}
	if {[llength $apps] == 0} {
		return 0
	}

	return [exec sh -c "[findTVEscript calculateTotal] $apps"]
}

# This returns a list of all depended on packages
proc Depends {package} {
	set depends [findTVEbinary {depends}]
	if [catch {exec -ignorestderr sh -c "$depends $package"} dependencies] {
		tk_messageBox -title "Depends Failed!" -message "Dependencies Failed: $dependencies"
		exit -1
	}
	set retList [list]
	foreach {intExt name version} [split $dependencies] {
		if [string equal $intExt "I"] {
			lappend retList $name
		}
	}

	return $retList
}

# This is the command of the "Do It" button
proc DoIt {} {
	global selectedPackages
	global env

	set installFail ""
	set removeFail ""
	set installSucc ""
	set removeSucc ""

	set diffList [getDiff]

	set cost [getCost $diffList]
	if {$cost != 0} {
		set continueAnswer [tk_messageBox -title "Continue?" -message "The cost of installing the selected packages is $cost ¤.\nContinue?" -type yesno]
		if {$continueAnswer == no} {
			return
		}
	}

	if [info exists env(TVEOFFLINE)] {
		return
	}

	foreach p $diffList {
		set pStatus [lindex $p 1]
		set pName [lindex $p 0]

		if {$pStatus == 1} {
			# Check if all dependencies are purchased
			foreach {dName} [Depends $pName] {
				if [catch {exec sh -c "[findTVEbinary status] -o $dName"} val] {
					tk_messageBox -title "Status Broke" -message "Couldn't Call Status -o. Error: $val"
					append installFail " $pName"
					break
				}
				if {$val == 0} {
					# This needs purchasing
					if [catch {exec sh -c "[findTVEscript purchase] $dName"} val] {
						tk_messageBox -title "Purchase Broke" -message "Error With Purchase: $val"
						append installFail " $pName"
						break
					}
				}
			}
			# If this failed anywhere above, skip this
			if [string equal [lindex $installFail end] $pName] {
				tk_messageBox -title "?" -message "Failed Above"
				continue
			}
			# Purchase the actual package
			if [catch {exec sh -c "[findTVEscript purchase] $pName"} val] {
				tk_messageBox -title "Purchase Broke" -message "Error With Purchase: $val"
				append installFail " $pName"
				break
			}
			# Install this
			if [catch {exec -ignorestderr sh -c "[findTVEscript maybesudo ""] [findTVEscript install] $pName"} failWords] {
				append installFail " $pName"
				tk_messageBox -message $failWords -title "Install"
			} else {
				append installSucc " $pName"
			}
		} else {
			# Remove this
			if [catch {exec -ignorestderr sh -c "[findTVEscript maybesudo ""] [findTVEscript remove] $pName"} failWords] {
				append removeFail " $pName"
				tk_messageBox -message $failWords -title "Remove"
			} else {
				append removeSucc " $pName"
			}
		}
	}
	Report "The following packages failed to install:" $installFail "Installation Failed"
	Report "Installation succeeded on the following packages:" $installSucc "Installation Success"
	Report "The following packages failed to remove:" $removeFail "Removal Failed"
	Report "Removal succeeded on the following packages:" $removeSucc "Removal Success"

	# Clear the chosen statuses, the database should match those now.
	# This will make all statuses be pulled from the database, so when something fails to install it will be unchecked.
	clearState
	# Now update the list
	getDataAndFilter
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

proc clearUi {} {
	foreach widget [grid slave .] {
		grid forget $widget
	}
}

# This function is in charge of putting all the root widgets on the root window
proc drawUi {} {
	# Pull in all the root widgets
	global canvas
	global canvasScroll
	global viewarea
	global topBar
	global categoryArea
	global bottomBar

	# And put them on the screen

	# Grid the top bar
	grid $topBar - -sticky ew

	# Grid the canvas and scrollbar
	grid $canvas $canvasScroll
	grid $canvas -sticky news
	grid $canvasScroll -sticky ns

	# Grid the viewarea
	grid $viewarea -
	grid $viewarea -sticky news

	# Grid the bottom bar
	grid $bottomBar -sticky ew
}

proc handleLoginStart {channel} {
	global TOKEN
	global SECRET
	global URL
	global loginButton
	global offlineButton

	if [eof $channel] {
		set ERR ""
		if [catch {close $channel} errorOutput] {
			# There was output to stderr during the execution of the program.

			if [regexp "Go to \"(\[^\"\]+)\"" $errorOutput mat gUrl] {
				# We couldn't find a way to open the given url, give it to them manually.
				set URL $gUrl
			} else {
				# If there was error output other than that, assume the reader should be notified
				set ERR $errorOutput
			}
		}
		# At this point the channel's done.
		Report "Encountered Error:" $ERR "Error"
		# Regardless of the error output we recieved above, if we got tokens out of this, assume it succeeded.
		if {[string length [string trim $TOKEN]] != 0} {
			# We seem to have a token.
			clearUi
			drawLoginFinish
		} else {
			# Failed to get tokens
			tk_messageBox -message "Login Failure. No authentication tokens could be found."
			$loginButton configure -state normal
			$offlineButton configure -state normal
		}
	} else {
		# There's still data to be read
		set line [gets $channel]
		if {[regexp {(\w{15,25}) (\w+)} $line mat token secret]} {
			# Found the tokens
			set TOKEN $token
			set SECRET $secret
		}
	}
}

proc handleLoginFinish {channel} {
	global loginContinue

	if [eof $channel] {
		set result [catch {close $channel} errorOutput exitOptions]

		if {$result != 0 && [lindex [dict get $exitOptions -errorcode] 2] != 0} {
			# Exited with actual error
			if {[string length [string trim $errorOutput]] != 0} {
				tk_messageBox -message "Encountered Error: $errorOutput"
			} else {
				tk_messageBox -message "Encountered Unknown Error"
			}
			clearUi
			drawLoginStart
		} else {
			# Here, it worked
			clearUi
			drawLoggedInUi
		}
	} else {
		# I don't require any particular output, so just consume it
		gets $channel
	}
}

proc loginStart {} {
	global TOKEN
	global SECRET
	global URL
	global loginButton
	global offlineButton

	set TOKEN ""
	set SECRET ""
	set URL ""

	$loginButton configure -state disabled -text "Please wait..."
	$offlineButton configure -state disabled

	set command [open "| sh -c [findTVEscript login-start]" r]
	fileevent $command readable [list handleLoginStart $command]
}

proc loginFinish {} {
	global TOKEN
	global SECRET
	global loginContinue

	$loginContinue configure -state disabled -text "Please wait..."

	set command [open "| sh -c \"[findTVEscript login-finish] $TOKEN $SECRET\"" r]
	fileevent $command readable [list handleLoginFinish $command]
}

# This function draws the login elements
proc drawLoginStart {} {
	global loginLabel
	global loginLabel2
	global loginButton
	global offlineButton

	$loginButton configure -state normal -text "Click Here to Login"
	$offlineButton configure -state normal

	grid $loginLabel -sticky ew
	grid $loginButton
	grid $loginLabel2 -sticky ew
	grid $offlineButton
}

# This function draws the screen where we wait for authentication.
proc drawLoginFinish {} {
	global URL
	global loginWait
	global loginUrlWait
	global loginUrl
	global loginContinue

	$loginContinue configure -state normal -text "Continue"

	if {$URL == ""} {
		# Browser opened on its own
		grid $loginWait
	} else {
		# Need to give them the url
		grid $loginWait
		grid $loginUrl
	}

	grid $loginContinue
}

# Offline mode
proc offlineMode {} {
	clearUi
	drawOfflineUi
}

# Logout
proc logout {} {
	global offlineMode

	if $offlineMode {
		# If in offline mode, check to see if we're online, and if so be online, if not present login.
		clearUi
		drawProperScreen
	} else {
		if [catch {exec sh -c [findTVEscript logout]} errorMessage] {
			tk_messageBox -message "Encountered Error: $errorMessage" -title "Error"
		}
		clearUi
		drawLoginStart
	}
}

# This checks to see if you're logged in, and draws the appropriate window
proc drawProperScreen {} {
	global loginCheckCommand
	global loginCheckSkipped
	global preLoginLabel
	global preLoginSkip

	# Set the loginCheck to be not skipped
	set loginCheckSkipped 0

	# Draw the login-check UI
	# In a fast login-check they might not even see this
	grid $preLoginLabel -sticky ew
	grid $preLoginSkip

	set loginCheckCommand [open "| sh -c [findTVEscript login-check]" r]
	fileevent $loginCheckCommand readable [list handleLoginCheck $loginCheckCommand]
}

# This function handles the result of login-check
proc handleLoginCheck {channel} {
	global loginCheckSkipped
	# If this isn't the end of the output, just consume it
	if {![eof $channel]} {
		gets $channel
		return
	}

	# This is the end, close it and look for the result
	set result [catch {close $channel} errorMsg exitOptions]

	# Check if the user's still waiting for us
	if {$loginCheckSkipped == 1} {
		set loginCheckSkipped 0
		return
	}
	# Clear the UI, something's going to get drawn here
	clearUi
	if {$result != 0 && [lindex [dict get $exitOptions -errorcode] 2] != 0} {
		# Not Logged In
		drawLoginStart
	} else {
		# Logged In
		drawLoggedInUi
	}
}

# This draws the logged-in UI, taking care of all special considerations
proc drawLoggedInUi {} {
	global offlineMode
	global logoutButtonText
	global {description.rating}

	set offlineMode 0
	set logoutButtonText "Logout"
	# Make sure you can do ratings
	${description.rating} configure -readonly 0
	drawUi
}

# This draws the offline-mode UI
proc drawOfflineUi {} {
	global offlineMode
	global logoutButtonText
	global {description.rating}

	set offlineMode 1
	set logoutButtonText "Go Online"
	# Can't do ratings in offline mode
	${description.rating} configure -readonly 1
	drawUi
}

# This command intercepts the login check and just assumes offline mode
# This function is only really used when the connection is really slow or broken, and the user knows that
# This is here because sometimes login-check will take a while Trying to connect.
proc skipLoginCheck {} {
	global loginCheckCommand
	global loginCheckSkipped

	# Closing the command waits for it to finish. That's not what we want.
	# So, we just ignore it. 
	set loginCheckSkipped 1

	clearUi
	drawOfflineUi
}

# Login Stuff
# TODO: put logo here... put logo always in app?
set loginLabel    [ttk::label  .loginLabel    -text "Welcome to The Veeb Ecosystem"]
set loginButton   [ttk::button .loginButton   -text "Click Here to Login" -command loginStart]
set loginLabel2   [ttk::label  .loginLabel2   -text "(this will open your web browser, close it when you're done)"]
set offlineButton [ttk::button .offlineButton -text "Browse Offline" -command offlineMode]

set loginWait [ttk::label .loginWait -text "After Authenticating in your browser, click below to continue"]
set loginUrlWait [ttk::label .loginUrlWait -text "Go to the following URL on the internet to login. Then click below to continue"]
set loginUrl [ttk::entry .loginUrl -textvariable URL -state readonly]
set loginContinue [ttk::button .loginContinue -text "Continue" -command loginFinish]

# Pre-Login stuff
# This is to show that login is being checked, and gives the option to opt-out.
set preLoginLabel [ttk::label .preLoginLabel -text "Checking Login Status..."]
set preLoginSkip [ttk::button .preLoginSkip -text "Click this to just work offline." -command skipLoginCheck]

# Get the main scrollable canvas
set canvas [scrollableThing .can]
set canvasScroll [scrollbar .yscroll -orient vertical -command {$canvas yview}]
$canvas configure -yscrollcommand [list $canvasScroll set]

# Get scrollable view area
set viewarea [ttk::frame .viewarea]

# Make the top area.
set topBar [ttk::frame .topBar]

# Make the category box
set categoryArea [ttk::frame .categoryArea]

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
set searchBar [ttk::entry ${topBar}.bar -width 20 -textvariable searchQuery]
set searchButton [ttk::button ${topBar}.button -text "Search" -command getDataAndFilter]
bind $searchBar <Return> "$searchButton invoke"
grid $categoryCombo $searchBar $searchButton
grid $searchBar -sticky ew
grid $searchButton -sticky e
# Make the seach box expand when the window does
grid columnconfigure $topBar 1 -weight 1

# Make grid fill window
grid rowconfigure . 1 -weight 1
grid rowconfigure . 2 -weight 2
grid columnconfigure . 0 -weight 1

# And make rows fill canvas
grid columnconfigure ${canvas}.frame 0 -weight 1

# Add label to viewarea
set tabArea [ttk::notebook ${viewarea}.tabArea]

set description [ttk::frame ${tabArea}.description]
set description.topLine [ttk::frame ${description}.topLine]
set description.secondLine [ttk::frame ${description}.secondLine]
set description.title [ttk::label ${description.topLine}.title -textvariable currentPackage(title) -font TkHeadingFont -justify left]
set description.caption [ttk::label ${description.secondLine}.caption -textvariable currentPackage(caption) -justify left]
set description.longText [text ${description}.longText -wrap word]
set description.price [ttk::label ${description.topLine}.price -textvariable currentPackage(price) -justify right]
set description.rating [ratingWidget ${description.secondLine}.rating -pointRadius 12 -troughRadius 5]
bind ${description.rating} <<Rate>> {
	if [info exists packageRating($currentPackage(package))] {
		set currentValue $packageRating($currentPackage(package))
	} else {
		set currentValue 0
	}
	if {%d != $currentValue} {
		# Only report on changes
		puts "Rated package $currentPackage(package) a %d"
		set packageRating($currentPackage(package)) {%d}
	}
}

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
grid ${description.secondLine} -sticky ew

# Layout the second line
grid ${description.caption} ${description.rating}
grid ${description.caption} -sticky nw
grid ${description.rating} -sticky ne
# Make the rating widget take up as much space as it can (This keeps it right aligned)
grid columnconfigure ${description.secondLine} 1 -weight 1
# Now, hide the rating widget until something's clicked on
grid remove ${description.rating}

grid ${description.longText} ${description.scrollbar}

grid ${description.longText} -sticky news
grid ${description.scrollbar} -sticky ns

grid columnconfigure $description 0 -weight 1
grid rowconfigure $description 2 -weight 1

set reviews [ttk::frame ${tabArea}.review]

# Setup Feedback page
set feedback [ttk::frame ${tabArea}.feedback]
# Type box
set feedback.typeBox [ttk::frame ${feedback}.typeBox]
set feedback.typeLabel [ttk::label ${feedback.typeBox}.typeLabel -text "Type: "]
set feedback.type [ttk::combobox ${feedback.typeBox}.type -value [list "Report Bug" "Request Feature" "Other"]]
${feedback.type} set "Other"
grid ${feedback.typeLabel} ${feedback.type}

# Main Feedback form
set feedback.box [text ${feedback}.box]
set feedback.scroll [scrollbar ${feedback}.scroll -command [list ${feedback.box} yview]]
${feedback.box} configure -yscrollcommand [list ${feedback.scroll} set]
# And send button
set feedback.send [ttk::button ${feedback}.send -text "Send" -command [list sendFeedback ${feedback.box} ${feedback.type}]]
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
set bottomBar [ttk::frame .buttonBar]

set logoutButton [ttk::button ${bottomBar}.logout -textvariable logoutButtonText -command logout]
set quitButton [ttk::button ${bottomBar}.quit -text "Quit" -command safeQuit]
set commitButton [ttk::button ${bottomBar}.commit -text "Apply" -command DoIt]

grid $logoutButton $quitButton $commitButton

# Initialize Filter
set searchQuery ""
set filterCategory ""

set pkgs [getPackList "" ""]

drawPackageList $canvas $pkgs

if [info exists env(TVEOFFLINE)] {
	# This is offline mode, don't check for login
	drawLoggedInUi
} else {
	# This is normal mode
	drawProperScreen
}
