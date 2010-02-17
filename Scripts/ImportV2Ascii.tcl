#* 
#* ------------------------------------------------------------------
#* ImportV2Ascii.tcl - Import V2 Ascii Files
#* Created by Robert Heller on Sat Sep 16 16:38:46 2006
#* ------------------------------------------------------------------
#* Modification History: $Log: ImportV2Ascii.tcl,v $
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
package require DatabaseFunctions

namespace eval ImportV2Ascii {
  snit::type ImportV2Ascii {

#
# From Card.h
#
    typevariable _CardType -array {
	B Book
	M Magazine
	D CD
	C {Audio Cassette}
	A Album
	V {VHS Video}
	S {Beta Video}
	8 {Eight MM}
	E {Eight Track}
	4 DAT
	O Other
	a {}
	b {}
	c {}
	d {}
	e {}
	f {}
	g {}
	h {}
	i {}
	j {}
    }
    variable CardType
    typevariable _LocationType -array {
	S {On Shelf}
	L {On Loan}
	O {On Order}
	D {Destroyed}
	s {In Storage}
        U Unknown
	a {}
	b {}
	c {}
	d {}
	e {}
	f {}
	g {}
	h {}
	i {}
	j {}
    }
    variable LocationType
    typevariable _BlankCard -array {
	Key {}
	Title {Unknown}
	Author {Unknown}
	Subject {Unknown}
	Description {}
	Location {}
	Category {}
	Media {}
	Publisher {}
	Publisher {}
	PubLocation {}
	PubDate {}
	Edition {}
	ISBN {}
    }
    typevariable _NumCardTypes 22
    typevariable _IndexUC1 12
    typevariable _NumLocationTypes 16
    typevariable _IndexUL1 6
    typevariable _Categories -array {0 {}}
    variable Categories
    typevariable _SignatureWord {Library-V2-Ascii}
    typevariable _RecordType CardRecord

    option -in -readonly yes -default stdin

    constructor {args} {
      array set CardType [array get _CardType]
      array set LocationType [array get _LocationType]
      array set Categories [array get _Categories]
      $self configurelist $args
    }
    method _GetBuffer {} {
      set buffer "[gets $options(-in)]"
      while {![info complete "$buffer"]} {
	append buffer "\n[gets $options(-in)]"
      }
      return "$buffer"
    }
    method import {} {
      if {![string equal "[gets $options(-in)]" "$_SignatureWord"]} {
	error "Read mismatch on header in \"$options(-file)\""
	return
      }
      set numpages [gets $options(-in)]
      if {![string is integer $numpages]} {
	error "Format error on file (numpages): \"$options(-file)\""
	return
      }
      for {set ikey $_IndexUC1} {$ikey < $_NumCardTypes} {incr ikey} {
	set buffer "[$self _GetBuffer]"
	foreach {code name} $buffer {
	  set CardType($code) "$name"
	}
      }
      for {set ikey $_IndexUL1} {$ikey < $_NumLocationTypes} {incr ikey} {
	set buffer "[$self _GetBuffer]"
	foreach {code name} $buffer {
	  set LocationType($code) "$name"
	}
      }
      set numcats [gets $options(-in)]
      if {![string is integer $numcats]} {
	error "Format error on file (numcats): \"$options(-file)\""
	return
      }
      for {set ikey 0} {$ikey < $numcats} {incr ikey} {
	set buffer "[$self _GetBuffer]"
	foreach {code name} $buffer {
	  set Categories($code) "$name"
	}
      }
      set numcards [gets $options(-in)]
      if {![string is integer $numcards]} {
	error "Format error on file (numcards): \"$options(-file)\""
	return
      }
      for {set ikey 0} {$ikey < $numcards} {incr ikey} {
	set buffer "[$self _GetBuffer]"
	if {[llength $buffer] == 1} {set buffer [lindex $buffer 0]}
	array unset data
	array set data [array get _BlankCard]
	set data(Key) "[string toupper [lindex $buffer 0]]"
#	puts stderr "*** $self import: data(Key) = '$data(Key)'"
#	puts stderr "*** $self import: lindex \$buffer 1 = '[lindex $buffer 1]', _RecordType = '$_RecordType'"
	if {![string equal "[lindex $buffer 1]" "$_RecordType"]} {
	  error "Format error (bad record): $buffer"
	  return
	}
        set vol {}
        set locdetail {}
	foreach ele [lrange $buffer 2 end] {
	  foreach {key val} $ele {
	    switch -exact $key {
	      cardtype {
	        set data(Media) "$CardType($val)"
	      }
	      author {
		set data(Author) "$val"
	      }
	      title {
		set data(Title) "$val"
	      }
	      publisher {
		set data(Publisher) "$val"
	      }
	      city {
		set data(PubLocation) "$val"
	      }
	      description {
		set data(Description) "$val"
	      }
	      vol {
		set vol "$val"
	      }
	      year {
		set data(PubDate) "$val-01-01"
	      }
	      locationtype {
		set data(Location) "$LocationType($val)"
	      }
	      locationdetail {
		set locdetail "$val"
	      }
	      categorycode {
		set data(Category) "$Categories($val)"
	      }
	    }
	  }
	}
	if {[string length "$locdetail"] > 0} {
	  append data(Location) ", $locdetail"
	}
	if {$vol > 0} {
	  append data(Description) "\nVolume: $vol"
	}
	Database::InsertCard data
	update
      }
      set numtitles [gets $options(-in)]
      if {![string is integer $numtitles]} {
	error "Format error on file (numtitles): \"$options(-file)\""
	return
      }
      for {set ikey 0} {$ikey < $numtitles} {incr ikey} {
	set buffer "[$self _GetBuffer]"
      }
      set numauthors [gets $options(-in)]
      if {![string is integer $numauthors]} {
	error "Format error on file (numauthors): \"$options(-file)\""
	return
      }
      for {set ikey 0} {$ikey < $numauthors} {incr ikey} {
	set buffer "[$self _GetBuffer]"
      }
      set numsubjects [gets $options(-in)]
      if {![string is integer $numsubjects]} {
	error "Format error on file (numsubjects): \"$options(-file)\""
	return
      }
      for {set ikey 0} {$ikey < $numsubjects} {incr ikey} {
	set buffer "[$self _GetBuffer]"
	if {[llength $buffer] == 1} {set buffer [lindex $buffer 0]}
	set keyword "[lindex $buffer 0]"
	Database::InsertKeywordsForKey "$keyword" [lrange $buffer 1 end]
	update
      }
      return [list $numcards $numsubjects]
    }
  }
}

package provide ImportV2Ascii 1.0
