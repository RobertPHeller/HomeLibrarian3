#* 
#* ------------------------------------------------------------------
#* AnimatedHeader.tcl - Animated Header widget
#* Created by Robert Heller on Mon Sep 11 18:25:28 2006
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

package require BWidget
package require snit

namespace eval AnimatedHeader {
  snit::widget AnimatedHeader {
    widgetclass AnimatedHeader
    typeconstructor {
      global imageDir
      image create photo AnimatedHeader::cabEnd -file [file join "$imageDir" base.gif]
      image create photo AnimatedHeader::cardsMiddle -file [file join "$imageDir" finger.gif]
      image create photo AnimatedHeader::handleEnd -file [file join "$imageDir" handle.gif]
      image create photo AnimatedHeader::cardsLeft -file [file join "$imageDir" left.gif]
      image create photo AnimatedHeader::cardsRight -file [file join "$imageDir" right.gif]
      image create photo AnimatedHeader::LargeFace -file [file join "$imageDir" ffront.gif]
      image create photo AnimatedHeader::LargeProfile -file [file join "$imageDir" fside.gif]
    }
    variable _WorkingAfterId {}
    variable _WorkingIndex -1
    typevariable _ReverseWorkIndex -array {
	36 1
	35 2
	34 3
	33 4
	32 5
	31 6
	30 7
	29 8
	28 9
	27 10
	26 11
	25 12
	24 13
	23 14
	22 15
	21 16
	20 17
	19 18

	38 36
	39 35
	40 34
	41 33
	42 32
	43 31
	44 30
	45 29
	46 28
	47 27
	48 26
	49 25
	50 24
	51 23
	52 22
	53 21
	54 20
    }       
    component face
    component cf
    component workCanvas
    component fill
    method _Working {{worktime 100}} {
#      puts stderr "*** _Working $worktime"
      set width [$workCanvas cget -width]
#      puts stderr "*** _Working: width =  $width, _WorkingIndex = $_WorkingIndex"
      switch -exact $_WorkingIndex {
	 0 {
	  # start up index.  Clear out the canvas and then display a closed
	  # drawer.
	  $workCanvas delete all
	  $workCanvas create image [expr $width - 20] 0 -image AnimatedHeader::cabEnd -anchor nw -tag CabEnd
	  $workCanvas create image [expr $width - 40] 0 -image AnimatedHeader::handleEnd -anchor nw -tag Handle
	}
	 1 -
	 2 -
	 3 -
	 4 -
	 5 -
	 6 -
	 7 -
	 8 -
	 9 -
	10 -
	11 -
	12 -
	13 -
	14 -
	15 -
	16 -
	17 -
	18 {
	  # Phase one: open the drawer, full of cards leaning to the right.
	  $workCanvas move Handle -20 0
	  set offset [expr $width - (($_WorkingIndex * 20) + 20)]
	  $workCanvas create image $offset 0 -image AnimatedHeader::cardsRight -anchor nw -tag "CardsRight Batch$_WorkingIndex"
	}
	19 -
	20 -
	21 -
	22 -
	23 -
	24 -
	25 -
	26 -
	27 -
	28 -
	29 -
	30 -
	31 -
	32 -
	33 -
	34 -
	35 -
	36 {
	  # Phase two: flip the cards to the left, one by one.
	  set x $_ReverseWorkIndex($_WorkingIndex)
	  set index "[$workCanvas find withtag CardsMiddle]"
	  if {[llength "$index"] > 0} {
	    $workCanvas itemconfigure $index -image AnimatedHeader::cardsLeft -tags "CardsLeft Batch$_WorkingIndex"
	  }
	  set index [$workCanvas find withtag "Batch$x"]
	  $workCanvas itemconfigure $index -image AnimatedHeader::cardsMiddle -tags CardsMiddle
	}
	37 {
	  # Phase three: delete the middle card and start closing the drawer.
	  $workCanvas delete CardsMiddle
	  $workCanvas move CardsLeft +20 0
	  $workCanvas move Handle +20 0
	} 
	38 -
	39 -
	40 -
	41 -
	42 -
	43 -
	44 -
	45 -
	46 -
	47 -
	48 -
	49 -
	50 -
	51 -
	52 -
	53 -
	54 {
	  # Phase four: close the drawer.
	  $workCanvas delete Batch$_ReverseWorkIndex($_WorkingIndex)
	  $workCanvas move CardsLeft +20 0
	  $workCanvas move Handle +20 0
	}
      }
      incr _WorkingIndex
      if {$_WorkingIndex > 54} {set _WorkingIndex 1}
      if {$worktime > 0} {
	set _WorkingAfterId [after $worktime [mymethod _Working $worktime]]
      } else {
        update
      }
    }
    method StartWorking {{worktime 100}} {
      set _WorkingIndex 0
      grab set $workCanvas
      $face configure -image {AnimatedHeader::LargeProfile}
      $self _Working $worktime
    }
    method EndWorking {{message {How May I Help You?}}} {
      catch "after cancel $_WorkingAfterId"
      set _WorkingAfterId {}
      $workCanvas delete all
      $workCanvas create rectangle 0 0 \
	[$workCanvas cget -width] [$workCanvas cget -height] \
	-fill yellow -outline {}
      $self _CenterText $workCanvas 28 brown "$message"
      $face configure -image {AnimatedHeader::LargeFace}
      set cg "[grab current]"
      foreach gw $cg {
	grab release $gw
      }
    }
    method _CenterText {W Size Color Text {tag Message}} {
      if {[lsearch -exact [font families] {new century schoolbook}] >= 0} {
	set font [list {new century schoolbook} [expr {0 - $Size}] bold italic]
      } else {
	set font [list times  [expr {0 - $Size}] bold italic]
      }
      set CX [expr [$W cget -width] / 2.0]
      set CY [expr [$W cget -height] / 2.0]
      set x [$W create text $CX $CY -width [$W cget -width] -anchor center \
			-font "$font" -fill "$Color" -text "$Text" -tag $tag]
      return $x
    }
    method SetMessage {text} {
      $workCanvas delete all
      $workCanvas create rectangle 0 0 \
	[$workCanvas cget -width] [$workCanvas cget -height] \
	-fill yellow -outline {}
      $self _CenterText $workCanvas 28 brown "$text"
    }	
    constructor {args} {
      install face using label $win.face -borderwidth 4 -height 100 \
					 -relief ridge -highlightthickness 0 \
					 -image AnimatedHeader::LargeFace \
					 -width 100
      pack $win.face -side left
      install cf using frame $win.cf -borderwidth 4 -relief ridge \
				     -highlightthickness 0
      pack $win.cf -side right -expand yes -fill x
      install workCanvas using canvas $win.cf.workCanvas -borderwidth 0 \
							 -height 100 \
							 -relief flat \
							 -highlightthickness 0 \
							 -selectborderwidth 0 \
							 -width 400 \
							 -background white
      pack $win.cf.workCanvas -side left
      install fill using label $win.cf.fill -relief flat -background yellow \
					    -text {}
      pack $win.cf.fill -side right -expand 1 -fill both
      #$self configurelist $args
      $workCanvas create rectangle 0 0 \
		[$workCanvas cget -width] [$workCanvas cget -height] \
        -fill yellow -outline {}
      $self _CenterText $workCanvas 28 brown "How May I Help You?"
    }
  }
}












package provide AnimatedHeader 1.0
