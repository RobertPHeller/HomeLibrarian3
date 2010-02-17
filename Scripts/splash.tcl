#* 
#* ------------------------------------------------------------------
#* splash.tcl - General purpose splash window
#* Created by Robert Heller on Mon Feb 27 13:13:31 2006
#* ------------------------------------------------------------------
#* Modification History: $Log: splash.tcl,v $
#* Modification History: Revision 1.1.1.1  2006/11/02 19:55:53  heller
#* Modification History: Imported Sources
#* Modification History:
#* Modification History: Revision 1.1  2006/06/02 02:39:49  heller
#* Modification History: Mostly Done!
#* Modification History:
#* Modification History: Revision 1.2  2006/05/16 19:27:46  heller
#* Modification History: May162006 Lockdown
#* Modification History:
#* Modification History: Revision 1.1  2006/03/06 18:46:20  heller
#* Modification History: March 6 lockdown
#* Modification History:
#* Modification History: Revision 1.1  2002/07/28 14:03:50  heller
#* Modification History: Add it copyright notice headers
#* Modification History:
#* ------------------------------------------------------------------
#* Contents:
#* ------------------------------------------------------------------
#*  
#*     Model RR System, Version 2
#*     Copyright (C) 1994,1995,2002-2005  Robert Heller D/B/A Deepwoods Software
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

# $Id$

package require snit
package require BWidget

snit::widget splash {
  hulltype toplevel

  component image
  component progressBar
  component title
  component icon
  component status
  component header

  delegate option -troughcolor to progressBar
  delegate option {-titleforeground foreground Foreground} to title as -foreground
  delegate option {-statusforeground foreground Foreground} to status as -foreground
  variable  currentProgress 0

  option {-background background Background} \
		-default #d9d9d9 \
		-readonly yes \
		-validatemethod CheckColor
  method CheckColor {option value} {
    if {[catch [list winfo rgb $win $value] message]} {
      error "Option $option must have a legal color value.  Got $value"
    }
  }

  option {-progressbar progressBar ProgressBar} \
		-default yes \
		-readonly yes \
		-validatemethod CheckBoolean
  method CheckBoolean {option value} {
    if {![string is boolean -strict $value]} {
      error "Option $option must have a boolean value.  Got $value."
    }
  }
  option {-image image Image} \
	-default {} \
	-readonly yes \
	-validatemethod CheckImage
  option {-icon icon Icon} \
	-default {} \
	-readonly yes \
	-validatemethod CheckImage
  method CheckImage {option value} {
    if {[string equal "$value" {}]} {
      return
    } elseif {[lsearch -exact [image names] "$value"] < 0} {
       error "Option $option must have a valid image (or be empty for none).  Got $value."
    }
  }
  option {-title title Title} \
	-default {} \
	-readonly yes

  method update {statusMessage percentDone} {
    $status configure -text "$statusMessage"
    set currentProgress $percentDone
    if {$percentDone >= 100} {$self enableClickDestroy}
  }

  method enableClickDestroy {} {
    wm protocol $win WM_DELETE_WINDOW {}
    bind $win <1> "destroy $win"
  }

  method hide {} {
    wm withdraw $win
  }

  method show {} {
    wm deiconify $win
  }

  constructor {args} {
    set header $win.header
    set icon $header.icon
    set title $header.title
    set image $win.image
    set progressBar $win.progressBar
    set status $win.status
    wm withdraw $win
    wm overrideredirect $win yes
    wm protocol $win WM_DELETE_WINDOW {break}

    frame $header -relief ridge -borderwidth 5
    label $icon
    message $title \
		-aspect {800} \
		-font {Times -10 roman}
    label $image
    ProgressBar $progressBar \
			-type normal \
			-height 20 \
			-maximum 100 \
			-variable [myvar currentProgress]
    set currentProgress 0
    message $status \
	-aspect {800} \
	-font   {Times -10 roman} \
	-text	{} \
	-background $options(-background) \
	-width  [winfo reqwidth $image]
    $self configurelist $args
    foreach w [list $header $title $progressBar $status] {
      catch [list $w configure -background $options(-background)]
    }
    if {[string length "$options(-icon)"] || [string length "$options(-title)"]} {
      pack $header -fill x -expand yes
      if {[string length "$options(-icon)"]} {
	$icon configure -image "$options(-icon)"
	pack $icon -side left
      }
      if {[string length "$options(-title)"]} {
	$title configure -text "$options(-title)"
	pack $title -side right -fill both -expand yes
      }
    }
    if {[string length "$options(-image)"]} {
      $image configure -image "$options(-image)"
      pack $image
    }
    if {$options(-progressbar)} {
      pack $progressBar -fill x
    }
    update idle
    $status configure -width [winfo reqwidth $image]
    pack $status -fill x
    update idle
    set w [winfo reqwidth $win]
    set h [winfo reqheight $win]
    set sw [winfo screenwidth $win]
    set sh [winfo screenheight $win]
    set rx [winfo rootx $win]
    set ry [winfo rooty $win]
    set xx [expr int($rx + (double($sw-$w) / 2.0) + .5)]
    set yy [expr int($ry + (double($sh-$h) / 2.0) + .5)]
    if {[expr $xx + $rx] > $sw} {set xx [expr $sw - $w]}
    if {[expr $yy + $ry] > $sh} {set yy [expr $sh - $h]}
    if {$xx < 0} {set xx 0}
    if {$yy < 0} {set yy 0}
    wm geom $win +$xx+$yy
    wm deiconify $win
  }
}

package provide Splash 1.0
