#* 
#* ------------------------------------------------------------------
#* EditWindow.tcl - Edit Window functions
#* Created by Robert Heller on Wed Sep 13 19:01:31 2006
#* ------------------------------------------------------------------
#* Modification History: $Log: EditWindow.tcl,v $
#* Modification History: Revision 1.2  2007/09/29 14:17:57  heller
#* Modification History: 3.0b1 Lockdown
#* Modification History:
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
package require AECFunctions

namespace eval AmazonECommerce {#dummy}

namespace eval Edit {
  variable TemplateFileTypes {
	{{Template Files} {.tmpl} TEXT}
	{{All Files}      *           }
  }
  snit::type TemplateCard {
    typevariable AvailableTemplates -array {}
    typemethod listOfTemplates {} {
      return [lsort -dictionary [array names AvailableTemplates]]
    }
    typemethod getTemplateByName {name} {
      if {[lsearch [array names AvailableTemplates] "$name"] < 0} {
	return {}
      } else {
	return $AvailableTemplates($name)
      }
    }
    typecomponent dialog
    typecomponent   templateListSW
    typecomponent     templateListBox
    typecomponent   templateFileB
    typecomponent   selectedTempLE
    typeconstructor {
      set dialog {}
    }
    typemethod _createdialog {} {
      if {"$dialog" ne "" && [winfo exists $dialog]} {return}
      set dialog [Dialog::create .selectATemplateDialog \
			-class SelectATemplateDialog -side bottom \
			-bitmap questhead -modal local \
			-title "Select A Template" \
			-default 0 -cancel 1]
      $dialog add -name ok -text OK -command [mytypemethod _OK]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command [list ::HTMLHelp::HTMLHelp help {Select A Template Dialog}]
      set frame [$dialog getframe]
      set templateListSW [ScrolledWindow::create $frame.templateListSW \
				-auto both -scrollbar both]
      pack $templateListSW -expand yes -fill both
      set templateListBox [ListBox::create $templateListSW.lb \
					-selectmode single -selectfill yes]
      pack $templateListBox -expand yes -fill both
      $templateListSW setwidget $templateListBox
      $templateListBox bindText <1> [mytypemethod _SelectTemplateFromLB]
      $templateListBox bindText <Double-1> [mytypemethod _ReturnTemplateFromLB]
      set templateFileB [Button::create $frame.layoutFE -text "Load from file" \
				-command [mytypemethod _LoadTemplateFile]]
      pack $templateFileB -fill x
      set selectedTempLE [LabelEntry::create $frame.selectedTempLE \
				-label "Selected Template:"]
      pack $selectedTempLE -fill x
      $selectedTempLE bind <Return> [mytypemethod _OK]

      $type create ::Edit::<default> -locked yes				
    }
    typemethod _LoadTemplateFile {} {
      set filename [tk_getOpenFile -defaultextension ".tmpl" \
			-title "File to load template from" \
			-filetypes $Edit::TemplateFileTypes \
			-parent $dialog]
      raise $dialog
      if {[string equal "$filename" {}]} {return}
      if {[catch [list open "$filename" r] chan]} {
	tk_messageBox -type ok -icon  error -message "open $filename r: $chan"
	return
      }
      set templatename [$type loadFromFile $chan]
      close $chan
      $templateListBox delete [$templateListBox items]
      foreach tp [$type listOfTemplates] {
	$templateListBox insert end $tp -text "$tp" -data "$tp"
      }
    }
    typevariable _Result {}
    typemethod _OK {} {
      set _Result "[$selectedTempLE cget -text]"
      $dialog withdraw
      return [$dialog enddialog ok]
    }
    typemethod _Cancel {} {
      $dialog withdraw
      return [$dialog enddialog cancel]
    }
    typemethod _SelectTemplateFromLB {selected} {
      $templateListBox selection set $selected
      $selectedTempLE configure -text "[$templateListBox itemcget $selected -data]"
    }
    typemethod _ReturnTemplateFromLB {selected} {
      $templateListBox selection set $selected
      $selectedTempLE configure -text "[$templateListBox itemcget $selected -data]"
      $type _OK
    }
    typemethod  selectATemplateDialog {args} {
      $type _createdialog
      $templateListBox delete [$templateListBox items]
      foreach tp [$type listOfTemplates] {
	$templateListBox insert end $tp -text "$tp" -data "$tp"
      }
      $selectedTempLE configure -text {}
      set newP [from args -new]
      $selectedTempLE configure -editable $newP
      set button [$dialog draw]
      if {[string equal "$button" ok]} {
	return "$_Result"
      } else {
	return {}
      }
    }
    option -title -readonly yes -default {}
    option -author -readonly yes -default {}
    option -subject -readonly yes -default {}
    option -location -readonly yes -default {}
    option -category -readonly yes -default {}
    option -media -readonly yes -default {}
    option -publisher -readonly yes -default {}
    option -publocation -readonly yes -default {}
    option -pubdate -readonly yes -default {}
    option -edition -readonly yes -default {}
    option -isbn -readonly yes -default {}
    option -description -readonly yes -default {}
    option -locked -readonly yes -default no
    variable templateName
    constructor {args} {
#      puts stderr "*** $type constructor: self = $self, args = $args"
      $self configurelist $args
      set templateName [namespace tail $self]
      set AvailableTemplates($templateName) $self
    }
    destructor {
      unset AvailableTemplates($templateName)
    }
    method saveToFile {channel} {
      puts $channel {Card Template File}
      puts $channel [list :name "$templateName"]
      puts $channel [list -locked "$options(-locked)"]
      puts $channel [list -title "$options(-title)"]
      puts $channel [list -author "$options(-author)"]
      puts $channel [list -subject "$options(-subject)"]
      puts $channel [list -location "$options(-location)"]
      puts $channel [list -category "$options(-category)"]
      puts $channel [list -media "$options(-media)"]
      puts $channel [list -publisher "$options(-publisher)"]
      puts $channel [list -publocation "$options(-publocation)"]
      puts $channel [list -pubdate "$options(-pubdate)"]
      puts $channel [list -edition "$options(-edition)"]
      puts $channel [list -isbn "$options(-isbn)"]
      puts $channel [list -description "$options(-description)"]
    }
    typemethod _GetBuffer {chan} {
      set buffer "[gets $chan]"
      while {![info complete "$buffer"] && ![eof $chan]} {
	append buffer "\n[gets $chan]"
      }
      return "$buffer"
    }
    typemethod loadFromFile {channel} {
      set buffer "[$type _GetBuffer $channel]"
      if {![string equal "$buffer" {Card Template File}]} {
	error "Not a template file!"
	return
      }
      set buffer "[$type _GetBuffer $channel]"
      foreach {n v} $buffer {
	if {![string equal "$n" :name]} {
	  error "Not a template file!"
	  return
	} else {
          regsub -all {[[:space:]]} "$v" {_} templatename
	  set oldtemp [$type getTemplateByName $templatename]
	  if {![string equal "$oldtemp" {}]} {
	    set ans [tk_messageBox -type yesno -icon question \
				   -message "Template $templatename already exists! Replace it?"]
	    if {!$ans} {return}
	    $oldtemp destroy
	  }
	}
      }
      set args {}
      while {![eof $channel]} {
	foreach {n v} [$type _GetBuffer $channel] {
	  lappend args "$n" "$v"
	}
      }
      
      return [eval $type create $templatename $args]
    }
    method edit {args} {
      eval [list Edit::EditTemplate draw -template $templateName \
				-update [mymethod _Update]] $args
    }
    method _Update {args} {
      if {$options(-locked)} {
	tk_messageBox -type ok -icon error \
		-message "Template $templateName is locked!"
        return
      }
      foreach o [array names options] {
	if {[string equal "$o" {-locked}]} {continue}
	set options($o) [from args $o $options($o)]
      }
    }
  }
  snit::widgetadaptor EditTemplate {
    typevariable _EditorsByName -array {}
    option -templatename -readonly yes -default {}
    delegate option -height to hull
    delegate option -width to hull
    option -transientparent -readonly yes -default {}
    delegate option -menu to hull
    option -update -readonly yes -default {}
    component nameLE
    component titleLE
    component authorLE
    component subjectLE
    component locationLE
    component categoryLE
    component mediaLE
    component publisherLE
    component publisherLocLE
    component publisherDateLE
    component editionLE
    component isbnLE
    component descriptionSW
    component   descriptionTX
    component editBB
    variable  dirtylabel
    constructor {args} {
      set options(-templatename) [from args -templatename]
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
      $hull configure -title "Editing Template card $options(-templatename)"
      install nameLE using LabelEntry::create $frame.idLE \
		-label {Name:} -labelwidth 16 -editable no \
		-entryfg blue -text "$options(-templatename)"
      pack $nameLE -fill x
      install titleLE using LabelEntry::create $frame.titleLE \
		-label {Title:} -labelwidth 16
      $titleLE bind <KeyPress> [mymethod _MakeDirty]
      pack $titleLE -fill x
      install authorLE using LabelEntry::create $frame.authorLE \
		-label {Author:} -labelwidth 16
      $authorLE bind <KeyPress> [mymethod _MakeDirty]
      pack $authorLE -fill x
      install subjectLE using LabelEntry::create $frame.subjectLE \
		-label {Subject:} -labelwidth 16
      $subjectLE bind <KeyPress> [mymethod _MakeDirty]
      pack $subjectLE -fill x
      install locationLE using LabelEntry::create $frame.locationLE \
		-label {Location:} -labelwidth 16
      $locationLE bind <KeyPress> [mymethod _MakeDirty]
      pack $locationLE -fill x
      install categoryLE using LabelEntry::create $frame.categoryLE \
		-label {Category:} -labelwidth 16
      $categoryLE bind <KeyPress> [mymethod _MakeDirty]
      pack $categoryLE -fill x
      install mediaLE using LabelEntry::create $frame.mediaLE \
		-label {Media:} -labelwidth 16
      pack $mediaLE -fill x
      $mediaLE bind <KeyPress> [mymethod _MakeDirty]
      frame $frame.pubframe -borderwidth 0
      pack $frame.pubframe -fill x
      set pubframe $frame.pubframe
      install publisherLE using LabelEntry::create $pubframe.publisherLE \
		-label {Publisher:} -labelwidth 16
      pack $publisherLE -fill x -side left
      $publisherLE bind <KeyPress> [mymethod _MakeDirty]
      install publisherLocLE using LabelEntry::create $pubframe.publisherLocLE \
		-label { of }
      pack $publisherLocLE  -side left
      $publisherLocLE bind <KeyPress> [mymethod _MakeDirty]
      install publisherDateLE using LabelEntry::create $pubframe.publisherDateLE \
		-label { on }
      pack $publisherDateLE -side left
      $publisherDateLE bind <KeyPress> [mymethod _MakeDirty]
      install editionLE using LabelEntry::create $frame.editionLE \
		-label {Edition:} -labelwidth 16
      pack $editionLE -fill x
      $editionLE bind <KeyPress> [mymethod _MakeDirty]
      install isbnLE using LabelEntry::create $frame.isbnLE \
		-label {ISBN/ASIN:} -labelwidth 16
      pack $isbnLE -fill x
      $isbnLE bind <KeyPress> [mymethod _MakeDirty]
      install descriptionSW using ScrolledWindow::create $frame.descriptionSW \
		-auto both -scrollbar both
      pack $descriptionSW -expand yes -fill both
      install descriptionTX using text $descriptionSW.text -wrap word \
			-height 12
      pack $descriptionTX -expand yes -fill both
      $descriptionSW setwidget $descriptionTX
      global tk_patchLevel
      if {[package vcompare $tk_patchLevel 8.4.0] >= 0} {
        bind $descriptionTX <<Modified>> [mymethod _MakeDirty]
      } else {
	bind $descriptionTX <KeyPress> [mymethod _MakeDirty]
      }
      install editBB using ButtonBox::create $frame.editBB \
		-orient horizontal -homogeneous no
      pack $editBB -fill x
      $editBB add -name save -text Save -command [mymethod _Save]
      $editBB add -name dismis -text Dismis -command [mymethod _Dismis]
      $editBB add -name help -text Help -command [list ::HTMLHelp::HTMLHelp help {Edit Template}]
      wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
      set _EditorsByName($options(-templatename)) $self
      $dirtylabel configure -foreground [$dirtylabel cget -background]
      $dirtylabel configure -relief flat
    }
    method _MakeDirty {} {
      $dirtylabel configure -foreground red
      $dirtylabel configure -relief sunken
    }
    method _IsDirty {} {
      return [expr {![string equal "[$dirtylabel cget -foreground]" \
			           "[$dirtylabel cget -background]"]}]
    }
    method _Dismis {} {
      if {[$self _IsDirty]} {
	if {[tk_messageBox -type yesno -icon question \
			-message "Template has not been saved! Save it?"]} {
	  $self _Save
        }
      }
      wm withdraw $win
    }
    method _Save {} {
      if {[string equal "$options(-update)" {}]} {return}
      set args {}
      foreach opt      {-title   -author   -subject   -location   -category   \
			-media   -publisher   -publocation   -pubdate  \
			-edition   -isbn} \
	      LE  [list $titleLE $authorLE $subjectLE $locationLE $categoryLE \
			$mediaLE $publisherLE $publisherLocLE $publisherDateLE \
			$editionLE $isbnLE] {
        lappend args $opt "[$LE cget -text]"
      }
      lappend args -description "[$descriptionTX get 1.0 end-1c]"
      eval $options(-update) $args
      $dirtylabel configure -foreground [$dirtylabel cget -background]
      $dirtylabel configure -relief flat
    }
    method raise {} {
      wm deiconify $win
      raise $win
    }
    method initialize {newP} {
      set template [Edit::TemplateCard getTemplateByName "$options(-templatename)"]
      foreach opt      {-title   -author   -subject   -location   -category   \
			-media   -publisher   -publocation   -pubdate  \
			-edition   -isbn} \
	      LE  [list $titleLE $authorLE $subjectLE $locationLE $categoryLE \
			$mediaLE $publisherLE $publisherLocLE $publisherDateLE \
			$editionLE $isbnLE] {
	$LE configure -text "[$template cget $opt]"
      }
      $descriptionTX delete 1.0 end
      $descriptionTX insert end "[$template cget -description]"
      if {[$template cget -locked]} {
	$editBB itemconfigure save -state disabled
      } else {
	$editBB itemconfigure save -state normal
      }
      if {$newP} {
	$dirtylabel configure -foreground red
	$dirtylabel configure -relief sunken
      } else {
	$dirtylabel configure -foreground [$dirtylabel cget -background]
	$dirtylabel configure -relief flat
      }
    }
    typemethod draw {args} {
      set name [from args -template]
      set newp [from args -new]
      if {[catch [list set _EditorsByName($name)] te]} {
	set te [eval [list $type create .editTemplate%AUTO% -templatename $name] $args]
      } else {
	$te raise
      }
      $te initialize $newp
    }
  }
  variable EditCardKeyString {}
  variable MainSearchFrame {}
  variable AmazonSearchFrame {}
}

proc Edit::EditATemplate {} {
  set new no
  set temp [TemplateCard selectATemplateDialog -new yes]
  if {[string equal "$temp" {}]} {return}
  set template [TemplateCard getTemplateByName $temp]
  if {[string equal "$template" {}]} {
    regsub -all {[[:space:]]} "$temp" {_} temp
    TemplateCard create "$temp"
     set template [TemplateCard getTemplateByName $temp]
    set new yes
  }
#  puts stderr "*** Edit::EditATemplate: temp = $temp"
#  puts stderr "*** Edit::EditATemplate: template = $template"
#  puts stderr "*** Edit::EditATemplate: info procs $temp = [info procs $temp]"
#  puts stderr "*** Edit::EditATemplate: info procs $template = [info procs $template]"
  $template edit -new $new
}

proc Edit::DeleteTemplate {} {
  set temp [TemplateCard selectATemplateDialog -new no]
  if {[string equal "$temp" {}]} {return}
  [TemplateCard getTemplateByName $temp] destroy
}


proc Edit::SaveTemplate {} {
  variable TemplateFileTypes
  set temp [TemplateCard selectATemplateDialog -new no]
  if {[string equal "$temp" {}]} {return}
  set file [tk_getSaveFile -title "File to save template $temp in" \
  			   -filetypes $TemplateFileTypes \
			   -defaultextension .tmpl]
  if {[string equal "$file" {}]} {return}
  if {[catch [list open "$file" w] chan]} {
    tk_messageBox -type ok -icon error -message "$chan"
    return
  }
  [TemplateCard getTemplateByName $temp] saveToFile $chan
  close $chan
}

proc Edit::LoadTemplate {} {
  variable TemplateFileTypes
  set file [tk_getOpenFile -title "File to load template from" \
			   -filetypes $TemplateFileTypes \
			   -defaultextension .tmpl]
  if {[string equal "$file" {}]} {return}
  if {[catch [list open "$file" r] chan]} {
    tk_messageBox -type ok -icon error -message "$chan"
    return
  }
  TemplateCard loadFromFile $chan
  close $chan
}

proc Edit::EditPane {} {
  variable EditCardKeyString
  variable MainSearchFrame
  variable AmazonSearchFrame
  variable ::Windows::Manager
  variable ::Windows::MainButtons

  set uf [$Manager add update]
  pack [frame $uf.ekframe -borderwidth 0 -relief flat] -fill x
  pack [Button::create $uf.ekframe.edit -text {Edit Card:} -width 10 \
	-command {Edit::EditACardByKey "[$Edit::EditCardKeyString cget -text]"} \
	-justify left -anchor w] -side left
  pack [Entry::create $uf.ekframe.keystring -text {} \
	-command {Edit::EditACardByKey "[$Edit::EditCardKeyString cget -text]"}] \
		-side right -expand yes -fill x
  set EditCardKeyString $uf.ekframe.keystring
  set ufpaneW [PanedWindow::create $uf.ufpaneW -side right]
  pack $ufpaneW -expand yes -fill both
  set search [$ufpaneW add -weight 1 -name search]
  pack [Database::SearchFrame $search.searchframe -resultlbheight 2 \
						  -selectmode single] \
	-expand yes -fill both
  set MainSearchFrame $search.searchframe
  $MainSearchFrame buttons add -name edit -text {Edit} \
	-command Edit::EditCardFromList
  $MainSearchFrame buttons add -name delete -text {Delete} \
	-command Edit::DeleteCardFromList
  update idle
  $ufpaneW paneconfigure search -minsize [winfo reqheight $search]
  set amazon [$ufpaneW add -weight 1 -name amazon]
  set AmazonSearchFrame [AmazonECommerce::AmazonSearch $amazon.amazonSearch \
				-resultlbheight 2]
  pack $AmazonSearchFrame -expand yes -fill both
  $AmazonSearchFrame buttons add -name create \
	-text {Create Card From Amazon Data} \
	-command Edit::CreateCardFromAmazonData
  $AmazonSearchFrame buttons add -name view \
	-text {View Amazon Data} \
	-command "$AmazonSearchFrame viewItem"
  update idle
  $ufpaneW paneconfigure notes -minsize [winfo reqheight $amazon]
  pack [Button::create $uf.returnbutton -text {Return To Main} \
	 -command "$Windows::AnimatedHeader SetMessage {How May I Help You?};$Manager raise main"] -fill x
#  puts stderr "*** Edit::EditPane: update added"
  $MainButtons add -name update -text "Update Library" \
			      -font {Helvetica -34 bold roman} \
			      -background {yellow} -activeforeground {yellow} \
			      -foreground {brown} -activebackground {brown} \
			      -command "$Manager raise update" -state disabled
  if {[Database::HaveData] && [Database::IsWritableData]} {
    $MainButtons itemconfigure update -state normal
  }
}

proc Edit::EditACardByKey {key} {
  set oldCardP [Database::GetCardByKey "$key" dummy]
  if {$oldCardP} {
    set temp [EditCard .editCard%AUTO% -new no -key "$key"]
  } else {
    set temp [EditCard .editCard%AUTO% -new yes -key "$key"]
  }
#  puts stderr "*** Edit::EditACardByKey: temp = $temp"
#  puts stderr "*** Edit::EditACardByKey: class: [winfo class $temp]"
  if {[string equal [winfo class $temp] Frame]} {
    destroy $temp
  }

}

proc Edit::EditCardFromList {} {
  variable MainSearchFrame
  set selection [$MainSearchFrame listbox selection get]
  if {[llength $selection] < 1} {return}
  EditACardByKey "[lindex $selection 0]"
}

proc Edit::DeleteCardFromList {} {
  variable MainSearchFrame
  set selection [$MainSearchFrame listbox selection get]
  if {[llength $selection] < 1} {return}
  set key "[lindex $selection 0]"
  set ans [tk_messageBox -type yesno -icon question \
	-message "Are you sure you want to delete the card for $key?"
  if {$ans} {
    Database::DeleteCard "$key" \
	[Edit::EditUpdateLogDialog .deleteLog%AUTO% \
		-title "Deleting card $key" \
		-parent .]
  }
}

proc Edit::CreateCardFromAmazonData {} {
  variable AmazonSearchFrame
  set URL [$AmazonSearchFrame formSelectedItemResponseGroupURL Large]
  if {[string equal "$URL" {}]} {return}
  set temp [EditCard .editCard%AUTO% -new yes -haveamazonurl "$URL"]
  if {[string equal [winfo class $temp] Frame]} {
    destroy $temp
  }
}

namespace eval Edit {
  snit::widgetadaptor EditCard {

    option -new -readonly yes -default yes
    option {-haveamazonurl haveAmazonURL HaveAmazonURL} -readonly yes -default {}
    option {-havetemplate haveTemplate HaveTemplate} -readonly yes -default {}
    option -key -readonly yes -default {}
    delegate option -height to hull
    delegate option -width to hull
    option -separator -default both
    option -transientparent -readonly yes -default {}
    delegate option -menu to hull
    method _SetURL {url} {set options(-haveamazonurl) "$url"}
    method _SetTemplate {template} {set options(-havetemplate) "$template"}
    component idLE
    component titleLE
    component authorLE
    component subjectLE
    component locationLE
    component categoryLE
    component mediaLE
    component publisherLE
    component publisherLocLE
    component publisherDateLE
    component editionLE
    component isbnLE
    component descriptionSW
    component   descriptionTX
    component keywordsSW
    component   keywordsLB
    component keywordLE
    component keywordsBB
    component editBB
    variable  dirtylabel
    
    constructor {args} {
      set options(-key) [from args -key]
      set options(-transientparent) [from args -transientparent]
      if {[string equal "$options(-key)" {}]} {
	set options(-key) "[Edit::GetNewKeyDialog draw]"
	if {[string equal "$options(-key)" {}]} {
	  installhull using frame
	  return
 	}
      }
      installhull using Windows::HomeLibrarianTopLevel \
		-transientparent $options(-transientparent) \
		-windowmenu {} \
		-separator both
      set frame [$hull getframe]
      $self configurelist $args
      set dirtylabel [$hull mainframe addindicator -bitmap gray50]
      $dirtylabel configure -foreground [$dirtylabel cget -background]
      $dirtylabel configure -relief flat
      $hull configure -title "Editing card for $options(-key)"
      install idLE using LabelEntry::create $frame.idLE \
		-label {Identification:} -labelwidth 16 -editable no \
		-entryfg blue -text "$options(-key)"
      pack $idLE -fill x
      install titleLE using LabelEntry::create $frame.titleLE \
		-label {Title:} -labelwidth 16
      $titleLE bind <KeyPress> [mymethod _MakeDirty]
      pack $titleLE -fill x
      install authorLE using LabelEntry::create $frame.authorLE \
		-label {Author:} -labelwidth 16
      $authorLE bind <KeyPress> [mymethod _MakeDirty]
      pack $authorLE -fill x
      install subjectLE using LabelEntry::create $frame.subjectLE \
		-label {Subject:} -labelwidth 16
      $subjectLE bind <KeyPress> [mymethod _MakeDirty]
      pack $subjectLE -fill x
      install locationLE using LabelEntry::create $frame.locationLE \
		-label {Location:} -labelwidth 16
      $locationLE bind <KeyPress> [mymethod _MakeDirty]
      pack $locationLE -fill x
      install categoryLE using LabelEntry::create $frame.categoryLE \
		-label {Category:} -labelwidth 16
      $categoryLE bind <KeyPress> [mymethod _MakeDirty]
      pack $categoryLE -fill x
      install mediaLE using LabelEntry::create $frame.mediaLE \
		-label {Media:} -labelwidth 16
      pack $mediaLE -fill x
      $mediaLE bind <KeyPress> [mymethod _MakeDirty]
      frame $frame.pubframe -borderwidth 0
      pack $frame.pubframe -fill x
      set pubframe $frame.pubframe
      install publisherLE using LabelEntry::create $pubframe.publisherLE \
		-label {Publisher:} -labelwidth 16
      pack $publisherLE -fill x -side left
      $publisherLE bind <KeyPress> [mymethod _MakeDirty]
      install publisherLocLE using LabelEntry::create $pubframe.publisherLocLE \
		-label { of }
      pack $publisherLocLE  -side left
      $publisherLocLE bind <KeyPress> [mymethod _MakeDirty]
      install publisherDateLE using LabelEntry::create $pubframe.publisherDateLE \
		-label { on }
      pack $publisherDateLE -side left
      $publisherDateLE bind <KeyPress> [mymethod _MakeDirty]
      install editionLE using LabelEntry::create $frame.editionLE \
		-label {Edition:} -labelwidth 16
      pack $editionLE -fill x
      $editionLE bind <KeyPress> [mymethod _MakeDirty]
      install isbnLE using LabelEntry::create $frame.isbnLE \
		-label {ISBN/ASIN:} -labelwidth 16
      pack $isbnLE -fill x
      $isbnLE bind <KeyPress> [mymethod _MakeDirty]
      install descriptionSW using ScrolledWindow::create $frame.descriptionSW \
		-auto both -scrollbar both
      pack $descriptionSW -expand yes -fill both
      install descriptionTX using text $descriptionSW.text -wrap word \
			-height 12
      pack $descriptionTX -expand yes -fill both
      $descriptionSW setwidget $descriptionTX
      global tk_patchLevel
      if {[package vcompare $tk_patchLevel 8.4.0] >= 0} {
        bind $descriptionTX <<Modified>> [mymethod _MakeDirty]
      } else {
	bind $descriptionTX <KeyPress> [mymethod _MakeDirty]
      }
      set keyframe [frame $frame.keywordframe -borderwidth 0]
      pack $keyframe -fill x
      install keywordsSW using ScrolledWindow::create $keyframe.keywordsSW \
		-auto both -scrollbar both
      pack $keywordsSW -expand yes -fill both -side left
      install keywordsLB using ListBox::create $keywordsSW.lb \
		-selectmode single -selectfill yes -height 3
      pack $keywordsLB -expand yes -fill both
      $keywordsSW setwidget $keywordsLB
      set keyframeR [frame $keyframe.keyframeR -borderwidth 0]
      pack $keyframeR -fill both -side right
      install keywordLE using LabelEntry::create $keyframeR.keywordLE \
		-label {Keyword:}
      pack $keywordLE -fill x
      install keywordsBB using ButtonBox::create $keyframeR.keywordsBB \
	-orient horizontal -homogeneous no
      pack $keywordsBB -fill x
      $keywordsBB add -name add -text {Add Keyword} -command [mymethod _AddKeyword]
      $keywordsBB add -name delete -text {Delete Keyword} -command [mymethod _DeleteKeyword]
      install editBB using ButtonBox::create $frame.editBB \
		-orient horizontal -homogeneous no
      pack $editBB -fill x
      $editBB add -name save -text Save -command [mymethod _Save]
      $editBB add -name dismis -text Dismis -command [mymethod _Dismis]
      $editBB add -name help -text Help -command [list ::HTMLHelp::HTMLHelp help {Edit Card}]
      wm protocol $win WM_DELETE_WINDOW [mymethod _Dismis]
      if {$options(-new)} {
	if {[string equal "$options(-haveamazonurl)" {}] && 
	    [string equal "$options(-havetemplate)" {}]} {
	  Edit::GetNewCardTemplateOrAmazonURLDialog draw \
		-setURLProc [mymethod _SetURL] \
		-setTemplateProc [mymethod _SetTemplate]
	}
	if {![string equal "$options(-haveamazonurl)" {}]} {
	  #fill from Amazon data
	  AmazonECommerce::GetAmazonData "$options(-haveamazonurl)" \
					[mymethod _AmazonDataCallback]
	} elseif {![string equal "$options(-havetemplate)" {}]} {
	  #fill from template
	  set template [Edit::TemplateCard getTemplateByName "$options(-havetemplate)"]
	  foreach opt      {-title   -author   -subject   -location   -category   \
			    -media   -publisher   -publocation   -pubdate  \
			    -edition   -isbn} \
		  LE  [list $titleLE $authorLE $subjectLE $locationLE $categoryLE \
			    $mediaLE $publisherLE $publisherLocLE $publisherDateLE \
			    $editionLE $isbnLE] {
	    $LE configure -text "[$template cget $opt]"
	  }
	  $descriptionTX delete 1.0 end
	  $descriptionTX insert end "[$template cget -description]"
	} else {
	  #don't fill
	}
      } else {
	# Fill from existing data
	if {[Database::GetCardByKey "$options(-key)" data]} {
	  $titleLE         configure -text "$data(Title)"
	  $authorLE        configure -text "$data(Author)"
	  $subjectLE       configure -text "$data(Subject)"
	  $locationLE      configure -text "$data(Location)"
	  $categoryLE      configure -text "$data(Category)"
	  $mediaLE         configure -text "$data(Media)"
	  $publisherLE     configure -text "$data(Publisher)"
	  $publisherLocLE  configure -text "$data(PubLocation)"
	  $publisherDateLE configure -text "$data(PubDate)"
	  $editionLE       configure -text "$data(Edition)"
	  $isbnLE          configure -text "$data(ISBN)"
          regsub -all "\r\n" "$data(Description)" "\n" unixDescription
	  $descriptionTX   insert end "$unixDescription"
	  if {[package vcompare $tk_patchLevel 8.4.0] >= 0} {
	    $descriptionTX edit modified 0
	  }
	  set keywords [Database::GetKeywordsForKey "$options(-key)"]
	  $keywordsLB delete [$keywordsLB items]
	  foreach keyword $keywords {
	    $keywordsLB insert end "$keyword" -data "$keyword" -text "$keyword"
	  }
	  $dirtylabel configure -foreground [$dirtylabel cget -background]
	  $dirtylabel configure -relief flat
	}
      }
    }
    method _AmazonDataCallback {field value} {
#      puts stderr [list *** $self _AmazonDataCallback $field $value]
#      puts stderr "*** $self _AmazonDataCallback: field = '$field'"
      set name "[lindex $field 0]"
      set attlist [lindex $field 1]
      switch -exact -- "$name" {
	Editor -
	Artist -
	Actor -
	Director -
	Foreword -
	Contributor -
	Author {
	   set authorSoFar "[$authorLE cget -text]"
	   if {[string equal "$authorSoFar" {}]} {
	     $authorLE configure -text "$value"
	   } else {
	     $authorLE configure -text "$authorSoFar, $value"
	   }
	}
	Creator {
	   set authorSoFar "[$authorLE cget -text]"
	   set roleI [expr {[lsearch $attlist role] + 1]}]
	   if {$roleI > 0} {
	     append value " ([lindex $attlist $roleI])"
	   }
	   if {[string equal "$authorSoFar" {}]} {
	     $authorLE configure -text "$value"
	   } else {
	     $authorLE configure -text "$authorSoFar, $value"
	   }
	}
	Title {
	  set titleSoFar "[$titleLE cget -text]"
	  if {[string equal "$titleSoFar" {}]} {
	    $titleLE         configure -text "$value"
	  }
	}
	ReleaseDate -
	PublicationDate {
	  set publisherDateSoFar "[$publisherDateLE cget -text]"
	  if {[string equal "$publisherDateSoFar" {}]} {
	    $publisherDateLE configure -text "$value"
	  }
	}
	Studio -
	Label -
	Publisher {
	  set publisherSoFar "[$publisherLE cget -text]"
	  if {[string equal "$publisherSoFar" {}]} {
	    $publisherLE     configure -text "$value"
	  }
	}
	ISBN {
	  $isbnLE          configure -text "$value"
	}
	Edition {
	  $editionLE       configure -text "$value"
	}
	Binding -
	Format -
	ProductGroup {
	  set mediaSoFar "[$mediaLE cget -text]"
	  if {[string equal "$mediaSoFar" {}]} {
	    $mediaLE         configure -text "$value"
	  } else {
	    $mediaLE         configure -text "$mediaSoFar, $value"
	  }
	}
	ListmaniaLists  -
	ListmaniaList  -
	ListPrice -
	ItemLookupResponse -
	ItemLookupRequest -
	Offers -
	OperationRequest -
	HTTPHeaders -
	Header -
	HTTPHeaders -
	Arguments -
	Argument -
	Items -
	Request -
	Item -
	ItemAttributes -
	OfferSummary -
	LowestNewPrice -
	LowestUsedPrice -
	LowestCollectiblePrice -
	BrowseNodes -
	BrowseNode -
	Ancestors -
	RequestId -
	RequestProcessingTime -
	IsValid -
	ItemId -
	ResponseGroup -
	ASIN -
	SalesRank -
	URL -
	Height -
	Width -
	EAN -
	Amount -
	CurrencyCode -
	FormattedPrice -
	UPC -
	TotalNew -
	TotalUsed -
	TotalCollectible -
	TotalRefurbished -
	TotalOffers -
	TotalOfferPages -
	AverageRating -
	TotalReviews -
	TotalReviewPages -
	Rating -
	HelpfulVotes -
	CustomerId -
	TotalVotes -
	Date -
	BrowseNodeId -
	Name -
	ListId -
	ListName {
	}
	default {
	  $descriptionTX insert end "$name $attlist $value\n"
	}
      }
    }
    method _MakeDirty {} {
      $dirtylabel configure -foreground red
      $dirtylabel configure -relief sunken
    }
    method _AddKeyword {} {
      set keyword [string trim "[$keywordLE cget -text]"]
      if {[$keywordsLB exists "$keyword"]} {return}
      $keywordsLB insert end "$keyword" -data "$keyword" -text "$keyword"
    }
    method _DeleteKeyword {} {
      set selection [$keywordsLB selection get]
      if {[llength $selection] > 0} {
	$keywordsLB delete $selection
      }
    }
    method _Save {} {
      set data(Key)         "$options(-key)"
      set data(Title)       "[$titleLE         cget -text]"
      set data(Author)      "[$authorLE        cget -text]"
      set data(Subject)     "[$subjectLE       cget -text]"
      set data(Location)    "[$locationLE      cget -text]"
      set data(Category)    "[$categoryLE      cget -text]"
      set data(Media)       "[$mediaLE         cget -text]"
      set data(Publisher)   "[$publisherLE     cget -text]"
      set data(PubLocation) "[$publisherLocLE  cget -text]"
      set data(PubDate)     "[$publisherDateLE cget -text]"
      set data(Edition)     "[$editionLE       cget -text]"
      set data(ISBN)        "[$isbnLE          cget -text]"
      set data(Description) "[$descriptionTX get 1.0 end-1c]"
      set keywords [$keywordsLB items]
#      puts stderr "*** $self _Save: options(-new) = $options(-new)"
      if {$options(-new)} {
        set log [Edit::EditUpdateLogDialog .insertLog%AUTO% \
			-title "Inserting card $options(-key)" \
			-parent [winfo toplevel $keywordsLB]]
	if {![Database::InsertCard data $log]} {return}
	if {![Database::InsertKeywordsForKey "$options(-key)" $keywords $log]} {return}
	set $options(-new) no
      } else {
        set log [Edit::EditUpdateLogDialog .updateLog%AUTO% \
			-title "Updating card $options(-key)" \
			-parent [winfo toplevel $keywordsLB]]
#	puts stderr "*** $self _Save: calling Database::UpdateCard"
        if {![Database::UpdateCard data $log]} {return}
#	puts stderr "*** $self _Save: calling Database::DeleteKeywordsForKey"
	if {![Database::DeleteKeywordsForKey "$options(-key)" $log]} {return}
#	puts stderr "*** $self _Save: calling Database::InsertKeywordsForKey"
	if {![Database::InsertKeywordsForKey "$options(-key)" $keywords $log]} {return}
      }
      global tk_patchLevel
      if {[package vcompare $tk_patchLevel 8.4.0] >= 0} {
	$descriptionTX edit modified 0
      }
#      puts stderr "*** $self _Save: changing dirty icon's foreground color"
      $dirtylabel configure -foreground "[$dirtylabel cget -background]"
#      puts stderr "*** $self _Save: changing dirty icon's relief"
      $dirtylabel configure -relief flat
      set $options(-new) no
    }
    method _Dismis {} {
      if {![string equal [$dirtylabel cget -background] \
			 [$dirtylabel cget -foreground]]} {
	set ans [tk_messageBox -type yesno -icon question -parent $win \
			       -message "Card is modified and not saved! Dismis anyway?"]
	if {!$ans} {return}
      }
      destroy $self
    }
  }
  snit::type GetNewKeyDialog {
    pragma -hastypeinfo    no
    pragma -hastypedestroy no
    pragma -hasinstances   no

    typecomponent dialog
    typecomponent newKeyLE

    typeconstructor {
      set dialog {}
    }
    typemethod _createdialog {} {
      if {"$dialog" ne "" && [winfo exists $dialog]} {return}
      set dialog [Dialog::create .getNewKeyDialog \
			-class GetNewKeyDialog \
			-side bottom -bitmap questhead \
			-modal local -title "Get New Key" \
			-default 0 -cancel 1]
      $dialog add -name ok -text OK -command [mytypemethod _OK]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command [list ::HTMLHelp::HTMLHelp help {Get New Key Dialog}]
      set frame [$dialog getframe]
      set newKeyLE [LabelEntry::create $frame.newKeyLE \
				-label "New key:" -side left -text {}]
      pack $newKeyLE -fill x
      $newKeyLE bind <Return> [mytypemethod _OK]
    }
    typevariable _Result
    typemethod _OK {} {
      set _Result "[$newKeyLE cget -text]"
      if {[string length "$_Result"] > 0} {
	if {[Database::GetCardByKey "$_Result" dummy]} {
	  tk_messageBox -type ok -icon info \
			-message "Key already in use: $_Result, try another."
	  return
	}
        $dialog withdraw
	$dialog enddialog ok
      }
    }
    typemethod _Cancel {} {
      $dialog withdraw
      $dialog enddialog cancel
    }
    typemethod draw {args} {
      $type _createdialog
      set button [$dialog draw]
      switch $button {
	ok {return $_Result}
	cancel {return {}}
      }
    }
  }
  snit::type GetNewCardTemplateOrAmazonURLDialog {
    pragma -hastypeinfo    no
    pragma -hastypedestroy no
    pragma -hasinstances   no

    typecomponent dialog
    typecomponent templateSW
    typecomponent  templateLB
    typecomponent amazonSB 
    typeconstructor {
      set dialog {}
    }
    typemethod _createdialog {} {
      if {"$dialog" ne "" && [winfo exists $dialog]} {return}
      set dialog [Dialog::create .getNewCardTemplateOrAmazonURLDialog \
			-class GetNewCardTemplateOrAmazonURLDialog \
			-bitmap questhead \
			-homogeneous no \
			-modal local -title "Get Template Or Amazon URL" \
			-cancel 2]
      $dialog add -name oktemp -text {Use Template} -command [mytypemethod _OKTemp]
      $dialog add -name okurl -text {Use Amazon URL} -command [mytypemethod _OKURL]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command [list ::HTMLHelp::HTMLHelp help {Get New Card Template Or Amazon URL Dialog}]
      set frame [$dialog getframe]
      set templateSW [ScrolledWindow::create $frame.templateSW -auto both -scrollbar both]
      pack $templateSW -expand yes -fill both -side left
      set templateLB [ListBox::create $templateSW.lb -selectfill yes \
						-selectmode single -height 10]
      pack $templateLB -expand yes -fill both
      $templateSW setwidget $templateLB
      set amazonSB [AmazonECommerce::AmazonSearch $frame.amazonSB -resultlbheight 6]
      pack $amazonSB -expand yes -fill both -side right
    }
    typevariable _SetURLScript
    typevariable _SetTemplateScript
    typemethod _OKTemp {} {
      set selection [$templateLB selection get]
      if {[llength $selection] < 1} {return}
      uplevel #0 "eval $_SetTemplateScript [$templateLB itemcget [lindex $selection 0] -data]"
      $dialog withdraw
      $dialog enddialog ok
    }
    typemethod _OKURL {} {
      set URL [$amazonSB formSelectedItemResponseGroupURL Large]
      if {[string equal "$URL" {}]} {return}
      uplevel #0 "eval $_SetURLScript $URL"
      $dialog withdraw
      $dialog enddialog ok
    }
    typemethod _Cancel {} {
      $dialog withdraw
      $dialog enddialog cancel
    }
    typemethod draw {args} {
      $type _createdialog
      set _SetURLScript "[from args -setURLProc {}]"
      set _SetTemplateScript "[from args -setTemplateProc {}]"
      # Init template list...
      $templateLB delete [$templateLB items]
      foreach tp [Edit::TemplateCard listOfTemplates] {
	$templateLB insert end $tp -data $tp -text $tp
      }
      return "[$dialog draw]"
    }
  }
  snit::widgetadaptor EditUpdateLogDialog {
    typevariable bannerfont {}
    typeconstructor {
      global imageDir
      if {[lsearch -exact [font families] {new century schoolbook}] >= 0} {
	set bannerfont [list {new century schoolbook} -18 bold roman]
      } else {
	set bannerfont [list times -18 bold roman]
      }
    }
    component logScroll
      component logText
    component   header
    component     facelabel
    component     headbanner
    option -title -default {Untitled} -configuremethod _SetTitle
    method _SetTitle {option value} {
      set options($option) "$value"
      $hull configure -title "$value"
      $headbanner configure -text "$value"
    }
    option -parent -readonly yes -default .
    delegate method * to logText
    delegate option -height to logText
    delegate option -width  to logText
    constructor {args} {
      set options(-parent) [from args -parent]
      installhull using Dialog::create \
		-class EditUpdateLogDialog -default 0 -cancel 0 -modal none \
		-transient yes -parent $options(-parent) -side bottom
      Dialog::add $win -name dismis -text Dismis -command [mymethod _Dismis]
      set f [Dialog::getframe $win]
      install header using frame $f.header -borderwidth {2} -relief flat
      pack $header -fill x
      install facelabel using label $header.facelabel -image Windows::FaceFrontSmall -relief flat
      pack $facelabel -side left
      install headbanner using label $header.headbanner \
	-bg yellow -fg brown -font $bannerfont -text {}
      pack $headbanner -side right -expand yes -fill both
      install logScroll using ScrolledWindow \
		$f.logScroll \
		-scrollbar vertical -auto vertical
      pack   $logScroll -expand yes -fill both
      install logText using rotext $logScroll.logText -wrap word
      pack $logText -expand yes -fill both
      $logScroll setwidget $logText
      $self configurelist $args
      $hull draw
    }
    method _Dismis {} {
      destroy $self
    }
  }    
}

package provide EditWindow 1.0
