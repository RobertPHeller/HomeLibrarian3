#* 
#* ------------------------------------------------------------------
#* SearchWindow.tcl - Search pane
#* Created by Robert Heller on Wed Sep 13 13:28:43 2006
#* ------------------------------------------------------------------
#* Modification History: $Log: SearchWindow.tcl,v $
#* Modification History: Revision 1.1.1.1  2006/11/02 19:55:53  heller
#* Modification History: Imported Sources
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
package require MainWindow
package require DWpanedw

namespace eval Search {
  variable MainSearchFrame {}
  variable MainSearchNoteBook {}
} 

proc Search::SearchPane {} {
  variable MainSearchNoteBook
  variable MainSearchFrame
  variable ::Windows::Manager
  variable ::Windows::MainButtons

  set sf [$Manager add search]
  set sfpaneW [PanedWindow::create $sf.sfpaneW -side right]
  pack $sfpaneW -expand yes -fill both
  set search [$sfpaneW add -weight 1 -name search]
  pack [Database::SearchFrame $search.searchframe -resultlbheight 3 \
						  -selectmode multiple] \
	-expand yes -fill both
  set MainSearchFrame $search.searchframe
  $MainSearchFrame buttons add -name addNote -text "Add To Notepad" \
			 -command Search::AddSelectionToNotes
  $MainSearchFrame buttons add -name displayMore -text "Display More Information" \
			 -command Search::DisplayMoreInfo
  update idle
  $sfpaneW paneconfigure search -minsize [winfo reqheight $search]
  set notes [$sfpaneW add -weight 1 -name notes]
  pack [ScrolledWindow::create $notes.notescroll -auto both -scrollbar both] \
	-expand yes -fill both
  set MainSearchNoteBook $notes.notescroll.notes
  pack [text $MainSearchNoteBook -height 3 -width 40] -expand yes -fill both
  $notes.notescroll setwidget $MainSearchNoteBook
  set notebookbb [ButtonBox::create $notes.notebookbb -orient horizontal \
		    -homogeneous no]
  pack $notebookbb -fill x
  $notebookbb add -name print -text {Print Notepad} \
		  -command {Print::PrintText \
				"[$Search::MainSearchNoteBook get 1.0 end-1c]" \
				-title "Printing notebook" \
				-pstitle "Home Librarian Search Notebook"}
  $notebookbb add -name save -text {Save Notepad} \
		  -command Search::SaveNoteBook
  $notebookbb add -name clear -text {Clear Notepad} \
		  -command {$Search::MainSearchNoteBook delete 1.0 end}
  update idle
  $sfpaneW paneconfigure notes -minsize [winfo reqheight $notes]
  pack [Button::create $sf.returnbutton -text {Return To Main} \
	 -command "$Windows::AnimatedHeader SetMessage {How May I Help You?};$Manager raise main"] -fill x
#  puts stderr "*** Search::SearchPane: search added"
  $MainButtons add -name search -text "Search Library" \
			      -font {Helvetica -34 bold roman} \
			      -background {yellow} -activeforeground {yellow} \
			      -foreground {brown} -activebackground {brown} \
			      -command "$Manager raise search" -state disabled
  if {[Database::HaveData]} {
    $MainButtons itemconfigure search -state normal
  }
}

proc Search::SearchResultsSelected {selection} {
  variable MainSearchButtons
  $MainSearchButtons configure -state normal
}

proc Search::AddSelectionToNotes {} {
  variable MainSearchFrame
  variable MainSearchNoteBook
  set items [$MainSearchFrame listbox selection get]
  if {[llength $items] < 1} {return}
  foreach item $items {
    $MainSearchNoteBook insert end "[$MainSearchFrame listbox itemcget $item -text]\n"
  }
}

