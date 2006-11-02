#* 
#* ------------------------------------------------------------------
#* PrintFunctions.tcl - Print Functions
#* Created by Robert Heller on Mon Sep 18 08:48:59 2006
#* ------------------------------------------------------------------
#* Modification History: $Log$
#* Modification History: Revision 1.1  2006/11/02 19:55:53  heller
#* Modification History: Initial revision
#* Modification History:
#* Modification History: Revision 1.1  2002/07/28 14:03:50  heller
#* Modification History: Add it copyright notice headers
#* Modification History:
#* ------------------------------------------------------------------
#* Contents:
#* ------------------------------------------------------------------
#*  
#*     Home Librarian V3.0
#*     Copyright (C) 2006  Robert Heller D/B/A Deepwoods Software
#* 			51 Locke Hill Road
#* 			Wendell, MA 01379-9728
#* 
#*     This program is free software; you can redistribute it and/or modify
#*     it under the terms of the GNU General Public License as published by
#*     the Free Software Foundation; either version 2 of the License, or
#*     (at your option) any later version.
#* 
#*     This program is distributed in the hope that it will be useful,
#*     but WITHOUT ANY WARRANTY; without even the implied warranty of
#*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#*     GNU General Public License for more details.
#* 
#*     You should have received a copy of the GNU General Public License
#*     along with this program; if not, write to the Free Software
#*     Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#* 
#*  
#* 

package require snit
package require BWidget
package require BWLabelComboBox
package require BWLabelSpinBox
package require BWFileEntry

namespace eval Print {
  snit::macro SelectPrintDialog_typecomponents {} {
    typecomponent dialog
    typecomponent   printerRB
    typecomponent   printerCB
    typecomponent   fileRB
    typecomponent   pfileFE
    typevariable  _FileOrPrinter printer
    typevariable  _PrinterPath
    typevariable  _PostscriptFiles {
	{{Postscript Files}	{.ps}	  }
	{{All Files}            *         }
    }
  }
  snit::macro SelectPrintDialog_typeconstructor {dpath body} {
    regsub -all {%dpath%} {
      set dialog [Dialog::create %dpath% \
			-class SelectPrinterDialog -side bottom \
			-bitmap questhead -modal local \
			-title "Select Printer" -default 0 -cancel 1]
      $dialog add -name ok -text OK -command [mytypemethod _OK]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command "BWHelp::HelpTopic SelectPrinterDialog"
      set frame [$dialog getframe]
      set printerRB [radiobutton $frame.printerRB \
				-command [mytypemethod _TogglePF] \
				-indicatoron yes \
				-value printer \
				-text "Print to printer" \
				-variable [mytypevar _FileOrPrinter]]
      pack $printerRB -fill x
      set printerCB [LabelComboBox $frame.printerCB -label "Printer:" \
						    -labelwidth 15 \
						    -editable no]
      pack $printerCB -fill x
      set fileRB [radiobutton $frame.fileRB \
				-command [mytypemethod _TogglePF] \
				-indicatoron yes \
				-value file \
				-text "Print to file" \
				-variable [mytypevar _FileOrPrinter]]
      pack $fileRB -fill x
      set pfileFE [FileEntry $frame.pfileFE -label "File:" -state disabled \
					    -labelwidth 15 \
					    -editable no \
					    -filedialog save \
					    -defaultextension .ps \
					    -filetypes $_PostscriptFiles \
					    -title "File to print to"]
      pack $pfileFE -fill x
      %body%
    } "$dpath" tconsbody
    regsub -all {%body%} "$tconsbody" "$body" tconsbody
    typeconstructor $tconsbody
  }
  snit::macro SelectPrintDialog_typemethods {drawbody} {
    typemethod _OK {} {
      switch $_FileOrPrinter {
	printer {
	  set _PrinterPath "|lpr -P[$printerCB cget -text]"
        }
	file {
	  set _PrinterPath "[$pfileFE cget -text]"
        }
      }
      $dialog withdraw
      return [$dialog enddialog ok]
    }
    typemethod _Cancel {} {
      set _PrinterPath {}
      $dialog withdraw
      return [$dialog enddialog cancel]
    }
    typemethod _TogglePF {} {
      switch $_FileOrPrinter {
        printer {
	  $printerCB configure -state normal
	  $pfileFE   configure -state disabled
        }
        file {
	  $pfileFE   configure -state normal
	  $printerCB configure -state disabled
        }
      }
    }
    regsub -all {%drawbody%} {
      $dialog configure -parent [from args -parent .]
      set printers {}
      set defprinter {}
      global tcl_platform
      switch "$tcl_platform(platform)" {
	unix {
	  if {![catch [list open "|lpstat -a" r] lpfp]} {
	    while {[gets $lpfp line] >= 0} {
	      if {[regexp {^([^[:space:]]*)[[:space:]]} "$line" -> printer] > 0} {
		lappend printers $printer
	      }
	    }
	    close $lpfp
	  }
	  if {![catch [list open "|lpstat -d" r] lpfp]} {
	    if {[gets $lpfp line] >= 0} {
	      regexp {destination:[[:space:]]*([^[:space:]]*)[[:space:]]*.*$} "$line" -> defprinter
	    }
	    close $lpfp
	  }
	}
	macintosh {
	}
	windows {
	}
      }
      $printerCB configure -values $printers
      if {[string equal "$defprinter" {}]} {
	$printerCB setvalue 0
      } else {
	$printerCB configure -text "$defprinter"
      }
      %drawbody%
      return [$dialog draw]
    } "$drawbody" selectbody
    typemethod _DrawSelectPrinterDialog {args} $selectbody
  }
  