snit::widgetadaptor rotext {
  typeconstructor {
    global tk_patchLevel
    global tcl_platform
    if {[package vcompare $tk_patchLevel 8.4.0] < 0} {
	# 8.3 or earlier
	bind ROText <1> {
	  tkTextButton1 %W %x %y
	  %W tag remove sel 0.0 end
	}
	bind ROText <B1-Motion> {
	  set tkPriv(x) %x
	  set tkPriv(y) %y
	  tkTextSelectTo %W %x %y
	}
	bind ROText <Double-1> {
	  set tkPriv(selectMode) word
	  tkTextSelectTo %W %x %y
	  catch {%W mark set insert sel.last}
	  catch {%W mark set anchor sel.first}
	}
	bind ROText <Triple-1> {
	  set tkPriv(selectMode) line
	  tkTextSelectTo %W %x %y
	  catch {%W mark set insert sel.last}
	  catch {%W mark set anchor sel.first}
	}
	bind ROText <Shift-1> {
	  tkTextResetAnchor %W @%x,%y
	  set tkPriv(selectMode) char
	  tkTextSelectTo %W %x %y
	}
	bind ROText <Double-Shift-1>      {
	  set tkPriv(selectMode) word
	  tkTextSelectTo %W %x %y 1
	}
	bind ROText <Triple-Shift-1>      {
	  set tkPriv(selectMode) line
	  tkTextSelectTo %W %x %y
	}
	bind ROText <B1-Leave> {
	  set tkPriv(x) %x
	  set tkPriv(y) %y
	  tkTextAutoScan %W
	}
	bind ROText <B1-Enter> {
	  tkCancelRepeat
	}
	bind ROText <ButtonRelease-1> {
	  tkCancelRepeat
	}
	bind ROText <Control-1> {
	  %W mark set insert @%x,%y
	}
	bind ROText <Left> {
	  tkTextSetCursor %W insert-1c
	}
	bind ROText <Right> {
	  tkTextSetCursor %W insert+1c
	}
	bind ROText <Up> {
	  tkTextSetCursor %W [tkTextUpDownLine %W -1]
	}
	bind ROText <Down> {
	  tkTextSetCursor %W [tkTextUpDownLine %W 1]
	}
	bind ROText <Shift-Left> {
	  tkTextKeySelect %W [%W index {insert - 1c}]
	}
	bind ROText <Shift-Right> {
	  tkTextKeySelect %W [%W index {insert + 1c}]
	}
	bind ROText <Shift-Up> {
	  tkTextKeySelect %W [tkTextUpDownLine %W -1]
	}
	bind ROText <Shift-Down> {
	  tkTextKeySelect %W [tkTextUpDownLine %W 1]
	}
	bind ROText <Control-Left> {
	  tkTextSetCursor %W [tkTextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Control-Right> {
	  tkTextSetCursor %W [tkTextNextWord %W insert]
	}
	bind ROText <Control-Up> {
	  tkTextSetCursor %W [tkTextPrevPara %W insert]
	}
	bind ROText <Control-Down> {
	  tkTextSetCursor %W [tkTextNextPara %W insert]
	}
	bind ROText <Shift-Control-Left> {
	  tkTextKeySelect %W [tkTextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Shift-Control-Right> {
	  tkTextKeySelect %W [tkTextNextWord %W insert]
	}
	bind ROText <Shift-Control-Up> {
	  tkTextKeySelect %W [tkTextPrevPara %W insert]
	}
	bind ROText <Shift-Control-Down> {
	  tkTextKeySelect %W [tkTextNextPara %W insert]
	}
	bind ROText <Prior> {
	  tkTextSetCursor %W [tkTextScrollPages %W -1]
	}
	bind ROText <Shift-Prior> {
	  tkTextKeySelect %W [tkTextScrollPages %W -1]
	}
	bind ROText <Next> {
	  tkTextSetCursor %W [tkTextScrollPages %W 1]
	}
	bind ROText <Shift-Next> {
	  tkTextKeySelect %W [tkTextScrollPages %W 1]
	}
	bind ROText <Control-Prior> {
	  %W xview scroll -1 page
	}
	bind ROText <Control-Next> {
	  %W xview scroll 1 page
	}

	bind ROText <Home> {
	  tkTextSetCursor %W {insert linestart}
	}
	bind ROText <Shift-Home> {
	  tkTextKeySelect %W {insert linestart}
	}
	bind ROText <End> {
	  tkTextSetCursor %W {insert lineend}
	}
	bind ROText <Shift-End> {
	  tkTextKeySelect %W {insert lineend}
	}
	bind ROText <Control-Home> {
	  tkTextSetCursor %W 1.0
	}
	bind ROText <Control-Shift-Home> {
	  tkTextKeySelect %W 1.0
	}
	bind ROText <Control-End> {
	  tkTextSetCursor %W {end - 1 char}
	}
	bind ROText <Control-Shift-End> {
	  tkTextKeySelect %W {end - 1 char}
	}
	bind ROText <Control-Tab> {
	  focus [tk_focusNext %W]
	}
	bind ROText <Control-Shift-Tab> {
	  focus [tk_focusPrev %W]
	}
	bind ROText <Select> {
	  %W mark set anchor insert
	}
	bind ROText <Control-Shift-space> {
	  set tkPriv(selectMode) char
	  tkTextKeyExtend %W insert
	}
	bind ROText <Shift-Select> {
	  set tkPriv(selectMode) char
	  tkTextKeyExtend %W insert
	}
	bind ROText <Control-slash> {
	  %W tag add sel 1.0 end
	}
	bind ROText <Control-backslash> {
	  %W tag remove sel 1.0 end
	}
	bind ROText <<Copy>> {
	  tk_textCopy %W
	}
	bind ROText <<Clear>> {
	  catch {%W delete sel.first sel.last}
	}

	# Additional emacs-like bindings:

	bind ROText <Control-a> {
	  if {!$tk_strictMotif} {
	    tkTextSetCursor %W {insert linestart}
	  }
	}
	bind ROText <Control-b> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W insert-1c
	    }
	}
	bind ROText <Control-e> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W {insert lineend}
	    }
	}
	bind ROText <Control-f> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W insert+1c
	    }
	}
	bind ROText <Control-n> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W [tkTextUpDownLine %W 1]
	    }
	}
	bind ROText <Control-p> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W [tkTextUpDownLine %W -1]
	    }
	}
	if {[string compare $tcl_platform(platform) "windows"]} {
	bind ROText <Control-v> {
	    if {!$tk_strictMotif} {
	        tkTextScrollPages %W 1
	    }
	}
	}


	bind ROText <Meta-b> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W [tkTextPrevPos %W insert tcl_startOfPreviousWord]
	    }
	}
	bind ROText <Meta-f> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W [tkTextNextWord %W insert]
	    }
	}
	bind ROText <Meta-less> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W 1.0
	    }
	}
	bind ROText <Meta-greater> {
	    if {!$tk_strictMotif} {
	        tkTextSetCursor %W end-1c
	    }
	}

	# Macintosh only bindings:

	# if text black & highlight black -> text white, other text the same
	if {[string equal $tcl_platform(platform) "macintosh"]} {
	bind ROText <FocusIn> {
	    %W tag configure sel -borderwidth 0
	    %W configure -selectbackground systemHighlight -selectforeground systemHighlightText
	}
	bind ROText <FocusOut> {
	    %W tag configure sel -borderwidth 1
	    %W configure -selectbackground white -selectforeground black
	}
	bind ROText <Option-Left> {
	    tkTextSetCursor %W [tkTextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Option-Right> {
	    tkTextSetCursor %W [tkTextNextWord %W insert]
	}
	bind ROText <Option-Up> {
	    tkTextSetCursor %W [tkTextPrevPara %W insert]
	}
	bind ROText <Option-Down> {
	    tkTextSetCursor %W [tkTextNextPara %W insert]
	}
	bind ROText <Shift-Option-Left> {
	    tkTextKeySelect %W [tkTextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Shift-Option-Right> {
	    tkTextKeySelect %W [tkTextNextWord %W insert]
	}
	bind ROText <Shift-Option-Up> {
	    tkTextKeySelect %W [tkTextPrevPara %W insert]
	}
	bind ROText <Shift-Option-Down> {
	    tkTextKeySelect %W [tkTextNextPara %W insert]
	}
	
	# End of Mac only bindings
	}
	bind ROText <B2-Motion> {
	    if {!$tk_strictMotif} {
	        if {(%x != $tkPriv(x)) || (%y != $tkPriv(y))} {
	            set tkPriv(mouseMoved) 1
	        }
	        if {$tkPriv(mouseMoved)} {
	            %W scan dragto %x %y
	        }
	    }
	}

	# The MouseWheel will typically only fire on Windows.  However,
	# someone could use the "event generate" command to produce one
	# on other platforms.

	bind ROText <MouseWheel> {
	    %W yview scroll [expr {- (%D / 120) * 4}] units
	}

	if {[string equal "unix" $tcl_platform(platform)]} {
	    # Support for mousewheels on Linux/Unix commonly comes through mapping
	    # the wheel to the extended buttons.  If you have a mousewheel, find
	    # Linux configuration info at:
	    #   http://www.inria.fr/koala/colas/mouse-wheel-scroll/
	    bind ROText <4> {
	        if {!$tk_strictMotif} {
	            %W yview scroll -5 units
	        }
	    }
	    bind ROText <5> {
	        if {!$tk_strictMotif} {
	            %W yview scroll 5 units
	        }
	    }
	}
    } else {
	# 8.4 or later
	# Standard Motif bindings:

	bind ROText <1> {
	    tk::TextButton1 %W %x %y
	    %W tag remove sel 0.0 end
	}
	bind ROText <B1-Motion> {
	    set tk::Priv(x) %x
	    set tk::Priv(y) %y
	    tk::TextSelectTo %W %x %y
	}
	bind ROText <Double-1> {
	    set tk::Priv(selectMode) word
	    tk::TextSelectTo %W %x %y
	    catch {%W mark set insert sel.last}
	}
	bind ROText <Triple-1> {
	    set tk::Priv(selectMode) line
	    tk::TextSelectTo %W %x %y
	    catch {%W mark set insert sel.last}
	}
	bind ROText <Shift-1> {
	    tk::TextResetAnchor %W @%x,%y
	    set tk::Priv(selectMode) char
	    tk::TextSelectTo %W %x %y
	}
	bind ROText <Double-Shift-1>	{
	    set tk::Priv(selectMode) word
	    tk::TextSelectTo %W %x %y 1
	}
	bind ROText <Triple-Shift-1>	{
	    set tk::Priv(selectMode) line
	    tk::TextSelectTo %W %x %y
	}
	bind ROText <B1-Leave> {
	    set tk::Priv(x) %x
	    set tk::Priv(y) %y
	    tk::TextAutoScan %W
	}
	bind ROText <B1-Enter> {
	    tk::CancelRepeat
	}
	bind ROText <ButtonRelease-1> {
	    tk::CancelRepeat
	}
	bind ROText <Control-1> {
	    %W mark set insert @%x,%y
	}
	bind ROText <Left> {
	    tk::TextSetCursor %W insert-1c
	}
	bind ROText <Right> {
	    tk::TextSetCursor %W insert+1c
	}
	bind ROText <Up> {
	    tk::TextSetCursor %W [tk::TextUpDownLine %W -1]
	}
	bind ROText <Down> {
	    tk::TextSetCursor %W [tk::TextUpDownLine %W 1]
	}
	bind ROText <Shift-Left> {
	    tk::TextKeySelect %W [%W index {insert - 1c}]
	}
	bind ROText <Shift-Right> {
	    tk::TextKeySelect %W [%W index {insert + 1c}]
	}
	bind ROText <Shift-Up> {
	    tk::TextKeySelect %W [tk::TextUpDownLine %W -1]
	}
	bind ROText <Shift-Down> {
	    tk::TextKeySelect %W [tk::TextUpDownLine %W 1]
	}
	bind ROText <Control-Left> {
	    tk::TextSetCursor %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Control-Right> {
	    tk::TextSetCursor %W [tk::TextNextWord %W insert]
	}
	bind ROText <Control-Up> {
	    tk::TextSetCursor %W [tk::TextPrevPara %W insert]
	}
	bind ROText <Control-Down> {
	    tk::TextSetCursor %W [tk::TextNextPara %W insert]
	}
	bind ROText <Shift-Control-Left> {
	    tk::TextKeySelect %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Shift-Control-Right> {
	    tk::TextKeySelect %W [tk::TextNextWord %W insert]
	}
	bind ROText <Shift-Control-Up> {
	    tk::TextKeySelect %W [tk::TextPrevPara %W insert]
	}
	bind ROText <Shift-Control-Down> {
	    tk::TextKeySelect %W [tk::TextNextPara %W insert]
	}
	bind ROText <Prior> {
	    tk::TextSetCursor %W [tk::TextScrollPages %W -1]
	}
	bind ROText <Shift-Prior> {
	    tk::TextKeySelect %W [tk::TextScrollPages %W -1]
	}
	bind ROText <Next> {
	    tk::TextSetCursor %W [tk::TextScrollPages %W 1]
	}
	bind ROText <Shift-Next> {
	    tk::TextKeySelect %W [tk::TextScrollPages %W 1]
	}
	bind ROText <Control-Prior> {
	    %W xview scroll -1 page
	}
	bind ROText <Control-Next> {
	    %W xview scroll 1 page
	}
	
	bind ROText <Home> {
	    tk::TextSetCursor %W {insert linestart}
	}
	bind ROText <Shift-Home> {
	    tk::TextKeySelect %W {insert linestart}
	}
	bind ROText <End> {
	    tk::TextSetCursor %W {insert lineend}
	}
	bind ROText <Shift-End> {
	    tk::TextKeySelect %W {insert lineend}
	}
	bind ROText <Control-Home> {
	    tk::TextSetCursor %W 1.0
	}
	bind ROText <Control-Shift-Home> {
	    tk::TextKeySelect %W 1.0
	}
	bind ROText <Control-End> {
	    tk::TextSetCursor %W {end - 1 char}
	}
	bind ROText <Control-Shift-End> {
	    tk::TextKeySelect %W {end - 1 char}
	}
	bind ROText <Control-Tab> {
	    focus [tk_focusNext %W]
	}
	bind ROText <Control-Shift-Tab> {
	    focus [tk_focusPrev %W]
	}

	bind ROText <Control-space> {
	    %W mark set anchor insert
	}
	bind ROText <Select> {
	    %W mark set anchor insert
	}
	bind ROText <Control-Shift-space> {
	    set tk::Priv(selectMode) char
	    tk::TextKeyExtend %W insert
	}
	bind ROText <Shift-Select> {
	    set tk::Priv(selectMode) char
	    tk::TextKeyExtend %W insert
	}
	bind ROText <Control-slash> {
	    %W tag add sel 1.0 end
	}
	bind ROText <Control-backslash> {
	    %W tag remove sel 1.0 end
	}
	bind ROText <<Copy>> {
	    tk_textCopy %W
	}
	bind ROText <<Clear>> {
	    catch {%W delete sel.first sel.last}
	}


	# Additional emacs-like bindings:

	bind ROText <Control-a> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W {insert linestart}
	    }
	}
	bind ROText <Control-b> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W insert-1c
	    }
	}
	bind ROText <Control-e> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W {insert lineend}
	    }
	}
	bind ROText <Control-f> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W insert+1c
	    }
	}
	bind ROText <Control-n> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W [tk::TextUpDownLine %W 1]
	    }
	}
	bind ROText <Control-p> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W [tk::TextUpDownLine %W -1]
	    }
	}

	if {[string compare $tcl_platform(platform) "windows"]} {
	bind ROText <Control-v> {
	    if {!$tk_strictMotif} {
		tk::TextScrollPages %W 1
	    }
	}
	}

	bind ROText <Meta-b> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
	    }
	}
	bind ROText <Meta-f> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W [tk::TextNextWord %W insert]
	    }
	}
	bind ROText <Meta-less> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W 1.0
	    }
	}
	bind ROText <Meta-greater> {
	    if {!$tk_strictMotif} {
		tk::TextSetCursor %W end-1c
	    }
	}

	# Macintosh only bindings:
	
	# if text black & highlight black -> text white, other text the same
	if {[string equal [tk windowingsystem] "classic"]
		|| [string equal [tk windowingsystem] "aqua"]} {
	bind ROText <FocusIn> {
	    %W tag configure sel -borderwidth 0
	    %W configure -selectbackground systemHighlight -selectforeground systemHighlightText
	}
	bind ROText <FocusOut> {
	    %W tag configure sel -borderwidth 1
	    %W configure -selectbackground white -selectforeground black
	}
	bind ROText <Option-Left> {
	    tk::TextSetCursor %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Option-Right> {
	    tk::TextSetCursor %W [tk::TextNextWord %W insert]
	}
	bind ROText <Option-Up> {
	    tk::TextSetCursor %W [tk::TextPrevPara %W insert]
	}
	bind ROText <Option-Down> {
	    tk::TextSetCursor %W [tk::TextNextPara %W insert]
	}
	bind ROText <Shift-Option-Left> {
	    tk::TextKeySelect %W [tk::TextPrevPos %W insert tcl_startOfPreviousWord]
	}
	bind ROText <Shift-Option-Right> {
	    tk::TextKeySelect %W [tk::TextNextWord %W insert]
	}
	bind ROText <Shift-Option-Up> {
	    tk::TextKeySelect %W [tk::TextPrevPara %W insert]
	}
	bind ROText <Shift-Option-Down> {
	    tk::TextKeySelect %W [tk::TextNextPara %W insert]
	}

	# End of Mac only bindings
	}

	# A few additional bindings of my own.

	bind ROText <2> {
	    if {!$tk_strictMotif} {
		tk::TextScanMark %W %x %y
	    }
	}
	bind ROText <B2-Motion> {
	    if {!$tk_strictMotif} {
		tk::TextScanDrag %W %x %y
	    }
	}

	# The MouseWheel will typically only fire on Windows.  However,
	# someone could use the "event generate" command to produce one
	# on other platforms.

	if {[string equal [tk windowingsystem] "classic"]
		|| [string equal [tk windowingsystem] "aqua"]} {
	    bind ROText <MouseWheel> {
	        %W yview scroll [expr {- (%D)}] units
	    }
	    bind ROText <Option-MouseWheel> {
	        %W yview scroll [expr {-10 * (%D)}] units
	    }
	    bind ROText <Shift-MouseWheel> {
	        %W xview scroll [expr {- (%D)}] units
	    }
	    bind ROText <Shift-Option-MouseWheel> {
	        %W xview scroll [expr {-10 * (%D)}] units
	    }
	} else {
	    bind ROText <MouseWheel> {
	        %W yview scroll [expr {- (%D / 120) * 4}] units
	    }
	}

	if {[string equal "x11" [tk windowingsystem]]} {
	    # Support for mousewheels on Linux/Unix commonly comes through mapping
	    # the wheel to the extended buttons.  If you have a mousewheel, find
	    # Linux configuration info at:
	    #	http://www.inria.fr/koala/colas/mouse-wheel-scroll/
	    bind ROText <4> {
		if {!$tk_strictMotif} {
		    %W yview scroll -5 units
		}
	    }
	    bind ROText <5> {
		if {!$tk_strictMotif} {
		    %W yview scroll 5 units
		}
	    }
	}
    }
  }
  delegate option * to hull
  delegate method * to hull
  constructor {args} {
    installhull using text
    set bindtags [bindtags $win]
    regsub Text "$bindtags" ROText bindtags
    bindtags $win $bindtags
    $self configurelist $args
  }
}

proc Search::DisplayMoreInfo {} {
  variable MainSearchFrame
  set items [$MainSearchFrame listbox selection get]
  if {[llength $items] < 1} {return}
  foreach item $items {
    set key [$MainSearchFrame listbox itemcget $item -data]
    set text [$MainSearchFrame listbox itemcget $item -text]
    if {![Database::GetCardByKey "$key" row]} {
      tk_messageBox -type ok -icon error -message "No card for $key!"
      return
    }
#    puts stderr "*** Search::DisplayMoreInfo: key = '$key'"
#    catch {parray row}
    DisplayMoreInfoWindow .moreInfo%AUTO% -key "$key" -htext "$text"
  }
}

namespace eval Search {
  snit::widgetadaptor DisplayMoreInfoWindow {
    option -key -readonly yes -default {}
    option -htext -readonly yes -default {}
    component idLE
    component titleLE
    component authorLE
    component subjectLE
    component mediaLE
    component locationLE
    component pubFrame
    component   publisherLE
    component   pubLocLE
    component   pubYearLE
    component editionLE
    component descriptionLF
    component  descriptionSW
    component    descriptionTX
    component buttons
    delegate option -menu to hull
    constructor {args} {
      set options(-key) [from args -key]
      set options(-htext) [from args -htext]
      Database::GetCardByKey "$options(-key)" row
      installhull using Windows::HomeLibrarianTopLevel -title "Card for: $options(-htext)"
      set frame [$hull getframe]
      install idLE using LabelEntry $frame.idLE -relief flat -entryfg blue \
			-label Key: -labelwidth 12 -text "$options(-key)" \
			-editable no
      pack $idLE  -fill x
      install titleLE using LabelEntry $frame.titleLE  -relief flat \
	    -entryfg blue -label Title: -labelwidth 12 -text "$row(Title)" \
	    -editable no
      pack $titleLE -fill x
      install authorLE using LabelEntry $frame.authorLE -relief flat -entryfg blue   \
	    -label Author: -labelwidth 12 -text "$row(Author)" \
	    -editable no
      pack $authorLE -fill x
      install subjectLE using LabelEntry $frame.subjectLE -relief flat -entryfg blue \
	    -label Subject: -labelwidth 12 -text "$row(Subject)" \
	    -editable no
      pack $subjectLE -fill x
      install mediaLE using LabelEntry $frame.mediaLE -relief flat -entryfg blue \
	    -label Media: -labelwidth 12 -text "$row(Media)" \
	    -editable no
      pack $mediaLE -fill x
      install locationLE  using LabelEntry $frame.locationLE  -relief flat -entryfg blue \
	    -label Location: -labelwidth 12 -text "$row(Location)" \
	    -editable no
      pack $locationLE -fill x
      install pubFrame using frame $frame.pub -borderwidth 0
      pack $pubFrame -expand yes -fill x
      install publisherLE using LabelEntry $pubFrame.publisher -relief flat -entryfg blue \
	    -label {Published By:} -labelwidth 12 -text "$row(Publisher)" \
	    -editable no
      pack $publisherLE -side left -fill x
      install pubLocLE using LabelEntry $pubFrame.loc -relief flat -entryfg blue \
	    -label { Of } -text "$row(PubLocation)" -editable no
      pack $pubLocLE -side left -fill x
      install pubYearLE using LabelEntry $pubFrame.date -relief flat -entryfg blue \
	    -label { In the year } -text "[clock format [clock scan $row(PubDate)] -format %Y]" -editable no
      pack $pubYearLE -side left
      install editionLE  using LabelEntry $frame.editionLE  -relief flat -entryfg blue \
	    -label Edition: -labelwidth 12 -text "$row(Edition)" \
	    -editable no
      pack $editionLE -fill x
      install descriptionLF using LabelFrame $frame.description \
	    -text Description: -side top
      pack $descriptionLF -expand yes -fill both
      install descriptionSW using ScrolledWindow $frame.description.descSW -auto vertical \
						   -scrollbar vertical
      pack $descriptionSW  -expand yes -fill both
      install descriptionTX using rotext $frame.description.descSW.desc -width 40 -height 12 -wrap word  -fg blue
      pack $descriptionTX -expand yes -fill both
      $descriptionSW setwidget $descriptionTX
      regsub -all "\r\n" "$row(Description)" "\n" unixDescription
      $descriptionTX insert end "$unixDescription"
      install buttons using ButtonBox $frame.buttons -orient horizontal
      pack $buttons -expand yes -fill both
      $buttons add -name print -text {Print Card} \
		       -command [list Print::PrintCard "$options(-key)"]
      $buttons add -name dismis -text {Dismis} \
		       -command [list destroy $self] \
		       -default active
      $buttons add -name help -text {Help} \
		       -command [list HTMLHelp::HTMLHelp help {More Info Window}]
      $self configurelist $args
    }
  }
}

proc Search::SaveNoteBook {{outfile {}}} {
  variable MainSearchNoteBook

  if {[string equal "$outfile" {}]} {
    set outfile [tk_getSaveFile -defaultextension .txt \
				-initialfile notebook.txt \
				-filetypes {
					{{Text Files}       {.txt .text} TEXT}
					{{All Files}        *             }
				} -parent . -title "File to save notebook in"]
  }
  if {[string equal "$outfile" {}]} {return}
  if {[catch [list open "$outfile" w] outfp]} {
    tk_messageBox -type ok -icon error \
		  -message "outfp"
    return
  }
  puts $outfp "[$MainSearchNoteBook get 1.0 end-1c]"
  close $outfp
}


package provide SearchWindow 1.0