  snit::widgetadaptor TextToPostscript {
    delegate option -background to hull
    option -foreground -default black \
		-configuremethod _ConfigureItem -cgetmethod _CgetItem
    option -font -default {} \
		-configuremethod _ConfigureItem -cgetmethod _CgetItem
    option -text -default {} \
		-configuremethod _ConfigureItem -cgetmethod _CgetItem
    option -width -default {} \
		-configuremethod _ConfigureItem -cgetmethod _CgetItem
    option -justify -default {} \
		-configuremethod _ConfigureItem -cgetmethod _CgetItem
    delegate option -xscrollcommand to hull
    delegate option -yscrollcommand to hull
    delegate method xview to hull
    delegate method yview to hull
    method _ConfigureItem {option value} {
      if {[string equal "$option" "-foreground"]} {set option -fill}
      set result [$hull itemconfigure theText $option "$value"]
      set bbox [$hull bbox theText]
      $hull configure -scrollregion $bbox
      return $result
    }
    method _CgetItem {option} {
      if {[string equal "$option" "-foreground"]} {set option -fill}
      return [$hull itemcget theText $option]
    }
    constructor {args} {
      installhull using canvas -relief flat -borderwidth 0
      $hull create text 0 0 -anchor nw -tag theText
      $self configurelist $args
    }
    method pstochan {channel args} {
      set bbox [$hull bbox theText]
      set x      [from args -x 0]
      set y      [from args -y 0]
      set width  [from args -width  [lindex $bbox 2]]
      set height [from args -height [lindex $bbox 3]]
      return [eval $hull postscript -channel $channel -x $x -y $y \
				    -width $width \
				    -height $height $args]
    }
    method getps {args} {
      set bbox [$hull bbox theText]
      set x      [from args -x 0]
      set y      [from args -y 0]
      set width  [from args -width  [lindex $bbox 2]]
      set height [from args -height [lindex $bbox 3]]
#      puts stderr "*** $self getps: x = $x, y = $y, width = $width, height = $height"
#      puts stderr "*** $self getps: args = $args"
      return [eval $hull postscript -x $x -y $y \
				    -width $width \
				    -height $height $args]
    }
    method itemwidth {} {
      set bbox [$hull bbox theText]
      return [expr {([lindex $bbox 2] - [lindex $bbox 0]) + 1}]
    }
    method itemheight {} {
      set bbox [$hull bbox theText]
      return [expr {([lindex $bbox 3] - [lindex $bbox 1]) + 1}]
    }
    method itemindex {index} {
      return [$hull index theText "$index"]
    }
  }
  snit::widgetadaptor CardToPostscript {
    delegate option -background to hull
    option -key -default {} -configuremethod _LayoutCard
    option -layout -default {} -configuremethod _LayoutCard
    variable cardrow
    method _LayoutCard {option value} {
      set options($option) "$value"
      $hull delete all
      catch {array unset cardrow}
      if {![Database::GetCardByKey $options(-key) cardrow]} {
	foreach i {Key Title Author Subject Description 
			     Location Category Media Publisher PubLocation 
			     PubDate Edition ISBN} {
	  set cardrow($i) {}
        }
      }
      $options(-layout) layout cardrow $hull 10 10
      return "$value"
    }
    delegate option -xscrollcommand to hull
    delegate option -yscrollcommand to hull
    delegate method xview to hull
    delegate method yview to hull
    constructor {args} {
      installhull using canvas -relief flat -borderwidth 0
      $self configurelist $args
    }
    method pstochan {channel args} {
      set bbox [$hull bbox all]
      set cheight [expr {[lindex $bbox 3] - [lindex $bbox 1] + 1}]
      set cwidth  [expr {[lindex $bbox 2] - [lindex $bbox 0] + 1}]
      return [eval $hull postscript -channel $channel \
			-pageheight [$options(-layout) cget -height] \
			-pagewidth [$options(-layout) cget -width] \
			-pagex 0 -pagey 0 \
			-height $cheight -width $cwidth \
			-x [lindex $bbox 0] \
			-y [lindex $bbox 1] -pageanchor nw $args]
    }
    method height {} {
      set bbox [$hull bbox all]
      return [expr {[lindex $bbox 3] - [lindex $bbox 1] + 1}]
    }
    method width {} {
      set bbox [$hull bbox all]
      return [expr {[lindex $bbox 2] - [lindex $bbox 0] + 1}]
    }
    method getps {args} {
      set bbox [$hull bbox all]
      set cheight [expr {[lindex $bbox 3] - [lindex $bbox 1] + 1}]
      set cwidth  [expr {[lindex $bbox 2] - [lindex $bbox 0] + 1}]
      return [eval $hull postscript  \
			-pageheight [$options(-layout) cget -height] \
			-pagewidth [$options(-layout) cget -width] \
			-pagex 0 -pagey 0 \
			-height $cheight -width $cwidth \
			-x [lindex $bbox 0] \
			-y [lindex $bbox 1] -pageanchor nw $args]
    }
  }
  snit::type CardLayout {
    typevariable AvailableLayouts -array {}
    typemethod listOfLayouts {} {
      return [lsort -dictionary [array names AvailableLayouts]]
    }
    typemethod getLayoutByName {name} {
      if {[lsearch [array names AvailableLayouts] "$name"] < 0} {
        return {}
      } else {
        return $AvailableLayouts($name)
      }
    }
    typecomponent dialog
    typecomponent   layoutListSW
    typecomponent     layoutListBox
    typecomponent   layoutFileB
    typecomponent   selectedLayoutLE

    typeconstructor {
      set dialog [Dialog::create .selectALayoutDialog \
			-class SelectALayoutDialog -side bottom \
			-bitmap questhead -modal local \
			-title "Select A Layout" \
			-default 0 -cancel 1]
      $dialog add -name ok -text OK -command [mytypemethod _OK]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command "BWHelp::HelpTopic SelectALayoutDialog"
      set frame [$dialog getframe]
      set layoutListSW [ScrolledWindow::create $frame.layoutListSW \
				-auto both -scrollbar both]
      pack $layoutListSW -expand yes -fill both
      set layoutListBox [ListBox::create $layoutListSW.lb \
					-selectmode single -selectfill yes]
      pack $layoutListBox -expand yes -fill both
      $layoutListSW setwidget $layoutListBox
      $layoutListBox bindText <1> [mytypemethod _SelectLayoutFromLB]
      $layoutListBox bindText <Double-1> [mytypemethod _ReturnLayoutFromLB]
      set layoutFileB [Button::create $frame.layoutFE -text "Load from file" \
				-command [mytypemethod _LoadLayoutFile]]
      pack $layoutFileB -fill x
      set selectedLayoutLE [LabelEntry::create $frame.selectedLayoutLE \
				-label "Selected Layout:"]
      pack $selectedLayoutLE -fill x
      $selectedLayoutLE bind <Return> [mytypemethod _OK]

    }
    typevariable _LayoutFiles {
	{{Layout Files} {.lay} TEXT}
	{{All Files}    *          }
    }
    typemethod layoutfiletypes {} {return $_LayoutFiles}
    typemethod _LoadLayoutFile {} {
      set filename [tk_getOpenFile -defaultextension ".lay" \
				   -title "File to load layout from" \
				   -filetypes $_LayoutFiles \
				   -parent $dialog]
      raise $dialog
      if {[string equal "$filename" {}]} {return}
      set layoutname [$type loadFromFile "$filename"]
      if {[string equal "$layoutname" {}]} {return {}}
      $layoutListBox delete [$layoutListBox items]
      foreach tp [$type listOfLayouts] {
	$layoutListBox insert end $tp -text "$tp" -data "$tp"
      }
    }
    typevariable _Result {}
    typemethod _OK {} {
      set _Result "[$selectedLayoutLE cget -text]"
      $dialog withdraw
      return [$dialog enddialog ok]
    }
    typemethod _Cancel {} {
      $dialog withdraw
      return [$dialog enddialog cancel]
    }
    typemethod _SelectLayoutFromLB {selected} {
      $layoutListBox selection set $selected
      $selectedLayoutLE configure -text "[$layoutListBox itemcget $selected -data]"
    }
    typemethod _ReturnLayoutFromLB {selected} {
      $layoutListBox selection set $selected
      $selectedLayoutLE configure -text "[$layoutListBox itemcget $selected -data]"
      $type _OK
    }
    typemethod    selectALayoutDialog {args} {
      $layoutListBox delete [$layoutListBox items]
      foreach tp [$type listOfLayouts] {
	$layoutListBox insert end $tp -text "$tp" -data "$tp"
      }
      $selectedLayoutLE configure -text {}
      set newP [from args -new]
      $selectedLayoutLE configure -editable $newP
      $dialog configure -parent [from args -parent .]
      set button [$dialog draw]
      if {[string equal "$button" ok]} {
	return "$_Result"
      } else {
	return {}
      }
    }
    variable layoutElements
    variable layoutName
    variable dirtyFlag
    option -filename -readonly yes -default {}
    option -width  -default 5i -configuremethod _CheckSize
    option -height -default 3i -configuremethod _CheckSize
    method _CheckSize {option value} {
      if {[string is double -strict  "$value"] && $value > 0} {
	set options($option) $value
	return $value
      } else {
	if {[regexp {^(.*)[mipc]$} "$value" -> number] < 1} {
	  error "Expected a coordinate for $option, got $value"
	}
	if {[string is double -strict  "$number"] && $number > 0} {
	  set options($option) $value
	  return $value
	}
	error "Expected a coordinate for $option, got $value"
      }
    }
    constructor {args} {
      $self configurelist $args
      set layoutName [namespace tail $self]
      set AvailableLayouts($layoutName) $self
      array set layoutElements {}
      set dirtyFlag yes
    }
    method clearlayout {} {
      catch {array unset layoutElements}
      set dirtyFlag yes
    }
    method elementexists {name} {
      if {[catch "set layoutElements($name)" ele]} {
	return no
      } else {
	return yes
      }
    }
    method addelement {name layouttype args} {
      if {[$self elementexists "$name"]} {
	error "Element already exists!"
      }
#      puts stderr "*** $self addelement: name = $name, layouttype = $layouttype, args = $args"
      set layoutElements($name) [concat $layouttype $args]
#      puts stderr "*** $self addelement: layoutElements($name) = $layoutElements($name)"
      set dirtyFlag yes
    }
    method removeelement {name} {
      catch {unset layoutElements($name)}
    }
    method elementcget {name option} {
      if {[catch "set layoutElements($name)" ele]} {return {}}
      set i [lsearch -exact $ele $option]
      if {$i > 0} {
	set dirtyFlag yes
	return [lindex $ele [expr {$i + 1}]]} else {return {}
      }
    }
    method elementtype {name} {
      if {[catch "set layoutElements($name)" ele]} {return {}}
      return [lindex $ele 0]
    }
    method elementconfigure {name option value} {
      if {[catch "set layoutElements($name)" ele]} {return {}}
      set i [lsearch -exact $ele $option]
      if {$i > 0} {
	set j [expr {$i + 1}]
	set layoutElements($name) [lreplace $ele $j $j "$value"]
	set dirtyFlag yes
	return [lindex $ele $j]
      } else {
	lappend layoutElements($name) $option "$value"
	set dirtyFlag yes
	return "$value"
      }
    }
    method elementcoords {name} {
      if {[catch "set layoutElements($name)" ele]} {return {}}
      set coords {}
      foreach c [lrange $ele 1 end] {
	if {[string is double $c]} {
	  lappend coords $c
	} else {
	  break
	}
      }
      return $coords
    }
    method setelementcoords {name coords} {
      if {[catch "set layoutElements($name)" ele]} {return {}}
      set i1 1
      set i2 2
      set i2m [llength $ele]
      for {set i2 2} {$i2 <= $i2m} {incr i2} {
	if {![string is double [lindex $ele $i2]]} {
	  incr i2 -1
	  break
	}
      }
      if {$i2 == $i2m} {incr $i2 -1}
      set ele [eval [list lreplace $ele $i1 $i2] $coords]
      set layoutElements($name) $ele
      set dirtyFlag yes
    }
    method edit {args} {
      Print::EditCardLayout draw -layoutname $layoutName -new $dirtyFlag
    }
    typemethod _GetBuffer {chan} {
      set buffer "[gets $chan]"
      while {![info complete "$buffer"] && ![eof $chan]} {
	append buffer "\n[gets $chan]"
      }
      return "$buffer"
    }
    typemethod loadFromFile {filename} {
      if {[catch [list open "$filename" r] channel]} {
        error "Could not open file: $filename: $channel"
        return {}
      }
      set buffer "[$type _GetBuffer $channel]"
      if {![string equal "$buffer" {Card Layout File}]} {
	error "Not a layout file!"
	return {}
      }
      set buffer "[$type _GetBuffer $channel]"
      foreach {n v} [lrange $buffer 0 1] {
	if {![string equal "$n" :name]} {
	  error "Not a layout file!"
	  return {}
	} else {
          regsub -all {[[:space:]]} "$v" {_} layoutname
	  set oldtemp [$type getLayoutByName $layoutname]
	  if {![string equal "$oldtemp" {}]} {
	    set ans [tk_messageBox 
			-type yesno -icon question \
			-message "Layout $layoutname already exists! Replace it?"]
	    if {!$ans} {return}
	    $oldtemp destroy
	  }
	}
      }
      set layout [eval $type create $layoutname -filename "$filename" [lrange $buffer 2 end]]
      while {![eof $channel]} {
	foreach {n v} [$type _GetBuffer $channel] {
	  eval $layout addelement $n $v
	}
      }
      close $channel
      set df [$layout info vars dirtyFlag]
      set $df no
      return $layoutname
    }
    method saveToFile {{filename {}}} {
      if {[string equal "$filename" {}]} {set filename "$options(-filename)"}
      if {[string equal "$filename" {}]} {
	set filename [tk_getSaveFile -defaultextension .lay \
				     -title "File to save layout in" \
				     -filetypes $_LayoutFiles]
	if {[string equal "$filename" {}]} {return no}
      }
      if {[catch [list open "$filename" w] channel]} {
	error "Could not open $filename: $channel"
	return no
      }
      set $options(-filename) "$filename"
      puts $channel {Card Layout File}
      puts $channel [list :name "$layoutName" -width "$options(-width)" \
					      -height "$options(-height)"]
      foreach n [lsort -dictionary [array names layoutElements]] {
	puts $channel [list $n $layoutElements($n)]
      }
      close $channel
      set dirtyFlag no
      return yes
    }
    method layout {dataname canvas xoff yoff} {
      upvar $dataname data
      $canvas delete all
      $canvas create rect 0 0 $options(-width) $options(-height) \
		-fill white -outline grey10 -dash . -tag {__background__}
      foreach elementname [array names layoutElements] {
        set element $layoutElements($elementname)
	if {[string equal [lindex $element 0] text]} {
	  set x [lindex $element 1]
	  set y [lindex $element 2]
	  set optionlist [lrange $element 3 end]
	  set text [from optionlist -text {}]
	  regsub -all "\r\n" "$data(Description)" "\n" data(Description)
	  regsub -all {[&\\]} "$data(Key)" {\\&} data(Key)
	  regsub -all {[&\\]} "$data(Title)" {\\&} data(Title)
	  regsub -all {[&\\]} "$data(Author)" {\\&} data(Author)
	  regsub -all {[&\\]} "$data(Subject)" {\\&} data(Subject)
	  regsub -all {[&\\]} "$data(Description)" {\\&} data(Description)
	  regsub -all {[&\\]} "$data(Location)" {\\&} data(Location)
	  regsub -all {[&\\]} "$data(Category)" {\\&} data(Category)
	  regsub -all {[&\\]} "$data(Media)" {\\&} data(Media)
	  regsub -all {[&\\]} "$data(Publisher)" {\\&} data(Publisher)
	  regsub -all {[&\\]} "$data(PubLocation)" {\\&} data(PubLocation)
	  regsub -all {[&\\]} "$data(PubDate)" {\\&} data(PubDate)
	  regsub -all {[&\\]} "$data(Edition)" {\\&} data(Edition)
	  regsub -all {[&\\]} "$data(ISBN)" {\\&} data(ISBN)
	  regsub -all {%KEY%}         "$text" "$data(Key)" text
	  regsub -all {%TITLE%}       "$text" "$data(Title)" text
	  regsub -all {%AUTHOR%}      "$text" "$data(Author)" text
	  regsub -all {%SUBJECT%}     "$text" "$data(Subject)" text
	  regsub -all {%DESCRIPTION%} "$text" "$data(Description)" text
	  regsub -all {%LOCATION%}    "$text" "$data(Location)" text
	  regsub -all {%CATEGORY%}    "$text" "$data(Category)" text
	  regsub -all {%MEDIA%}       "$text" "$data(Media)" text
	  regsub -all {%PUBLISHER%}   "$text" "$data(Publisher)" text
	  regsub -all {%PUBLOCATION%} "$text" "$data(PubLocation)" text
	  regsub -all {%PUBDATE%}     "$text" "$data(PubDate)" text
	  regsub -all {%EDITION%}     "$text" "$data(Edition)" text
	  regsub -all {%ISBN%}        "$text" "$data(ISBN)" text
	  set element [concat text $x $y $optionlist]
	  lappend element -text "$text"
	}
#	puts stderr "*** $self layout: element = \{$element\}"
        eval $canvas create $element
      }
      $canvas move all $xoff $yoff
      set bbox [$canvas bbox all]
      $canvas configure -scrollregion [list [expr {[lindex $bbox 0] - $xoff}] \
					    [expr {[lindex $bbox 1] - $yoff}] \
					    [expr {[lindex $bbox 2] + $xoff}] \
					    [expr {[lindex $bbox 3] + $yoff}]]
    }
    method layoutnodata {canvas xoff yoff} {
      $canvas delete all
      $canvas create rect 0 0 $options(-width) $options(-height) \
		-fill white -outline grey10 -dash . -tag {__background__}
      foreach elementname [array names layoutElements] {
#	puts stderr "*** $self layoutnodata: elementname = $elementname"
        set element $layoutElements($elementname)
#	puts stderr "*** $self layoutnodata: element = $element"
        eval $canvas create $element
      }
      $canvas move all $xoff $yoff
      set bbox [$canvas bbox all]
      $canvas configure -scrollregion [list [expr {[lindex $bbox 0] - $xoff}] \
					    [expr {[lindex $bbox 1] - $yoff}] \
					    [expr {[lindex $bbox 2] + $xoff}] \
					    [expr {[lindex $bbox 3] + $yoff}]]
    }
  }
  snit::widgetadaptor EditCardLayout {
    typevariable _EditorsByName -array {}

    typecomponent textToolDialog
    typecomponent   textnameLE
    typecomponent   fontselectCB
    typecomponent   fontsizeselectSB
    typecomponent   fontweightselectCB
    typecomponent   fontslantselectCB
    typecomponent   textcolorLF
    typecomponent     textcolorE
    typecomponent     textcolorB
    typecomponent   textcoordFrame
    typecomponent     textXSB
    typecomponent     textYSB
    typecomponent     textWSB
    typecomponent   textLF
    typecomponent     textSW
    typecomponent       textTX

    typecomponent lineToolDialog
    typecomponent   linenameLE
    typecomponent   linecolorLF
    typecomponent     linecolorE
    typecomponent     linecolorB
    typecomponent   linecoordLF
    typecomponent     lineXYSW
    typecomponent       lineXYLB
    typecomponent     newlinecoordFrame
    typecomponent       lineXSB
    typecomponent       lineYSB
    typecomponent       lineUpdateXYB
    typecomponent       lineDeleteXYB
    typecomponent       lineAddXYB
    typecomponent   linethickSB
    typecomponent   linedashCB

    typecomponent rectDiskToolDialog
    typecomponent rectDisknameLE
    typecomponent rectDiskfillcolorLF
    typecomponent   rectDiskfillcolorE
    typecomponent   rectDiskfillcolorB
    typecomponent rectDiskoutlinecolorLF
    typecomponent   rectDiskoutlinecolorE
    typecomponent   rectDiskoutlinecolorB
    typecomponent rectDiskcoordFrame
    typecomponent   rectDiskX1SB
    typecomponent   rectDiskY1SB
    typecomponent   rectDiskX2SB
    typecomponent   rectDiskY2SB

    typecomponent bitmapToolDialog
    typecomponent bitmapnameLE
    typecomponent bitmapforecolorLF
    typecomponent   bitmapforecolorE
    typecomponent   bitmapforecolorB
    typecomponent bitmapbackcolorLF
    typecomponent   bitmapbackcolorE
    typecomponent   bitmapbackcolorB
    typecomponent bitmapcoordFrame
    typecomponent   bitmapXSB
    typecomponent   bitmapYSB
    typecomponent bitmapBitmapLF
    typecomponent   bitmapBitmapCB
    typecomponent   bitmapBitmapFB

    typecomponent resizeToolDialog
    typecomponent resizeWidthLE
    typecomponent resizeHeightLE

    typeconstructor {
      set textToolDialog [Dialog::create .editLayoutTextToolDialog \
				-class EditLayoutTextToolDialog \
				-side bottom -bitmap questhead -modal local \
				-title "Text tool" -default 0 -cancel 1]
      $textToolDialog add -name ok -text OK -command [mytypemethod _TextToolOK]
      $textToolDialog add -name cancel -text Cancel -command [mytypemethod _TextToolCancel]
      $textToolDialog add -name help -text Help -command "BWHelp::HelpTopic EditLayoutTextToolDialog"
      set frame [$textToolDialog getframe]
      set textnameLE   [LabelEntry::create $frame.textnameLE \
			-label Name: -labelwidth 10 -editable yes]
      pack $textnameLE -fill x
      set fontselectCB [LabelComboBox::create $frame.fontselectCB \
			-label Font: -labelwidth 10 \
			-values [font families -displayof $textToolDialog] \
			-editable no -text times]
      pack $fontselectCB -fill x
      set fontsizeselectSB [LabelSpinBox::create $frame.fontsizeselectSB \
			-label Size: -labelwidth 10 \
			-range {1 100 1} -editable yes -text 12]
      pack $fontsizeselectSB -fill x
      set fontweightselectCB [LabelComboBox::create $frame.fontweightselectCB \
			-label Weight: -labelwidth 10 \
			-values [list normal bold] \
			-editable no -text normal]
      pack $fontweightselectCB -fill x
      set fontslantselectCB [LabelComboBox::create $frame.fontslantselectCB \
			-label Slant: -labelwidth 10 \
			-values [list roman italic] \
			-editable no -text roman]
      pack $fontslantselectCB -fill x
      set textcolorLF [LabelFrame::create $frame.textcolorLF \
			-text Color: -width 10]
      pack $textcolorLF -fill x
      set f [$textcolorLF getframe]
      set textcolorE [Entry::create $f.textcolorE -text black]
      pack $textcolorE -side left -expand yes -fill x
      set textcolorB [Button::create $f.textcolorB -text Browse \
			-command [mytypemethod _TextToolBrowseColor]]
      pack $textcolorB -side right
      set textcoordFrame [frame $frame.textcoordFrame -borderwidth 0]
      pack $textcoordFrame -expand yes -fill x
      set textXSB [LabelSpinBox::create $textcoordFrame.textXSB \
			-label {X Pos:} -labelwidth 10 -range {0 999999 1} \
			-editable yes -text 0.0]
#      puts stderr "*** $type typeconstructor: textXSB = $textXSB"
      pack $textXSB -side left -expand yes -fill x
      set textYSB [LabelSpinBox::create $textcoordFrame.textYSB \
			-label {Y Pos:} -labelwidth 10 -range {0 999999 1} \
			-editable yes -text 0.0]
      pack $textYSB -side left -expand yes -fill x
      set textWSB [LabelSpinBox::create $textcoordFrame.textWSB \
			-label {Width:} -labelwidth 10 -range {1 999999 1} \
			-editable yes -text 1.0]
      pack $textWSB -side left -expand yes -fill x
      set textLF [LabelFrame::create $frame.textLF -text Text: -width 10 \
			-side top]
      pack $textLF -expand yes -fill both
      set f [$textLF getframe]
      set textSW [ScrolledWindow::create $f.textSW \
				-scrollbar vertical -auto vertical]
      pack $textSW -expand yes -fill both
      set textTX [text $textSW.textTX -wrap word]
      pack $textTX -expand yes -fill both
      $textSW setwidget $textTX

      set lineToolDialog [Dialog::create .editLayoutLineToolDialog \
				-class EditLayoutLineToolDialog \
				-side bottom -bitmap questhead -modal local \
				-title "Line tool" -default 0 -cancel 1]
      $lineToolDialog add -name ok -text OK -command [mytypemethod _LineToolOK]
      $lineToolDialog add -name cancel -text Cancel -command [mytypemethod _LineToolCancel]
      $lineToolDialog add -name help -text Help -command "BWHelp::HelpTopic EditLayoutLineToolDialog"
      set frame [$lineToolDialog getframe]
      set linenameLE   [LabelEntry::create $frame.linenameLE \
			-label Name: -labelwidth 10 -editable yes]
      pack $linenameLE -fill x
      set linecolorLF [LabelFrame::create $frame.linecolorLF \
			-text Color: -width 10]
      pack $linecolorLF -fill x
      set f [$linecolorLF getframe]
      set linecolorE [Entry::create $f.linecolorE -text black]
      pack $linecolorE -side left -expand yes -fill x
      set linecolorB [Button::create $f.linecolorB -text Browse \
			-command [mytypemethod _LineToolBrowseColor]]
      pack $linecolorB -side right
      set linecoordLF [LabelFrame::create $frame.linecoordLF \
			-text Coordinates: -side top]
      pack $linecoordLF -fill x
      set f [$linecoordLF getframe]
      set lineXYSW [ScrolledWindow::create $f.lineXYSW \
				-scrollbar vertical -auto vertical]
      pack $lineXYSW -expand yes -fill both
      set lineXYLB [ListBox::create $lineXYSW.lineXYLB -selectmode single \
							-selectfill yes]
      pack $lineXYLB -expand yes -fill both
      $lineXYSW setwidget $lineXYLB
      set newlinecoordFrame [frame $f.newlinecoordFrame]
      pack $newlinecoordFrame -fill x
      set lineXSB [LabelSpinBox::create $newlinecoordFrame.lineXSB \
			-label X: -range {0 99999 1} -editable yes]
      pack $lineXSB -side left -fill x
      set lineYSB [LabelSpinBox::create $newlinecoordFrame.lineYSB \
			-label Y: -range {0 99999 1} -editable yes]
      pack $lineYSB -side left -fill x
      set lineUpdateXYB [Button::create $newlinecoordFrame.lineUpdateXYB \
			-text Update -command [mytypemethod _LineToolUpdateXY]]
      pack $lineUpdateXYB -side left
      set lineDeleteXYB [Button::create $newlinecoordFrame.lineDeleteXYB \
			-text Delete -command [mytypemethod _LineToolDeleteXY]]
      pack $lineDeleteXYB -side left
      set lineAddXYB [Button::create $newlinecoordFrame.lineAddXYB \
			-text Update -command [mytypemethod _LineToolAddXY]]
      pack $lineAddXYB -side right
      set linethickSB [LabelSpinBox::create $frame.linethickSB \
			-label Thickness: -labelwidth 10 -text 1 \
			-range {1 999 1}]
      pack $linethickSB -fill x
      set linedashCB [LabelComboBox::create $frame.linedashCB \
			-label Dash: -labelwidth 10 -text {} \
			-values [list {} . - -. -.. {. } ,] \
			-editable yes]
      pack $linedashCB -fill x

      set rectDiskToolDialog [Dialog::create .editLayoutRectDiskToolDialog \
				-class EditLayoutRectDiskToolDialog \
				-side bottom -bitmap questhead -modal local \
				-title "Rect / Disk tool" -default 0 -cancel 1]
      $rectDiskToolDialog add -name ok -text OK -command [mytypemethod _RectDiskToolOK]
      $rectDiskToolDialog add -name cancel -text Cancel -command [mytypemethod _RectDiskToolCancel]
      $rectDiskToolDialog add -name help -text Help -command "BWHelp::HelpTopic EditLayoutRectDiskToolDialog"
      set frame [$rectDiskToolDialog getframe]
      set rectDisknameLE   [LabelEntry::create $frame.rectDisknameLE \
			-label Name: -labelwidth 15 -editable yes]
      pack $rectDisknameLE -fill x
      set rectDiskfillcolorLF [LabelFrame::create $frame.rectDiskfillcolorLF \
			-text "Fill Color:" -width 15]
      pack $rectDiskfillcolorLF -fill x
      set f [$rectDiskfillcolorLF getframe]
      set rectDiskfillcolorE [Entry::create $f.rectDiskfillcolorE -text white]
      pack $rectDiskfillcolorE -side left -expand yes -fill x
      set rectDiskfillcolorB [Button::create $f.rectDiskfillcolorB -text Browse \
			-command [mytypemethod _RectDiskToolBrowseFillColor]]
      pack $rectDiskfillcolorB -side right
      set rectDiskoutlinecolorLF [LabelFrame::create $frame.rectDiskoutlinecolorLF \
			-text "Outline Color:" -width 15]
      pack $rectDiskoutlinecolorLF -fill x
      set f [$rectDiskoutlinecolorLF getframe]
      set rectDiskoutlinecolorE [Entry::create $f.rectDiskoutlinecolorE -text black]
      pack $rectDiskoutlinecolorE -side left -expand yes -fill x
      set rectDiskoutlinecolorB [Button::create $f.rectDiskoutlinecolorB -text Browse \
			-command [mytypemethod _RectDiskToolBrowseOutlineColor]]
      pack $rectDiskoutlinecolorB -side right
      set rectDiskcoordFrame [frame $frame.rectDiskcoordFrame -borderwidth 0]
      pack $rectDiskcoordFrame -expand yes -fill x
      set rectDiskX1SB [LabelSpinBox::create $rectDiskcoordFrame.rectDiskX1SB \
			-label {X1 Pos:} -labelwidth 15 -range {0 999999 1} \
			-editable yes -text 0.0]
#      puts stderr "*** $type typeconstructor: rectDiskX1SB = $rectDiskX1SB"
      grid $rectDiskX1SB -column 0 -row 0 -sticky ew
      set rectDiskY1SB [LabelSpinBox::create $rectDiskcoordFrame.rectDiskY1SB \
			-label {Y1 Pos:} -labelwidth 15 -range {0 999999 1} \
			-editable yes -text 0.0]
      grid $rectDiskY1SB -column 1 -row 0 -sticky ew
      set rectDiskX2SB [LabelSpinBox::create $rectDiskcoordFrame.rectDiskX2SB \
			-label {X2 Pos:} -labelwidth 15 -range {0 999999 1} \
			-editable yes -text 0.0]
#      puts stderr "*** $type typeconstructor: rectDiskX2SB = $rectDiskX2SB"
      grid $rectDiskX2SB -column 0 -row 1 -sticky ew
      set rectDiskY2SB [LabelSpinBox::create $rectDiskcoordFrame.rectDiskY2SB \
			-label {Y2 Pos:} -labelwidth 15 -range {0 999999 1} \
			-editable yes -text 0.0]
      grid $rectDiskY2SB -column 1 -row 1 -sticky ew

      set bitmapToolDialog [Dialog::create .editLayoutBitmapToolDialog \
				-class EditLayoutBitmapToolDialog \
				-side bottom -bitmap questhead -modal local \
				-title "Bitmap tool" -default 0 -cancel 1]
      $bitmapToolDialog add -name ok -text OK -command [mytypemethod _BitmapToolOK]
      $bitmapToolDialog add -name cancel -text Cancel -command [mytypemethod _BitmapToolCancel]
      $bitmapToolDialog add -name help -text Help -command "BWHelp::HelpTopic EditLayoutBitmapToolDialog"
      set frame [$bitmapToolDialog getframe]
      set bitmapnameLE   [LabelEntry::create $frame.bitmapnameLE \
			-label Name: -labelwidth 20 -editable yes]
      pack $bitmapnameLE -fill x
      set bitmapforecolorLF [LabelFrame::create $frame.bitmapforecolorLF \
			-text "Foreground Color:" -width 20]
      pack $bitmapforecolorLF -fill x
      set f [$bitmapforecolorLF getframe]
      set bitmapforecolorE [Entry::create $f.bitmapforecolorE -text white]
      pack $bitmapforecolorE -side left -expand yes -fill x
      set bitmapforecolorB [Button::create $f.bitmapforecolorB -text Browse \
			-command [mytypemethod _BitmapToolBrowseForeColor]]
      pack $bitmapforecolorB -side right
      set bitmapbackcolorLF [LabelFrame::create $frame.bitmapbackcolorLF \
			-text "Background Color:" -width 20]
      pack $bitmapbackcolorLF -fill x
      set f [$bitmapbackcolorLF getframe]
      set bitmapbackcolorE [Entry::create $f.bitmapbackcolorE -text black]
      pack $bitmapbackcolorE -side left -expand yes -fill x
      set bitmapbackcolorB [Button::create $f.bitmapbackcolorB -text Browse \
			-command [mytypemethod _BitmapToolBrowseBackColor]]
      pack $bitmapbackcolorB -side right
      set bitmapcoordFrame [frame $frame.bitmapcoordFrame -borderwidth 0]
      pack $bitmapcoordFrame -expand yes -fill x
      set bitmapXSB [LabelSpinBox::create $bitmapcoordFrame.bitmapXSB \
			-label {X Pos:} -labelwidth 20  -range {0 999999 1} \
                        -editable yes -text 0.0]
      pack $bitmapXSB -side left -fill x
      set bitmapYSB [LabelSpinBox::create $bitmapcoordFrame.bitmapYSB \
			-label {Y Pos:} -labelwidth 20  -range {0 999999 1} \
                        -editable yes -text 0.0]
      pack $bitmapYSB -side left -fill x
      set bitmapBitmapLF [LabelFrame::create $frame.bitmapBitmapLF \
				-text Bitmap: -width 20]
      pack $bitmapBitmapLF -fill x -expand yes
      set f [$bitmapBitmapLF getframe]
      set bitmapBitmapCB [ComboBox::create $f.bitmapBitmapCB \
			-values {error gray75 gray50 gray25 gray12 hourglass
				 info questhead question warning} \
			-text {error} -editable yes]
      pack $bitmapBitmapCB -side left -fill x -expand yes
      set bitmapBitmapFB [Button::create $f.bitmapBitmapFB -text {Browse XBMs} \
				-command [mytypemethod _BitmapToolBMFile]]
      pack $bitmapBitmapFB -side right
      
      set resizeToolDialog [Dialog::create .editLayoutResizeToolDialog \
				-class EditLayoutResizeToolDialog \
				-side bottom -bitmap questhead -modal local \
				-title "Resize tool" -default 0 -cancel 1]
      $resizeToolDialog add -name ok -text OK -command [mytypemethod _ResizeToolOK]
      $resizeToolDialog add -name cancel -text Cancel -command [mytypemethod _ResizeToolCancel]
      $resizeToolDialog add -name help -text Help -command "BWHelp::HelpTopic EditLayoutResizeToolDialog"
      set frame [$resizeToolDialog getframe]
      set resizeWidthLE [LabelEntry::create $frame.resizeWidthSB \
			-label Width: -labelwidth 7 -text 5i]
      pack $resizeWidthLE -fill x
      set resizeHeightLE [LabelEntry::create $frame.resizeHeightSB \
			-label Height: -labelwidth 7 -text 3i]
      pack $resizeHeightLE -fill x
    }

    option -layoutname -readonly yes -default {}
    delegate option -height to hull
    delegate option -width to hull
    option -transientparent -readonly yes -default {}
    delegate option -menu to hull
    component editBB
    component layoutCanvasSW
    component   layoutCanvas
    component     itemMenu
    variable  dirtylabel
    variable  selection
    variable  current
    variable  _lockstate 0
    variable _x1
    variable _y1
    variable _x2
    variable _y2
    variable _pointList
    constructor {args} {
      set options(-layoutname) [from args -layoutname]
      set options(-transientparent) [from args -transientparent]
      installhull using Windows::HomeLibrarianTopLevel \
		-transientparent $options(-transientparent) \
		-windowmenu {} \
		-separator none
      set frame [$hull getframe]
      $self configurelist $args
      set dirtylabel [$hull mainframe addindicator -bitmap gray50]
      $dirtylabel configure -foreground [$dirtylabel cget -background]
      $dirtylabel configure -relief flat
      $hull configure -title "Editing Card Layout $options(-layoutname)"
      install editBB using ButtonBox::create $frame.editBB \
		-orient vertical
      pack $editBB -side left -fill y
      $editBB add -name size -text Resize -command [mymethod _Resize]
      $editBB add -name text -text Text -command [mymethod _AddText]
      $editBB add -name line -text Line -command [mymethod _AddLine]
      $editBB add -name rect -text Rect -command [mymethod _AddRect]
      $editBB add -name disk -text Disk -command [mymethod _AddDisk]
      $editBB add -name bitmap -text Bitmap -command [mymethod _AddBitmap]
      $editBB add -name deselect -text Deselect -command [mymethod _Deselect]
      $editBB add -name delete -text Delete -command [mymethod _DeleteSelected]
      $editBB add -name move -text Move -command [mymethod _MoveSelected]
      $editBB add -name edit -text Edit -command [mymethod _EditSelected]
      $editBB add -name save -text Save -command [mymethod _Save]
      $editBB add -name dismis -text Dismis -command [mymethod _Dismis]
      $editBB add -name help -text Help -command "BWHelp::HelpTopic EditLayout"
      wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
      install layoutCanvasSW using ScrolledWindow::create \
			$frame.layoutCanvasSW -scrollbar both -auto both
      pack $layoutCanvasSW -side right -expand yes -fill both
      install layoutCanvas using canvas $layoutCanvasSW.layoutCanvas
      pack $layoutCanvas -expand yes -fill both
      $layoutCanvasSW setwidget $layoutCanvas
      $layoutCanvas bind all <1> [mymethod _SelectItem %x %y]
      $layoutCanvas bind all <3> [mymethod _ItemMenu %x %y]
      install itemMenu using menu $layoutCanvas.itemMenu -tearoff no
      $itemMenu add command -command [mymethod _DeleteCurrent] -label Delete
      $itemMenu add command -command [mymethod _MoveCurrent] -label Move
      $itemMenu add command -command [mymethod _EditCurrent] -label Edit
      set _EditorsByName($options(-layoutname)) $self
      $dirtylabel configure -foreground [$dirtylabel cget -background]
      $dirtylabel configure -relief flat
      set selection {}
      set current   {}
      set _lockstate 0
    }
    method _GetXYXY {message} {
      $hull setstatus "$message"
      $layoutCanvas create line 0 0 0 0 -fill blue -tags [list _getxyxy _getxyxyXC]
      $layoutCanvas create line 0 0 0 0 -fill blue -tags [list _getxyxy _getxyxyYC]
      $layoutCanvas create rect 0 0 0 0 -fill {} -outline red -tags [list _getxyxy _getxyxyBOX]
      bind $layoutCanvas <Motion> [mymethod _GetXYXY_0 %x %y]
      bind $layoutCanvas <ButtonPress-1> [mymethod _GetXYXY_1 %x %y]
      bind $layoutCanvas <B1-Motion> [mymethod _GetXYXY_2 %x %y]
      bind $layoutCanvas <ButtonRelease-1> [mymethod _GetXYXY_3 %x %y]
      bind $layoutCanvas <Escape> [mymethod _Escape]
      set oldcursor [$layoutCanvas cget -cursor]
      $layoutCanvas configure -cursor crosshair
      focus $layoutCanvas
      set _lockstate 1
      while {$_lockstate > 0} {
	tkwait variable [myvar _lockstate]
      }
      bind $layoutCanvas <Motion> {}
      bind $layoutCanvas <ButtonPress-1> {}
      bind $layoutCanvas <B1-Motion> {}
      bind $layoutCanvas <ButtonRelease-1> {}
      bind $layoutCanvas <Escape> {}
      $layoutCanvas delete _getxyxy
      $layoutCanvas configure -cursor "$oldcursor"
      $hull setstatus {}
      if {$_lockstate == 0} {
	return yes
      } else {
	return no
      }
    }
    method _GetXYXY_0 {mx my} {
#      puts stderr "*** $self _GetXYXY_0 $mx $my"
      set x [$layoutCanvas canvasx $mx]
      set y [$layoutCanvas canvasx $my]
      foreach {x0 y0 x9 y9} [$layoutCanvas cget -scrollregion] {
	$layoutCanvas coords _getxyxyXC $x  $y0 $x  $y9
	$layoutCanvas coords _getxyxyYC $x0 $y  $x9 $y
      }
    }
    method _GetXYXY_1 {mx my} {
#      puts stderr "*** $self _GetXYXY_1 $mx $my"
      set _x1 [$layoutCanvas canvasx $mx]
      set _y1 [$layoutCanvas canvasx $my]
      foreach {x0 y0 x9 y9} [$layoutCanvas cget -scrollregion] {
	$layoutCanvas coords _getxyxyXC $_x1 $y0  $_x1 $y9
	$layoutCanvas coords _getxyxyYC $x0  $_y1 $x9  $_y1
      }
      $layoutCanvas coords _getxyxyBOX $_x1 $_y1 $_x1 $_y1
    }
    method _GetXYXY_2 {mx my} {
#      puts stderr "*** $self _GetXYXY_2 $mx $my"
      set x [$layoutCanvas canvasx $mx]
      set y [$layoutCanvas canvasx $my]
      foreach {x0 y0 x9 y9} [$layoutCanvas cget -scrollregion] {
	$layoutCanvas coords _getxyxyXC $x  $y0 $x  $y9
	$layoutCanvas coords _getxyxyYC $x0 $y  $x9 $y
      }
      $layoutCanvas coords _getxyxyBOX $_x1 $_y1 $x $y
    }
    method _GetXYXY_3 {mx my} {
#      puts stderr "*** $self _GetXYXY_3 $mx $my"
      set _x2 [$layoutCanvas canvasx $mx]
      set _y2 [$layoutCanvas canvasx $my]
      $layoutCanvas coords _getxyxyBOX $_x1 $_y1 $_x2 $_y2
      set _lockstate 0
    }
    method _GetPolyline {message} {
      $hull setstatus "$message"
      set _pointList {}
      set _x1 0
      set _y1 0
      $layoutCanvas create line 0 0 0 0 -fill blue -tags _getpolyline
      $layoutCanvas create line 0 0 0 0 -fill blue -dash . -tags [list _getpolyline _getpolyline_tail]
      bind $layoutCanvas <ButtonPress-1> [mymethod _GetPolyline_1 %x %y]
      bind $layoutCanvas <Motion> [mymethod _GetPolyline_2 %x %y]
      bind $layoutCanvas <ButtonRelease-3> [mymethod _GetPolyline_3 %x %y]
      bind $layoutCanvas <Escape> [mymethod _Escape]
      set oldcursor [$layoutCanvas cget -cursor]
      $layoutCanvas configure -cursor crosshair 
      focus $layoutCanvas
      set _lockstate 1
      while {$_lockstate > 0} {
	tkwait variable [myvar _lockstate]
      }
      bind $layoutCanvas <ButtonPress-1> {}
      bind $layoutCanvas <Motion> {}
      bind $layoutCanvas <ButtonRelease-3> {}
      bind $layoutCanvas <Escape> {}
      $layoutCanvas delete _getpolyline
      $layoutCanvas configure -cursor "$oldcursor"
      $hull setstatus {}
      if {$_lockstate == 0} {
	return yes
      } else {
	return no
      }
    }
    method _GetPolyline_1 {mx my} {
      set _x2 [$layoutCanvas canvasx $mx]
      set _y2 [$layoutCanvas canvasx $my]
      lappend _pointList $_x2 $_y2
      if {[llength $_pointList] >= 4} {$layoutCanvas coords _getpolyline $_pointList}
      set _x1 $_x2
      set _y1 $_y2
    }
    method _GetPolyline_2 {mx my} {
      set _x2 [$layoutCanvas canvasx $mx]
      set _y2 [$layoutCanvas canvasx $my]
      if {[llength $_pointList] == 0} {return}
      $layoutCanvas coords _getpolyline_tail [list $_x1 $_y1 $_x2 $_y2]      
    }
    method _GetPolyline_3 {mx my} {
      set _x2 [$layoutCanvas canvasx $mx]
      set _y2 [$layoutCanvas canvasx $my]
      lappend _pointList $_x2 $_y2
      if {[llength $_pointList] < 4} {
	tk_messageBox -type ok -icon warning -message "Please add at least one more point"
	return
      }
      $layoutCanvas coords _getpolyline $_pointList
      set _lockstate 0    
    }
    method _GetXY {message} {
      $hull setstatus "$message"
      $layoutCanvas create line 0 0 0 0 -fill blue -tags [list _getxyxy _getxyXC]
      $layoutCanvas create line 0 0 0 0 -fill blue -tags [list _getxyxy _getxyYC]
      bind $layoutCanvas <Motion> [mymethod _GetXY_0 %x %y]
      bind $layoutCanvas <ButtonPress-1> [mymethod _GetXY_1 %x %y]
      bind $layoutCanvas <Escape> [mymethod _Escape]
      set oldcursor [$layoutCanvas cget -cursor]
      $layoutCanvas configure -cursor crosshair
      focus $layoutCanvas
      set _lockstate 1
      while {$_lockstate > 0} {
	tkwait variable [myvar _lockstate]
      }
      bind $layoutCanvas <Motion> {}
      bind $layoutCanvas <ButtonPress-1> {}
      bind $layoutCanvas <Escape> {}
      $layoutCanvas delete _getxyxy
      $layoutCanvas configure -cursor "$oldcursor"
      $hull setstatus {}
      if {$_lockstate == 0} {
	return yes
      } else {
	return no
      }
    }
    method _GetXY_0 {mx my} {
#      puts stderr "*** $self _GetXY_0 $mx $my"
      set x [$layoutCanvas canvasx $mx]
      set y [$layoutCanvas canvasx $my]
      foreach {x0 y0 x9 y9} [$layoutCanvas cget -scrollregion] {
	$layoutCanvas coords _getxyXC $x  $y0 $x  $y9
	$layoutCanvas coords _getxyYC $x0 $y  $x9 $y
      }
    }
    method _GetXY_1 {mx my} {
#      puts stderr "*** $self _GetXY_1 $mx $my"
      set _x1 [$layoutCanvas canvasx $mx]
      set _y1 [$layoutCanvas canvasx $my]
      foreach {x0 y0 x9 y9} [$layoutCanvas cget -scrollregion] {
	$layoutCanvas coords _getxyXC $_x1 $y0  $_x1 $y9
	$layoutCanvas coords _getxyYC $x0  $_y1 $x9  $_y1
      }
      set _lockstate 0
    }
    method _Escape {} {
      set _lockstate -1
    }
    method _Deselect {} {
      if {![string equal "$selection" {}]} {
	set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
	set eletype [$layout elementtype "$selection"]
	switch $eletype {
	  text -
	  line {
		set color [$layout elementcget $selection -fill]
#		puts stderr "*** $self _Deselect: selection = $selection, color = $color"
		$layoutCanvas itemconfigure $selection -fill $color
	  }
	  oval -
	  rect {
		set fcolor [$layout elementcget $selection -fill]
		set ocolor [$layout elementcget $selection -outline]
		$layoutCanvas itemconfigure $selection -fill $fcolor $fcolor -outline $ocolor
	  }
	  bitmap {
		set fcolor [$layout elementcget $selection -foreground]
		set ocolor [$layout elementcget $selection -background]
		$layoutCanvas itemconfigure $selection -foreground $fcolor -background $ocolor
	  }
	}
	set selection {}
      }
    }      
    method _SelectItem {mx my} {
      if {$_lockstate > 0} {return}
#      puts stderr "*** $self _SelectItem $mx $my"
      set x [$layoutCanvas canvasx $mx]
      set y [$layoutCanvas canvasy $my]
      set item [$layoutCanvas find closest $x $y]
      if {[string equal "$item" {}]} {return}
      set tags [$layoutCanvas gettags $item]
      if {[llength $tags] == 0} {return}
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      set ename {}
      foreach t $tags {
	set eletype [$layout elementtype "$t"]
        if {![string equal "$eletype" {}]} {
	  set ename $t
	  break
	}
      }
      if {[string equal "$ename" {}]} {return}
      $self _Deselect
      set selection "$ename"
      switch $eletype {
	text -
	line {
		set color [$layout elementcget $ename -fill]
		set ocolor [$self _OppositeColor $color]
#		puts stderr "*** $self _SelectItem: selection = $selection, color = $color, ocolor = $ocolor"
		$layoutCanvas itemconfigure $selection -fill $ocolor
	}
        oval -
	rect {
		set fcolor [$layout elementcget $ename -fill]
		set ocolor [$layout elementcget $ename -outline]
		if {[string equal "$fcolor" {}]} {
		  set ofcolor {}
		} else {
		  set ofcolor [$self _OppositeColor $fcolor]
		}
		if {[string equal "$ocolor" {}]} {
		  set oocolor {}
		} else {
		  set oocolor [$self _OppositeColor $ocolor]
		}
		$layoutCanvas itemconfigure $selection -fill $ofcolor -outline $oocolor
	}
	bitmap {
		set fcolor [$layout elementcget $ename -foreground]
		set ocolor [$layout elementcget $ename -background]
		if {[string equal "$fcolor" {}]} {
		  set ofcolor {}
		} else {
		  set ofcolor [$self _OppositeColor $fcolor]
		}
		if {[string equal "$ocolor" {}]} {
		  set oocolor {}
		} else {
		  set oocolor [$self _OppositeColor $ocolor]
		}
		$layoutCanvas itemconfigure $selection -foreground $ofcolor $ofcolor -background $oocolor
	}
      }
    }
    method _ItemMenu {mx my} {
      if {$_lockstate > 0} {return}
      set x [$layoutCanvas canvasx $mx]
      set y [$layoutCanvas canvasy $my]
      set item [$layoutCanvas find closest $x $y]
      if {[string equal "$item" {}]} {return}
      set tags [$layoutCanvas gettags $item]
      if {[llength $tags] == 0} {return}
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      set ename {}
      foreach t $tags {
	set eletype [$layout elementtype "$t"]
        if {![string equal "$eletype" {}]} {
	  set ename $t
	  break
	}
      }
      if {[string equal "$ename" {}]} {return}
      set current "$ename"
      set rx [expr {int([winfo rootx $layoutCanvas] + $x)}]
      set ry [expr {int([winfo rooty $layoutCanvas] + $y)}]
      $itemMenu post $rx $ry
      focus $itemMenu
    }
    typemethod _ResizeToolOK {} {
      $resizeToolDialog withdraw
      return [$resizeToolDialog enddialog ok]
    }
    typemethod _ResizeToolCancel {} {
      $resizeToolDialog withdraw
      return [$resizeToolDialog enddialog cancel]
    }
    method _ResizeTool {layout} {
      $resizeWidthLE  configure -text "[$layout cget -width]"
      $resizeHeightLE configure -text "[$layout cget -height]"
      set button [$resizeToolDialog draw]
      if {[string equal "$button" {ok}]} {
	set oldw "[$layout cget -width]"
	set oldh "[$layout cget -height]"
	if {[catch {$layout configure -width  "[$resizeWidthLE cget -text]"
		    $layout configure -height "[$resizeHeightLE cget -text]"} error]} {
	  tk_messageBox -type ok -icon error -message "$error"
	  $layout configure -width  "$oldw"
	  $layout configure -height "$oldh"
	  return false
	}
        $layout layoutnodata $layoutCanvas 10 10
	return true
      } else {
	return false
      }
    }
    method _Resize {} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {[$self _ResizeTool $layout]} {
	$self _MakeDirty
      }
    }
    typemethod _TextToolOK {} {
      if {[string equal "[$textnameLE cget -text]" {}]} {
	tk_messageBox -type ok -icon warning \
		      -message "Please enter a name for this object" \
		      -parent $win
	return
      }
      $textToolDialog withdraw
      return [$textToolDialog enddialog ok]
    }
    typemethod _TextToolCancel {} {
      $textToolDialog withdraw
      return [$textToolDialog enddialog cancel]
    }
    typemethod _TextToolBrowseColor {} {
      set newcolor [SelectColor::menu .editLayoutSelectColor center \
				-parent $textToolDialog \
				-color "[$textcolorE cget -text]"]
      if {[string length "$newcolor"] > 0} {
	$textcolorE configure -text "$newcolor"
      }
    }
    method _TextTool {layout args} {
#      puts stderr "*** $self _TextTool $layout $args"
      set oldname [from args -name {}]
#      puts stderr "*** $self _TextTool: oldname = '$oldname'"
      if {[string equal "$oldname" {}]} {
	if {[$self _GetXYXY "Select start and width of text"]} {
	  if {$_x1 > $_x2} {
	    set temp $_x1
	    set _x1 $_x2
	    set _x2 $temp
	  }
	  if {$_y1 > $_y2} {
	    set temp $_y1
	    set _y1 $_y2
	    set _y2 $temp
	  }
	  set w [expr {$_x2 - $_x1}]
	  $textXSB configure -text [expr {$_x1 - 10}]
	  $textYSB configure -text [expr {$_y1 - 10}]
	  $textWSB configure -text $w
	  $textnameLE configure -editable yes
	} else {
	  return false
	}
      } else {
	$textnameLE configure -text "$oldname"
	$textnameLE configure -editable no
	set coords [$layout elementcoords "$oldname"]
	$textXSB configure -text [lindex $coords 0]
	$textYSB configure -text [lindex $coords 1]
	$textWSB configure -text [$layout elementcget "$oldname" -width]
	set font [font actual [$layout elementcget "$oldname" -font]]
	$fontselectCB configure -text "[from font -family]"
	$fontsizeselectSB configure -text [from font -size]
	$fontslantselectCB configure -text "[from font -slant]"
	$fontweightselectCB configure -text "[from font -weight]"
	$textcolorE configure -text "[$layout elementcget "$oldname" -fill]"
	$textTX delete 1.0 end
	$textTX insert end "[$layout elementcget "$oldname" -text]"
      }
      set button [$textToolDialog draw]
      if {[string equal "$button" {ok}]} {
	if {[string equal "$oldname" {}]} {
	  set name "[$textnameLE cget -text]"
	  if {[$layout elementexists "$name"]} {
	    if {[tk_messageBox \
			-type yesno -icon warning \
			-message "$name already exists in this layout.  Replace it?" \
			-parent $win]} {
	        $layout removelement "$name"
	    } else {
	      return false
	    }
	  }
	  $layout addelement "$name" text \
			[$textXSB cget -text] [$textYSB cget -text] \
			-fill "[$textcolorE cget -text]" \
			-width [$textWSB cget -text] -justify left -anchor nw \
			-font [font actual \
					[list "[$fontselectCB cget -text]" \
					      [$fontsizeselectSB cget -text] \
					      [$fontweightselectCB cget -text] \
					      [$fontslantselectCB cget -text]]] \
			-text "[$textTX get 1.0 end-1c]" \
			-tags "$name"
	} else {
	  $layout setelementcoords "$oldname" \
			[list [$textXSB cget -text] [$textYSB cget -text]]
	  $layout elementconfigure "$oldname" -fill "[$textcolorE cget -text]"
	  $layout elementconfigure "$oldname" -width [$textWSB cget -text]
	  $layout elementconfigure "$oldname" -font [font actual \
					[list "[$fontselectCB cget -text]" \
					      [$fontsizeselectSB cget -text] \
					      [$fontweightselectCB cget -text] \
					      [$fontslantselectCB cget -text]]]
	  $layout elementconfigure "$oldname" -text "[$textTX get 1.0 end-1c]"
	}	    
	$layout layoutnodata $layoutCanvas 10 10
	return true
      } else {
	return false
      }
    }
    method _AddText {} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {[$self _TextTool $layout]} {
	$self _MakeDirty
      }
    }
    typemethod _LineToolOK {} {
      if {[string equal "[$linenameLE cget -text]" {}]} {
	tk_messageBox -type ok -icon warning \
		      -message "Please enter a name for this object" \
		      -parent $win
	return
      }
      $lineToolDialog withdraw
      return [$lineToolDialog enddialog ok]
    }
    typemethod _LineToolCancel {} {
      $lineToolDialog withdraw
      return [$lineToolDialog enddialog cancel]
    }
    typemethod _LineToolBrowseColor {} {
      set newcolor [SelectColor::menu .editLayoutSelectColor center \
				-parent $lineToolDialog \
				-color "[$linecolorE cget -text]"]
      if {[string length "$newcolor"] > 0} {
	$linecolorE configure -text "$newcolor"
      }
    }
    typemethod _LineToolUpdateXY {} {
      set selected [$lineXYLB selection get]
      if {[llength $selected] < 1} {return}
      set sel [lindex $selected 0]
      $lineXYLB itemconfigure $sel \
	-data [list [$lineXSB cget -text] [$lineYSB cget -text]] \
	-text [format {%8.2f %8.2f} [$lineXSB cget -text] [$lineYSB cget -text]]
    }
    typemethod _LineToolDeleteXY {} {
      set selected [$lineXYLB selection get]
      if {[llength $selected] < 1} {return}
      set sel [lindex $selected 0]
      $lineXYLB delete $sel
    }
    typemethod _LineToolAddXY {} {
      set last [lindex [$lineXYLB items end] 0]
      incr last
      $lineXYLB insert end $last \
	-data [list [$lineXSB cget -text] [$lineYSB cget -text]] \
	-text [format {%8.2f %8.2f} [$lineXSB cget -text] [$lineYSB cget -text]]
    }
    method _LineTool {layout args} {
      $lineXYLB delete [$lineXYLB items]
      set oldname [from args -name {}]
      if {[string equal "$oldname" {}]} {
	if {[$self _GetPolyline "Select line points"]} {
	  set index 0
	  foreach {x y} $_pointList {
	    incr index
	    set x [expr {$x - 10}]
	    set y [expr {$y - 10}]
	    $lineXYLB insert end $index \
			-data [list $x $y] -text [format {%8.2f %8.2f} $x $y]
	  }
	  $linenameLE configure -editable yes
	} else {
	  return false
	}
      } else {
	$linenameLE configure -text "$oldname"
	$linenameLE configure -editable no
	set coords [$layout elementcoords "$oldname"]
	set index 0
	foreach {x y} $coords {
	  incr index
	  $lineXYLB insert end $index \
			-data [list $x $y] -text [format {%8.2f %8.2f} $x $y]
	}
	$linecolorE configure -text [$layout elementcget "$oldname" -fill]
	$linethickSB configure -text [$layout elementcget "$oldname" -width]
	$linedashCB configure -text [$layout elementcget "$oldname" -dash]
      }
      set button [$lineToolDialog draw]
      if {[string equal "$button" {ok}]} {
	set coords {}
	foreach i [$lineXYLB items] {
	  set xy [$lineXYLB itemcget $i -data]
	  lappend coords [lindex $xy 0] [lindex $xy 1]
	}
	if {[string equal "$oldname" {}]} {
	  set name "[$linenameLE cget -text]"
	  if {[$layout elementexists "$name"]} {
	    if {[tk_messageBox \
			-type yesno -icon warning \
			-message "$name already exists in this layout.  Replace it?" \
			-parent $win]} {
	        $layout removelement "$name"
	    } else {
	      return false
	    }
	  }
	  eval [list $layout addelement "$name" line] $coords \
		[list -fill "[$linecolorE cget -text]" \
		-width [$linethickSB cget -text] \
		-dash "[$linedashCB cget -text]" \
		-tags "$name"]
	} else {
	  $layout setelementcoords "$oldname" $coords
	  $layout elementconfigure "$oldname" -fill "[$linecolorE cget -text]"
	  $layout elementconfigure "$oldname" -width [$linethickSB cget -text]
	  $layout elementconfigure "$oldname" -dash "[$linedashCB cget -text]"
	}
	$layout layoutnodata $layoutCanvas 10 10
	return true
      } else {
	return false
      }
    }
    method _AddLine {} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {[$self _LineTool $layout]} {
	$self _MakeDirty
      }
    }
    typemethod _RectDiskToolOK {} {
      if {[string equal "[$rectDisknameLE cget -text]" {}]} {
	tk_messageBox -type ok -icon warning \
		      -message "Please enter a name for this object" \
		      -parent $rectDiskToolDialog
	return
      }
      $rectDiskToolDialog withdraw
      return [$rectDiskToolDialog enddialog ok]
    }
    typemethod _RectDiskToolCancel {} {
      $rectDiskToolDialog withdraw
      return [$rectDiskToolDialog enddialog cancel]
    }
    typemethod _RectDiskToolBrowseFillColor {} {
      set newcolor [SelectColor::menu .editLayoutSelectColor center \
				-parent $rectDiskToolDialog \
				-color "[$rectDiskfillcolorE cget -text]"]
      if {[string length "$newcolor"] > 0} {
	$rectDiskfillcolorE configure -text "$newcolor"
      }
    }
    typemethod _RectDiskToolBrowseOutlineColor {} {
      set newcolor [SelectColor::menu .editLayoutSelectColor center \
				-parent $rectDiskToolDialog \
				-color "[$rectDiskoutlinecolorE cget -text]"]
      if {[string length "$newcolor"] > 0} {
	$rectDiskoutlinecolorE configure -text "$newcolor"
      }
    }
    method _RectTool {layout args} {
      set oldname [from args -name {}]
      if {[string equal "$oldname" {}]} {
	if {[$self _GetXYXY "Select corners of rectangle"]} {
	  if {$_x1 > $_x2} {
	    set temp $_x1
	    set _x1 $_x2
	    set _x2 $temp
	  }
	  if {$_y1 > $_y2} {
	    set temp $_y1
	    set _y1 $_y2
	    set _y2 $temp
	  }
 	  $rectDiskX1SB configure -text [expr {$_x1 - 10}]
	  $rectDiskY1SB configure -text [expr {$_y1 - 10}]
 	  $rectDiskX2SB configure -text [expr {$_x2 - 10}]
	  $rectDiskY2SB configure -text [expr {$_y2 - 10}]
	  $rectDisknameLE configure -editable yes
	} else {
	  return false
	}
      } else {
	$rectDisknameLE configure -text "$oldname"
	$rectDisknameLE configure -editable no
	set coords [$layout elementcoords "$oldname"]
	foreach {x1 y1 x2 y2} $coords {
 	  $rectDiskX1SB configure -text $x1
	  $rectDiskY1SB configure -text $y1
 	  $rectDiskX2SB configure -text $x2
	  $rectDiskY2SB configure -text $y2
	}
	$rectDiskfillcolorE configure -text "[$layout elementcget "$oldname" -fill]"
	$rectDiskoutlinecolorE configure -text "[$layout elementcget "$oldname" -outline]"
      }
      set button [$rectDiskToolDialog draw]
      if {[string equal "$button" {ok}]} {
	if {[string equal "$oldname" {}]} {
	  set name "[$rectDisknameLE cget -text]"
	  if {[$layout elementexists "$name"]} {
	    if {[tk_messageBox \
			-type yesno -icon warning \
			-message "$name already exists in this layout.  Replace it?" \
			-parent $win]} {
	      $layout removelement "$name"
	    } else {
	      return false
	    }
	  }
	  $layout addelement "$name" rect \
		[$rectDiskX1SB cget -text] [$rectDiskY1SB cget -text] \
		[$rectDiskX2SB cget -text] [$rectDiskY2SB cget -text] \
		-fill "[$rectDiskfillcolorE cget -text]" \
		-outline "[$rectDiskoutlinecolorE cget -text]" \
		-tags "$name"
	} else {
	  $layout setelementcoords "$oldname" \
		[list [$rectDiskX1SB cget -text] [$rectDiskY1SB cget -text] \
		      [$rectDiskX2SB cget -text] [$rectDiskY2SB cget -text]]
	  $layout elementconfigure "$oldname" -fill "[$rectDiskfillcolorE cget -text]"
	  $layout elementconfigure "$oldname" -outline "[$rectDiskoutlinecolorE cget -text]"
	}
	$layout layoutnodata $layoutCanvas 10 10
        return true
      } else {
	return false
      }
    }
    method _AddRect {} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {[$self _RectTool $layout]} {
	$self _MakeDirty
      }
    }
    method _DiskTool {layout args} {
      set oldname [from args -name {}]
      if {[string equal "$oldname" {}]} {
	if {[$self _GetXYXY "Select corners of disk"]} {
	  if {$_x1 > $_x2} {
	    set temp $_x1
	    set _x1 $_x2
	    set _x2 $temp
	  }
	  if {$_y1 > $_y2} {
	    set temp $_y1
	    set _y1 $_y2
	    set _y2 $temp
	  }
 	  $rectDiskX1SB configure -text [expr {$_x1 - 10}]
	  $rectDiskY1SB configure -text [expr {$_y1 - 10}]
 	  $rectDiskX2SB configure -text [expr {$_x2 - 10}]
	  $rectDiskY2SB configure -text [expr {$_y2 - 10}]
	  $rectDisknameLE configure -editable yes
	} else {
	  return false
	}
      } else {
	$rectDisknameLE configure -text "$oldname"
	$rectDisknameLE configure -editable no
	set coords [$layout elementcoords "$oldname"]
	foreach {x1 y1 x2 y2} $coords {
 	  $rectDiskX1SB configure -text $x1
	  $rectDiskY1SB configure -text $y1
 	  $rectDiskX2SB configure -text $x2
	  $rectDiskY2SB configure -text $y2
	}
	$rectDiskfillcolorE configure -text "[$layout elementcget "$oldname" -fill]"
	$rectDiskoutlinecolorE configure -text "[$layout elementcget "$oldname" -outline]"
      }
      set button [$rectDiskToolDialog draw]
      if {[string equal "$button" {ok}]} {
	if {[string equal "$oldname" {}]} {
	  set name "[$rectDisknameLE cget -text]"
	  if {[$layout elementexists "$name"]} {
	    if {[tk_messageBox \
			-type yesno -icon warning \
			-message "$name already exists in this layout.  Replace it?" \
			-parent $win]} {
	      $layout removelement "$name"
	    } else {
	      return false
	    }
	  }
	  $layout addelement "$name" oval \
		[$rectDiskX1SB cget -text] [$rectDiskY1SB cget -text] \
		[$rectDiskX2SB cget -text] [$rectDiskY2SB cget -text] \
		-fill "[$rectDiskfillcolorE cget -text]" \
		-outline "[$rectDiskoutlinecolorE cget -text]" \
		-tags "$name"
	} else {
	  $layout setelementcoords "$oldname" \
		[list [$rectDiskX1SB cget -text] [$rectDiskY1SB cget -text] \
		      [$rectDiskX2SB cget -text] [$rectDiskY2SB cget -text]]
	  $layout elementconfigure "$oldname" -fill "[$rectDiskfillcolorE cget -text]"
	  $layout elementconfigure "$oldname" -outline "[$rectDiskoutlinecolorE cget -text]"
	}
	$layout layoutnodata $layoutCanvas 10 10
        return true
      } else {
	return false
      }
    }
    method _AddDisk {} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {[$self _DiskTool $layout]} {
	$self _MakeDirty
      }
    }
    typemethod _BitmapToolOK {} {
      if {[string equal "[$bitmapnameLE cget -text]" {}]} {
	tk_messageBox -type ok -icon warning \
		      -message "Please enter a name for this object" \
		      -parent $bitmapToolDialog
	return
      }
      $bitmapToolDialog withdraw
      return [$bitmapToolDialog enddialog ok]
    }
    typemethod _BitmapToolCancel {} {
      $bitmapToolDialog withdraw
      return [$bitmapToolDialog enddialog cancel]
    }
    typemethod _BitmapToolBrowseForeColor {} {
      set newcolor [SelectColor::menu .editLayoutSelectColor center \
				-parent $bitmapToolDialog \
				-color "[$bitmapforecolorE cget -text]"]
      if {[string length "$newcolor"] > 0} {
	$bitmapforecolorE configure -text "$newcolor"
      }
    }
    typemethod _BitmapToolBrowseBackColor {} {
      set newcolor [SelectColor::menu .editLayoutSelectColor center \
				-parent $bitmapToolDialog \
				-color "[$bitmapbackcolorE cget -text]"]
      if {[string length "$newcolor"] > 0} {
	$bitmapbackcolorE configure -text "$newcolor"
      }
    }
    typemethod _BitmapToolBMFile {} {
      set oldfile "[$bitmapBitmapCB cget -text]"
      if {[lsearch -exact {error gray75 gray50 gray25 gray12 hourglass 
                                 info questhead question warning} "$oldfile"] < 0 &&
	  [regexp {^@(.*)$} "$oldfile" -> f] > 0} {
	set oldfile "$f"
      } else {
	set oldfile {}
      }
      set newfile [tk_getOpenFile -defaultextension .xbm \
				  -initialfile "$oldfile" \
				  -parent $bitmapToolDialog \
				  -filetypes {
					{{X11 Bitmap files} {.xbm} TEXT}
					{{All Files}        *          }
				  } \
				  -title "Select a bitmap file"]
      if {[string equal "$newfile" {}]} {return}
      $bitmapBitmapCB configure -text "@$newfile"
    }
    method _BitmapTool {layout args} {
      set oldname [from args -name {}]
      if {[string equal "$oldname" {}]} {
	if {[$self _GetXY "Select position of bitmap"]} {
 	  $bitmapXSB configure -text [expr {$_x1 - 10}]
	  $bitmapYSB configure -text [expr {$_y1 - 10}]
	  $bitmapnameLE configure -editable yes
	} else {
	  return false
	}
      } else {
	$bitmapnameLE configure -text "$oldname"
	$bitmapnameLE configure -editable no
	set coords [$layout elementcoords "$oldname"]
	foreach {x y} $coords {
 	  $bitmapXSB configure -text $x
	  $bitmapYSB configure -text $y
	}
	$bitmapforecolorE configure -text "[$layout elementcget "$oldname" -foreground]"
	$bitmapbackcolorE configure -text "[$layout elementcget "$oldname" -background]"
	$bitmapBitmapCB configure -text "[$layout elementcget "$oldname" -bitmap]"
      }
      set button [$bitmapToolDialog draw]
      if {[string equal "$button" {ok}]} {
	if {[string equal "$oldname" {}]} {
	  set name "[$bitmapnameLE cget -text]"
	  if {[$layout elementexists "$name"]} {
	    if {[tk_messageBox \
			-type yesno -icon warning \
			-message "$name already exists in this layout.  Replace it?" \
			-parent $win]} {
	      $layout removelement "$name"
	    } else {
	      return false
	    }
	  }
	  $layout addelement "$name" bitmap \
		[$bitmapXSB cget -text] [$bitmapYSB cget -text] \
		-foreground "[$bitmapforecolorE cget -text]" \
		-background "[$bitmapbackcolorE cget -text]" \
		-bitmap     "[$bitmapBitmapCB cget -text]" \
		-tags "$name"
	} else {
	  $layout setelementcoords "$oldname" [list [$bitmapXSB cget -text] \
						    [$bitmapYSB cget -text]]
	  $layout elementconfigure "$oldname" -foreground "[$bitmapforecolorE cget -text]"
	  $layout elementconfigure "$oldname" -background "[$bitmapbackcolorE cget -text]"
	  $layout elementconfigure "$oldname" -bitmap     "[$bitmapBitmapCB cget -text]"
	}
	$layout layoutnodata $layoutCanvas 10 10
        return true
      } else {
	return false
      }
    }
    method _AddBitmap {} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {[$self _BitmapTool $layout]} {
	$self _MakeDirty
      }
    }
    method _DeleteSelected {} {
      if {[string equal "$selection" {}]} {return}
      $self _DeleteObject "$selection"
    }
    method _MoveSelected {} {
      if {[string equal "$selection" {}]} {return}
      $self _MoveObject "$selection"
    }
    method _EditSelected {} {
      if {[string equal "$selection" {}]} {return}
      $self _EditObject "$selection"
    }
    method _DeleteCurrent {} {
      if {[string equal "$current" {}]} {return}
      $self _DeleteObject "$current"
    }
    method _MoveCurrent {} {
      if {[string equal "$current" {}]} {return}
      $self _MoveObject "$current"
    }
    method _EditCurrent {} {
      if {[string equal "$current" {}]} {return}
      $self _EditObject "$current"
    }
    method _DeleteObject {name} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {![$layout elementexists "$name"]} {return}
      if {[tk_messageBox -type yesno -icon warning \
			 -message "Really delete element $name?" \
			 -parent $win]} {
	set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
	if {[string equal "$layout" {}]} {return}
	$layout removeelement "$name"
	$self _MakeDirty
	$layout layoutnodata $layoutCanvas 10 10
	raise $win
      }
    }
    method _MoveObject {name} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {![$layout elementexists "$name"]} {return}
      bind $layoutCanvas <ButtonPress-1> [mymethod _Move_1 %x %y "$name"]
      bind $layoutCanvas <B1-Motion> [mymethod _Move_2 %x %y "$name"]
      bind $layoutCanvas <ButtonRelease-1> [mymethod _Move_3 %x %y "$name"]
      bind $layoutCanvas <Escape> [mymethod _Escape]
      set oldcursor [$layoutCanvas cget -cursor]
      $layoutCanvas configure -cursor fleur
      focus $layoutCanvas
      set _lockstate 1
      $hull setstatus "Drag Object"
      while {$_lockstate > 0} {
	tkwait variable [myvar _lockstate]
      }
      bind $layoutCanvas <ButtonPress-1> {}
      bind $layoutCanvas <B1-Motion> {}
      bind $layoutCanvas <ButtonRelease-1> {}
      bind $layoutCanvas <Escape> {}
      $layoutCanvas configure -cursor "$oldcursor"
      $hull setstatus {}
      if {$_lockstate == 0} {
        set ncoords {}
        foreach {x y} [$layoutCanvas coords "$name"] {
	  lappend ncoords [expr {$x - 10}] [expr {$y - 10}]
	}
	$layout setelementcoords "$name" $ncoords
        $self _MakeDirty
      }
      $layout layoutnodata $layoutCanvas 10 10
    }
    method _Move_1 {mx my tag} {
      set _x1 [$layoutCanvas canvasx $mx]
      set _y1 [$layoutCanvas canvasx $my]
    }
    method _Move_2 {mx my tag} {
      set x [$layoutCanvas canvasx $mx]
      set y [$layoutCanvas canvasx $my]
      $layoutCanvas move "$tag" [expr {$x - $_x1}] [expr {$y - $_y1}]
      set _x1 $x
      set _y1 $y
    }
    method _Move_3 {mx my tag} {
      set x [$layoutCanvas canvasx $mx]
      set y [$layoutCanvas canvasx $my]
      $layoutCanvas move "$tag" [expr {$x - $_x1}] [expr {$y - $_y1}]
      set _lockstate 0
    }
    method _EditObject {name} {
      set layout [Print::CardLayout getLayoutByName $options(-layoutname)]
      if {[string equal "$layout" {}]} {return}
      if {![$layout elementexists "$name"]} {return}
      switch [$layout elementtype "$name"] {
	text {
	  if {[$self _TextTool $layout -name "$name"]} {
	    $self _MakeDirty
	  }
	}
	line {
	  if {[$self _LineTool $layout -name "$name"]} {
	    $self _MakeDirty
	  }
	}
	rect {
	  if {[$self _RectTool $layout -name "$name"]} {
	    $self _MakeDirty
	  }
	}
	oval {
	  if {[$self _DiskTool $layout -name "$name"]} {
	    $self _MakeDirty
	  }
	}
	bitmap {
	  if {[$self _BitmapTool $layout -name "$name"]} {
	    $self _MakeDirty
	  }
	}
      }
    }
    method _MakeDirty {} {
      $dirtylabel configure -foreground red
      $dirtylabel configure -relief sunken
    }
    method _OppositeColor {color} {
      set rgb [winfo rgb $layoutCanvas "$color"]
      set orgb {}
      foreach c $rgb {
	lappend orgb [expr {65535 - $c}]
      }
      return [eval format {#%04x%04x%04x} $orgb]
    }
    method _IsDirty {} {
      return [expr {![string equal "[$dirtylabel cget -foreground]" \
			           "[$dirtylabel cget -background]"]}]
    }
    method _Dismis {} {
      if {[$self _IsDirty]} {
	if {[tk_messageBox -type yesno -icon question \
			-message "Layout has not been saved! Save it to disk?" \
			-parent $win]} {
	  $self _Save
        }
      }
      wm withdraw $win
    }
    method _Save {} {
      set layout [Print::CardLayout getLayoutByName "$options(-layoutname)"]
      set wassaved [$layout saveToFile]
      if {!$wassaved} {return}
      $dirtylabel configure -foreground [$dirtylabel cget -background]
      $dirtylabel configure -relief flat
    }
    method raise {} {
      wm deiconify $win
      raise $win
    }
    method initialize {newP} {
      set layout [Print::CardLayout getLayoutByName "$options(-layoutname)"]
      $layout layoutnodata $layoutCanvas 10 10
      if {$newP} {
	$dirtylabel configure -foreground red
	$dirtylabel configure -relief sunken
      } else {
	$dirtylabel configure -foreground [$dirtylabel cget -background]
	$dirtylabel configure -relief flat
      }
    }
    typemethod draw {args} {
      set name [from args -layoutname]
      set new [from args -new]
      if {[catch [list set _EditorsByName($name)] te]} {
	set te [eval $type create .editLayout%AUTO% -layoutname $name $args]
      } else {
	wm deiconify $te
	$te raise
      }
      $te initialize $new
    }
  }
  snit::widgetadaptor PrintProgress {
    delegate option -height to hull
    delegate option -width to hull
    delegate option -menu to hull
    delegate option -title to hull
    option -transientparent -readonly yes -default {}
    option {-cancelcommand cancelCommand CancelCommand} -default {}
    option {-documentstartcommand documentStartCommand DocumentStartCommand} \
	-default {}
    option {-pagecommand  pageCommand  PageCommand} -default {}
    option {-getpagecountcommand  getPageCountCommand  GetPageCountCommand} -default {}
    option {-documentendcommand documentEndCommand DocumentEndCommand} \
	-default {}
    option {-selectprintercommand selectPrinterCommand SelectPrinterCommand} \
	   -default {}
    component userFrame
    component buttons
    variable _canceled 0
    method getframe {} {return $userFrame}
    delegate method {buttons *} to buttons
    delegate method setstatus to hull
    constructor {args} {
      set options(-transientparent) [from args -transientparent]
      installhull using Windows::HomeLibrarianTopLevel \
	-transientparent $options(-transientparent) \
	-windowmenu {} -separator both
      set frame [$hull getframe]
      $self configurelist $args
      install userFrame using frame $frame.userFrame -borderwidth 0
      pack $userFrame -expand yes -fill both
      install buttons using ButtonBox::create $frame.buttons \
		-orient horizontal -homogeneous no
      pack $buttons -side bottom -fill x
      $buttons add -name print -text Print -default active \
		   -command [mymethod _Print]
      $buttons add -name cancel -text Cancel -default normal \
		   -command [mymethod _Cancel]
      $buttons add -name help -text Help -default normal \
		   -command "BWHelp::HelpTopic PrintProgress"
      wm protocol $win WM_DELETE_WINDOW [mymethod _Cancel]
    }
    method _Print {} {
      $buttons itemconfigure print -state disabled
      if {[string equal "$options(-selectprintercommand)" {}]} {
	set printcommand "|lpr"
      } else {
	set printcommand [uplevel #0 "$options(-selectprintercommand) -parent $win"]
      }
#      puts stderr "*** $self _Print: printcommand = '$printcommand'"
      if {[string equal "$printcommand" {}]} {return [$self _Cancel]}
      if {[catch [list open "$printcommand" w] chan]} {
	tk_messageBox -type ok -icon error -message "Error opening $printcommand: $chan"
	return [$self _Cancel]
      }
      if {![string equal "$options(-documentstartcommand)" {}]} {
	uplevel #0 "$options(-documentstartcommand) $chan"
      }
      if {![string equal "$options(-getpagecountcommand)" {}]} {
	set pagecount [uplevel #0 "$options(-getpagecountcommand) $chan"]
      } else {
	set pagecount 1
      }
      set pagenumber 0
      if {![string equal "$options(-pagecommand)" {}]} {
        incr pagenumber
	while {[uplevel #0 "$options(-pagecommand) $chan"]} {
	  $hull setprogress [expr {(double($pagenumber)/double($pagecount)) * 100}]
	  update
	  if {$_canceled} {close $chan;return}
	  incr pagenumber
	}
	$hull setprogress 100
	$hull setstatus {}
      }
      if {![string equal "$options(-documentendcommand)" {}]} {
	uplevel #0 "$options(-documentendcommand) $chan"
      }
      close $chan
      catch {destroy $win} message
#      puts stderr "*** $self _Print: message = $message"
    }
    method _Cancel {} {
      if {![string equal "$options(-cancelcommand)" {}]} {
	uplevel #0 "$options(-cancelcommand)"
      }
      set _canceled 1
      update
      catch {destroy $win} message
#      puts stderr "*** $self _Cancel: message = $message"
    }
  }
  snit::widgetadaptor PrintTextProgress {
    option -text -readonly yes -default {}
    option {-papersize paperSize PaperSize} -readonly yes -default letter
    option {-pstitle psTitle PsTitle} -readonly yes -default {Untitled}
    delegate option -title to hull
    delegate option -menu to hull
    variable _textwidth 0
    variable _pagewidth 0
    variable _pageheight 0
    variable _textheight 0
    variable _leftmargin 0
    variable _topmargin 0
    variable _pagecount -1
    variable _currentpage 0
    variable _texttopY 0
    variable _textChunks -array {}
    component scroll
    component  t2p
    constructor {args} {
      installhull using Print::PrintProgress \
		-documentstartcommand [mymethod _StartTextDocument] \
		-getpagecountcommand  [mymethod _CountTextPages] \
		-pagecommand          [mymethod _PrintTextPage] \
		-documentendcommand   [mymethod _EndTextDocument] \
		-selectprintercommand [mymethod _SelectPrinterDialog]
      $self configurelist $args
      set frame [$hull getframe]
      install scroll using ScrolledWindow::create $frame.scroll \
				-scrollbar both -auto both
      pack $scroll -expand yes -fill both
      install t2p using Print::TextToPostscript $scroll.t2p
      pack $t2p -expand yes -fill both
      $scroll setwidget $t2p
      $self _ComputeSizes "$options(-papersize)"
      $t2p configure  -text "$options(-text)" -width $_textwidth
    }
    SelectPrintDialog_typecomponents
    typecomponent paperSizeCB
    SelectPrintDialog_typeconstructor .selectTextPrinterDialog {
      set paperSizeCB [LabelComboBox $frame.paperSizeCB \
					-label "Paper:" -labelwidth 15 \
					-editable no \
					-values {a4 halfletter letter legal 
						 3x5 5x8} \
					-text letter]
      pack $paperSizeCB -fill x
    }
    SelectPrintDialog_typemethods {
      set defpapersize [from args -papersize letter]
      $paperSizeCB configure -text "$defpapersize"
    }
    method _SelectPrinterDialog {args} {
      switch [eval $type _DrawSelectPrinterDialog $args] {
	ok {
	  set options(-papersize) "[paperSizeCB cget -text]"
          $self _ComputeSizes "$options(-papersize)"
	  $t2p configure  -text "$options(-text)" -width $_textwidth
	  set _pagecount -1
	  return "$_PrinterPath"
        }
	cancel {return {}}
      }
    }
    method _ComputeSizes {papersize} {
      switch -- "$papersize" {
	a4 {
		set _pagewidth 595
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 842
		set _textheight [expr {$_pageheight - 72}]
	}
	halfletter {
		set _pagewidth 396
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 612
		set _textheight [expr {$_pageheight - 72}]
	}	
	8.5x11 -
	letter {
		set _pagewidth 612
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 792
		set _textheight [expr {$_pageheight - 72}]
	}
	8.5x14 -
	legal {
		set _pagewidth 612
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 1008
		set _textheight [expr {$_pageheight - 72}]
	}
	3x5 {
		set _textwidth [expr {5 * 72}]
		set _textheight [expr {3 * 72}]
		set _pagewidth [expr {5 * 72}]
		set _pageheight [expr {3 * 72}]
	}
	5x8 {
		set _textwidth [expr {8 * 72}]
		set _textheight [expr {5 * 72}]
		set _pagewidth [expr {8 * 72}]
		set _pageheight [expr {5 * 72}]
	}
	default {
		set _pagewidth 612
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 792
		set _textheight [expr {$_pageheight - 72}]
	}
      }
      set _leftmargin [expr {double($_pagewidth - $_textwidth)/ 2.0}]
      set _topmargin [expr {$_pageheight - (double($_pageheight - $_textheight)/ 2.0)}]
    }
    method _ComputePages {} {
      set _pagecount 1
#      puts stderr "*** $self _ComputePages: indexspec is @0,$_textheight"
      set index [$t2p itemindex @0,$_textheight]
      incr index -1
#      puts stderr "*** $self _ComputePages: index = '$index'"
      set _textChunks($_pagecount) [string range "$options(-text)" 0 $index]
      set next [expr {$index + 1}]
      $t2p configure -text [string range "$options(-text)" $next end]
      while {$next < [string length "$options(-text)"]} {
	incr _pagecount
#	puts stderr "*** $self _ComputePages: indexspec is @0,$_textheight"
	set index [expr {$next + [$t2p itemindex @0,$_textheight]}]
	incr index -1
#	puts stderr "*** $self _ComputePages: index = $index, _pagecount = $_pagecount"
        set _textChunks($_pagecount) [string range "$options(-text)" $next $index]
        set next [expr {$index + 1}]
	$t2p configure -text [string range "$options(-text)" $next end]
      }
#      puts stderr "*** $self _ComputePages: _pagecount = $_pagecount"
    }
    method _StartTextDocument {chan} {
      puts $chan "%!PS-Adobe-2.0"
      puts $chan "%%Creator: PrintFunctions of HomeLibrarian. Copyright 2006 Robert Heller D/B/A Deepwoods Software."
      puts $chan "%%Title: $options(-pstitle)"
      puts $chan "%%CreationDate: [clock format [clock seconds]]"
      puts $chan "%%Pages: [$self _CountTextPages $chan]"
      puts $chan "%%BoundingBox: 0 0 $_pagewidth $_pageheight"
      puts $chan "%%EndComments"
      puts $chan "%%BeginProlog"
      puts $chan "/EncapDict 200 dict def EncapDict begin"
      puts $chan "/showpage {} def /erasepage {} def /copypage {} def end"
      puts $chan "/BeginInclude {0 setgray 0 setlinecap 1 setlinewidth"
      puts $chan "0 setlinejoin 10 setmiterlimit \[\] 0 setdash"
      puts $chan "/languagelevel where {"
      puts $chan "  pop"
      puts $chan "  languagelevel 2 ge {"
      puts $chan "    false setoverprint"
      puts $chan "    false setstrokeadjust"
      puts $chan "  } if"
      puts $chan "} if"
      puts $chan "newpath"
      puts $chan "save $_leftmargin $_topmargin translate EncapDict begin} def"
      puts $chan "/EndInclude {restore end} def"
      puts $chan "%%EndProlog"
      set _texttopY 0
    }
    method _CountTextPages {chan} {
      if {$_pagecount <= 0} {$self _ComputePages}
      return $_pagecount
    }
    method _PrintTextPage {chan} {
      incr _currentpage
      if {$_currentpage > $_pagecount} {
	return false
      }
      $hull setstatus "Printing page $_currentpage..."
      puts $chan "%%Page: $_currentpage $_currentpage"
      puts $chan "BeginInclude"
      $t2p configure -text "$_textChunks($_currentpage)"
      update idle
      set postscript "[$t2p getps -pageheight $_textheight \
			  -pagewidth $_textwidth -y 0 -x 0 \
			  -height $_textheight -width $_textwidth \
			  -pagex 0 -pagey 0 -pageanchor nw]"
      regsub -all -line {^%%(.*)$} "$postscript" {%#\1} postscript
      puts $chan "$postscript"
      puts $chan "EndInclude showpage"
      set _texttopY [expr {$_texttopY + $_textheight}]
      return true	
    }
    method _EndTextDocument {chan} {
      puts $chan "%%EOF"
    }
  }
  snit::widgetadaptor PrintCardProgress {
    option -key -default {} -readonly yes
    option {-searchwheresql searchWhereSql SearchWhereSql} -default {} -readonly yes
    option {-orderbycolumn orderByColumn OrderByColumn} -default {} -readonly yes
    option {-asksql askSql AskSql} -default no -readonly yes
    option {-papersize paperSize PaperSize} -readonly yes -default 3x5
    option {-cardspagelayout cardsPageLayout CardsPageLayout} -readonly yes -default {1 0.0 1 0.0}
    option {-cardlayout cardLayout CardLayout} -readonly yes -default {}
    option -pstitle -default {Untitled}
    delegate option -title to hull
    delegate option -menu to hull
    variable _textwidth 0
    variable _pagewidth 0
    variable _pageheight 0
    variable _textheight 0
    variable _leftmargin 0
    variable _topmargin 0
    variable _rows 1
    variable _cols 1
    variable _currow 1
    variable _curcol 1
    variable _rowoff 0
    variable _coloff 0
    variable _cardcount -1
    variable _currentpage 0
    variable _currentcard 0
    variable _needshowpage false
    component scroll
    component  c2p
    constructor {args} {  
      installhull using Print::PrintProgress \
		-documentstartcommand [mymethod _StartCardDocument] \
		-getpagecountcommand  [mymethod _CountCards] \
		-pagecommand          [mymethod _PrintCard] \
		-documentendcommand   [mymethod _EndCardDocument] \
		-selectprintercommand [mymethod _SelectPrinterDialog]
      $self configurelist $args
      set frame [$hull getframe]
      install scroll using ScrolledWindow::create $frame.scroll \
				-scrollbar both -auto both
      pack $scroll -expand yes -fill both
      install c2p using Print::CardToPostscript $scroll.c2p
      pack $c2p -expand yes -fill both
      $scroll setwidget $c2p
      $self _ComputeSizes "$options(-papersize)"
      if {![string equal "$options(-cardlayout)" {}]} {
	$c2p configure -layout "$options(-cardlayout)"
      }
    }
    SelectPrintDialog_typecomponents
    typecomponent paperSizeCB
    typecomponent cardLayoutLF
    typecomponent  cardLayoutE
    typecomponent  cardLayoutB
    typecomponent cardsPageLayoutLF
    typecomponent  cardsPageLayoutRSB
    typecomponent  cardsPageLayoutCSB
    typecomponent  cardsPageLayoutRoffSB
    typecomponent  cardsPageLayoutCoffSB
    typecomponent sqlclauseFrame
    typecomponent  orderByLCB
    typevariable   whereclauseelements -array {}
    typevariable  _fieldnames {Key Title Author Subject Description Location 
			       Category Media Publisher PubLocation PubDate 
			       Edition ISBN}
    typevariable _compops {is {is not} {is like} {is not like} {greater than} 
			   {less than}}
    typevariable _connops {and or}
    typevariable _lastrowindex


    SelectPrintDialog_typeconstructor .selectCardPrinterDialog {
      set paperSizeCB [LabelComboBox $frame.paperSizeCB \
					-label "Paper:" -labelwidth 16 \
					-editable no \
					-values {a4 halfletter letter legal 
						 3x5 5x8} \
					-text 3x5]
      pack $paperSizeCB -fill x
      set cardLayoutLF [LabelFrame::create $frame.cardLayoutLF \
				-text "Card Layout:" \
				-side left -width 16]
      pack $cardLayoutLF -expand yes -fill x
      set f [$cardLayoutLF getframe]
      set cardLayoutE [Entry::create $f.cardLayoutE -editable no]
      pack $cardLayoutE -fill x -expand yes -side left
      set cardLayoutB [Button::create $f.cardLayoutB -text "Browse Layouts" \
				-command [mytypemethod _BrowseCardLayouts]]
      pack $cardLayoutB -side right
      set cardsPageLayoutLF [LabelFrame::create $frame.cardsPageLayoutLF \
				-text "Multiple Card Page Layout" -side top]
      pack $cardsPageLayoutLF -expand yes -fill both
      set f [$cardsPageLayoutLF getframe]
      set cardsPageLayoutRSB [LabelSpinBox::create $f.cardsPageLayoutRSB \
				-label "Rows:" -labelwidth 16 -range {1 99 1}]
      grid $cardsPageLayoutRSB -row 0 -column 0 -sticky ew
      set cardsPageLayoutRoffSB [LabelSpinBox::create $f.cardsPageLayoutRoffSB \
				-label "Row Offset:" -labelwidth 16 \
				-range {0.0 9999.0 1.0}]
      grid $cardsPageLayoutRoffSB -row 0 -column 1 -sticky ew
      set cardsPageLayoutCSB [LabelSpinBox::create $f.cardsPageLayoutCSB \
				-label "Columns:" -labelwidth 16 -range {1 99 1}]
      grid $cardsPageLayoutCSB -row 1 -column 0 -sticky ew
      set cardsPageLayoutCoffSB [LabelSpinBox::create $f.cardsPageLayoutCoffSB \
				-label "Column Offset:" -labelwidth 16 \
				-range {0.0 9999.0 1.0}]
      grid $cardsPageLayoutCoffSB -row 1 -column 1 -sticky ew
      set sqlclauseFrame [frame $frame.sqlclauseFrame -borderwidth 0]
      set orderByLCB [LabelComboBox::create $sqlclauseFrame.orderByLCB \
				-label "Order By Column:" -labelwidth 16 \
				-values {Key Title Author Subject} \
				-text Key]
      grid configure $orderByLCB -column 0 -row 0 -columnspan 6 -sticky we
      set whereclauseelements(1,conn) [Label::create $sqlclauseFrame.conn1 \
					-text Where -anchor w]
      grid configure $whereclauseelements(1,conn) -column 0 -row 1 -sticky we
      set whereclauseelements(1,field) \
		[ComboBox::create $sqlclauseFrame.field1 \
			-values $_fieldnames -text [lindex $_fieldnames 0] \
			-editable no]
      grid configure $whereclauseelements(1,field) -column 1 -row 1 -sticky we
      set whereclauseelements(1,op) \
		[ComboBox::create $sqlclauseFrame.op1 \
			-values $_compops -text [lindex $_compops 0] \
			-editable no]
      grid configure $whereclauseelements(1,op) -column 2 -row 1 -sticky we
      set whereclauseelements(1,value) \
		[Entry::create $sqlclauseFrame.value1 -editable yes -text {}]
      grid configure $whereclauseelements(1,value) -column 3 -row 1 -sticky we
      set whereclauseelements(1,add) \
		[Button::create $sqlclauseFrame.add1 -text + -command [mytypemethod _AddWhereRow 1]]
      grid configure $whereclauseelements(1,add) -column 4 -row 1 -sticky we
      set whereclauseelements(1,delete) \
		[Label::create $sqlclauseFrame.delete1 -text {-} -relief raised]
      grid configure $whereclauseelements(1,delete) -column 5 -row 1 -sticky we
      set _lastrowindex 1
    }
    typemethod _LastWhereRow {} {
      set rownum 0
      regsub {,field} [lindex [lsort -decreasing -dictionary [array names *,field whereclauseelements]] 0] {} rownum
      return $rownum
    }
    typemethod _AddWhereRow {currentRow} {
      set lastrow [$type _LastWhereRow]
      set newrowname [expr {$_lastrowindex + 1}]
      for {set j $lastrow} {$j > $currentRow} {incr j -1} {
	foreach w {conn field op value add delete} c {0 1 2 3 4 5} {
	  set jj [expr {$j + 1}]
	  set whereclauseelements($jj,$w) $whereclauseelements($j,$w)
	  unset $whereclauseelements($j,$w)
	  grid configure $whereclauseelements($jj,$w) -column $c -row $jj \
						      -sticky we
	}
      }
      set newrow [expr {$currentRow + 1}]
      set whereclauseelements($newrow,conn) \
		[ComboBox::create $sqlclauseFrame.conn$newrowname \
			-values $_connops -value [lindex $_connops 0] \
			-editable no]
      grid configure $whereclauseelements($newrow,conn) -column 0 -row $newrow -sticky we
      set whereclauseelements($newrow,field) \
		[ComboBox::create $sqlclauseFrame.field$newrowname \
			-values $_fieldnames -text [lindex $_fieldnames 0] \
			-editable no]
      grid configure $whereclauseelements($newrow,field) -column 1 -row $newrow -sticky we
      set whereclauseelements($newrow,op) \
		[ComboBox::create $sqlclauseFrame.op$newrowname \
			-values $_compops -text [lindex $_compops 0] \
			-editable no]
      grid configure $whereclauseelements($newrow,op) -column 2 -row $newrow -sticky we
      set whereclauseelements($newrow,value) \
		[Entry::create $sqlclauseFrame.value$newrowname -editable yes -text {}]
      grid configure $whereclauseelements($newrow,value) -column 3 -row $newrow -sticky we
      set whereclauseelements($newrow,add) \
		[Button::create $sqlclauseFrame.add$newrowname \
			-text + -command [mytypemethod _AddWhereRow $newrow]
      grid configure $whereclauseelements($newrow,add) -column 4 -row $newrow -sticky we
      set whereclauseelements($newrow,delete) \
		[Button::create $sqlclauseFrame.delete$newrowname \
			-text {-} -command [mytypemethod _DeleteWhereRow $newrow]
      grid configure $whereclauseelements($newrow,delete) -column 5 -row $newrow -sticky we
    }
    typemethod _DeleteWhereRow {currentRow} {
      set lastrow [$type _LastWhereRow]
      foreach w {conn field op value add delete} {
	grid forget $whereclauseelements($currentRow,$w)
        destroy $whereclauseelements($currentRow,$w)
        unset whereclauseelements($currentRow,$w)
      }
      for {set j [expr {$currentRow + 1}]} {$j <= $lastrow} {incr j} {
	foreach w {conn field op value add delete} c {0 1 2 3 4 5} {
	  set jj [expr {$j - 1}]
	  set whereclauseelements($jj,$w) $whereclauseelements($j,$w)
	  unset $whereclauseelements($j,$w)
	  grid configure $whereclauseelements($jj,$w) -column $c -row $jj \
						      -sticky we
	}
      }
    }
    SelectPrintDialog_typemethods {
      set defpapersize [from args -papersize 3x5]
      $paperSizeCB configure -text "$defpapersize"
      set defcardlayout [from args -cardlayout {}]
      $cardLayoutE configure -text "$defcardlayout"
      set defcardspagelayout [from args -cardspagelayout {1 0.0 1 0.0}]
      foreach {rows roff cols coff} $defcardspagelayout {
	$cardsPageLayoutRSB configure -text "$rows"
	$cardsPageLayoutRoffSB configure -text "$roff"
	$cardsPageLayoutCSB configure -text "$cols"
	$cardsPageLayoutCoffSB configure -text "$coff"
      }
      if {[from args -asksql no]} {
	catch "pack $sqlclauseFrame -expand yes -fill both"
      } else {
	catch "pack forget $sqlclauseFrame"
      }
    }
    typemethod _BrowseCardLayouts {} {
      set layoutname "[Print::CardLayout selectALayoutDialog \
				-parent $dialog -new no]"
      if {[string equal "$layoutname" {}]} {return}
      $cardLayoutE configure -text "$layoutname"
    }
    typemethod _BuildOneClause {index} {
      set field "[$whereclauseelements($index,field) cget -text]"
      set value "[$whereclauseelements($index,value) cget -text]"
      set op    "[$whereclauseelements($index,op) cget -text]"
      if {[string equal "$value" {}]} {
	return {}
      } else {
	switch -exact "$value" {
	  is {
	   return "$field = [Database::QuoteValue $value]"
	  }
	  {is not} {
	   return "$field != [Database::QuoteValue $value]"
	  }
	  {is like} {
	   return "$field like [Database::QuoteValue $value]"
	  }
	  {is not like} {
	   return "not ($field like [Database::QuoteValue $value])"
	  }
	  {greater than} {
	   return "$field > [Database::QuoteValue $value]"
	  }
	  {less than} {
	   return "$field < [Database::QuoteValue $value]"
	  }
	}
      }
    }
    typemethod _BuildWhereClause {} {
      set whereclause {}
      foreach conn [lsort -dictionary [array names whereclauseelements *,conn]] {
	regsub {,conn} $conn {} rowindex
	set clause [$type _BuildOneClause $rowindex]
        if {[string equal "$clause" {}]} {continue}
	if {[string equal "$whereclause" {}]} {
	  set whereclause "$clause"
	} else {
	  switch [$whereclauseelements($conn) cget -text] {
	    and {
		append whereclause " and $clause"
	    }
	    or {
		append whereclause " or $clause"
	    }
	  }
	}
      }
      return "$whereclause"
    }
    method _SelectPrinterDialog {args} {
      set asksql [from args -cardspagelayout "$options(-asksql)"]
      set button [$type _DrawSelectPrinterDialog \
			-parent [from args -parent .] \
			-papersize [from args -papersize "$options(-papersize)"] \
			-cardlayout [from args -cardlayout "$options(-cardlayout)"] \
			-cardspagelayout [from args -cardspagelayout "$options(-cardspagelayout)"] \
			-asksql $asksql]
      switch $button {
	ok {
		set options(-papersize) "[$paperSizeCB cget -text]"
		$self _ComputeSizes "$options(-papersize)"
		set options(-cardlayout) "[$cardLayoutE cget -text]"
		if {![string equal "$options(-cardlayout)" {}]} {
		  $c2p configure -layout [Print::CardLayout getLayoutByName \
							"$options(-cardlayout)"]
		}
		set options(-cardspagelayout) \
			[list [$cardsPageLayoutRSB cget -text] \
			      [$cardsPageLayoutRoffSB cget -text] \
			      [$cardsPageLayoutCSB cget -text] \
			      [$cardsPageLayoutCoffSB cget -text]]
		if {$asksql} {
		  set options(-searchwheresql) "[$type _BuildWhereClause]"
		  set options(-orderbycolumn)  "[$orderByLCB cget -text]"
		}
		return "$_PrinterPath"
	}
	cancel {return {}}
      }
    }
    method _ComputeSizes {papersize} {
      switch -- "papersize" {
	a4 {
		set _pagewidth 595
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 842
		set _textheight [expr {$_pageheight - 72}]
	}
	halfletter {
		set _pagewidth 396
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 612
		set _textheight [expr {$_pageheight - 72}]
	}	
	8.5x11 -
	letter {
		set _pagewidth 612
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 792
		set _textheight [expr {$_pageheight - 72}]
	}
	8.5x14 -
	legal {
		set _pagewidth 612
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 1008
		set _textheight [expr {$_pageheight - 72}]
	}
	3x5 {
		set _textwidth [expr {5 * 72}]
		set _textheight [expr {3 * 72}]
		set _pagewidth [expr {5 * 72}]
		set _pageheight [expr {3 * 72}]
	}
	5x8 {
		set _textwidth [expr {8 * 72}]
		set _textheight [expr {5 * 72}]
		set _pagewidth [expr {8 * 72}]
		set _pageheight [expr {5 * 72}]
	}
	default {
		set _pagewidth 612
		set _textwidth [expr {$_pagewidth - 72}]
		set _pageheight 792
		set _textheight [expr {$_pageheight - 72}]
	}
      }
      set _leftmargin [expr {double($_pagewidth - $_textwidth)/ 2.0}]
      set _topmargin [expr {$_pageheight - (double($_pageheight - $_textheight)/ 2.0)}]
    }
    method _CountCards {chan} {
      if {$_cardcount >= 0} {return $_cardcount}
      if {![string equal "$options(-key)" {}]} {
        if {[Database::GetCardByKey "$options(-key)" dummy]} {
	  set _cardcount 1
	} else {
	  set _cardcount 0
	}
      } else {
	set _cardcount [Database::CountMatchingCards \
					"$options(-searchwheresql)"]
      }
      return $_cardcount
    }
    method _StartCardDocument {chan} {
      $self _CountCards $chan
      set _rows [lindex $options(-cardspagelayout) 0]
      set _rowoff [lindex $options(-cardspagelayout) 1]
      set _cols [lindex $options(-cardspagelayout) 2]
      set _coloff [lindex $options(-cardspagelayout) 3]
      set cardsperpage [expr {$_rows * $_cols}]
      set _currow 0
      set _curcol 0
      set pages [expr {int(($_cardcount + ($cardsperpage - 1))/ $cardsperpage)}]
      if {[string equal "$options(-key)" {}]} {
	Database::StartWhereSelect "$options(-searchwheresql)" "$options(-orderbycolumn)"
      }
      puts $chan "%!PS-Adobe-2.0"
      puts $chan "%%Creator: PrintFunctions of HomeLibrarian. Copyright 2006 Robert Heller D/B/A Deepwoods Software."
      puts $chan "%%Title: $options(-pstitle)"
      puts $chan "%%CreationDate: [clock format [clock seconds]]"
      puts $chan "%%Pages: $pages"
      puts $chan "%%BoundingBox: 0 0 $_pagewidth $_pageheight"
      puts $chan "%%EndComments"
      puts $chan "%%BeginProlog"
      puts $chan "/EncapDict 200 dict def EncapDict begin"
      puts $chan "/showpage {} def /erasepage {} def /copypage {} def end"
      puts $chan "/BeginInclude {0 setgray 0 setlinecap 1 setlinewidth"
      puts $chan "0 setlinejoin 10 setmiterlimit \[\] 0 setdash"
      puts $chan "/languagelevel where {"
      puts $chan "  pop"
      puts $chan "  languagelevel 2 ge {"
      puts $chan "    false setoverprint"
      puts $chan "    false setstrokeadjust"
      puts $chan "  } if"
      puts $chan "} if"
      puts $chan "newpath"
      puts $chan "save EncapDict begin} def"
      puts $chan "/EndInclude {restore end} def"
      puts $chan "%%EndProlog"
      set _needshowpage false
    }
    method _PrintCard {chan} {
      incr _currentcard
      if {$_currentcard > $_cardcount} {return false}
      if {[string equal "$options(-key)" {}]} {
	if {![Database::NextCard row]} {return false}
	$c2p configure -key "$row(Key)"
      } else {
	$c2p configure -key "$options(-key)"
      }
      update idle
      if {$_currow < 1 || ($_currow >= $_rows && $_curcol >= $_cols)} {
	set _currow 1
	set _curcol 1
	set _rowoff [lindex $options(-cardspagelayout) 1]
	set _coloff [lindex $options(-cardspagelayout) 3]
	if {$_needshowpage} {puts $chan "showpage"}
	incr _currentpage
	set _needshowpage false
	puts $chan "%%Page: $_currentpage $_currentpage"
	if {$_rows == 1 && $_cols == 1} {
	  puts $chan "$_leftmargin $_topmargin translate"
	}
      } elseif {$_currow < $_rows} {
	incr _currow
	set _rowoff [expr {$_rowoff + [$c2p height]}]
      } elseif {$_currow == $_rows} {
	set _currow 1
	set _rowoff [lindex $options(-cardspagelayout) 1]
	incr _curcol
	set _coloff [expr {$_coloff + [$c2p width]}]
      }
      $hull setstatus "Printing card $_currentcard (on page $_currentpage)..."
      puts $chan "BeginInclude $_coloff $_rowoff translate"
      set postscript "[$c2p getps]"
      regsub -all -line {^%%(.*)$} "$postscript" {%#\1} postscript
      puts $chan "$postscript"
      puts $chan "EndInclude"
      set _needshowpage true
      return true
    }
    method _EndCardDocument {chan} {
      if {$_needshowpage} {puts $chan "showpage"}
      puts $chan "%%EOF"
    }
  }
}

proc Print::PrintText {text args} {
#  puts stderr "*** Print::PrintText '$text' $args"
  eval [list PrintTextProgress create .printText%AUTO% -text "$text"] $args
}

proc Print::PrintCard {key args} {
  eval [list PrintCardProgress create .printCard%AUTO% -key "$key" -asksql no] $args
}

proc Print::CardCatalog {args} {
  eval [list PrintCardProgress create .printCardCatalog%AUTO% -asksql yes] $args
}

proc Print::EditLayout {} {
  set layoutname [CardLayout selectALayoutDialog -new yes]
  if {[string equal "$layoutname" {}]} {return {}}
  set layout [CardLayout getLayoutByName $layoutname]
  if {[string equal "$layout" {}]} {
    if {[tk_messageBox -type yesno -icon question \
		-message "Layout not in cache, load from file?"]} {
      set filename [tk_getOpenFile -defaultextension ".lay" \
				   -title "File to load layout from" \
				   -filetypes [CardLayout layoutfiletypes]]
      if {[string equal "$filename" {}]} {return}
      set layoutname [CardLayout loadFromFile "$filename"]
      if {[string equal "$layoutname" {}]} {return {}}
    } else {
      regsub -all {[[:space:]]} "$layoutname" {_} layoutname
      CardLayout create $layoutname
    }
    set layout [CardLayout getLayoutByName $layoutname]
  }
  $layout edit
}

package provide PrintFunctions 1.0
