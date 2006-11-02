#* 
#* ------------------------------------------------------------------
#* ImportV1Ascii.tcl - Import V1 Ascii
#* Created by Robert Heller on Sat Sep 30 13:12:56 2006
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
package require DatabaseFunctions

namespace eval ImportV1Ascii {
  snit::type ImportV1Ascii {
    typevariable _BlankCard -array {
	Key {}
	Title {Unknown}
	Author {Unknown}
	Subject {UNKNOWN}
	Description {}
	Location {}
	Category {}
	Media {}
	Publisher {}
	PubLocation {}
	PubDate {}
	Edition {}
	ISBN {}
    }
    variable _lookahead_ch
    option -in -readonly yes -default stdin
    constructor {args} {
      $self configurelist $args
      set _lookahead_ch {}
    }
    method _eof {} {return [eof $options(-in)]}
    method _getch {} {
      if {![string equal "$_lookahead_ch" {}]} {
	set ch "$_lookahead_ch"
	set _lookahead_ch {}
	return "$ch"
      } else {
	return "[read $options(-in) 1]"
      }
    }
    method _peek {} {
      if {![string equal "$_lookahead_ch" {}]} {
	set ch "$_lookahead_ch"
	return "$ch"
      } else {
	set _lookahead_ch "[read $options(-in) 1]"
	return "$_lookahead_ch"
      }
    }
    method _putback {ch} {
      if {![string equal "$_lookahead_ch" {}]} {
	error "Putback overflow!"
      }
      set _lookahead_ch "$ch"
      return "$ch"
    }
    method _getword {} {
      set word {}
      while {true} {
	set ch "[$self _getch]"
	if {[$self _eof]} {return}
	if {[string compare "$ch" { }] <= 0} {
	  $self _putback "$ch"
	  return "$word"
	} else {
	  append word "$ch"
	}
      }
    }
    method _getline {} {
      set line "$_lookahead_ch[gets $options(-in)]"
      set _lookahead_ch {}
      return "$line"
    }
    method _ReadQuotedString {} {
      while {![string equal "[$self _getch]" {"}] && ![$self _eof]} {}
      set result {}
      while {true} {
	set ch "[$self _getch]"
	if {[$self _eof]} {return {}}
	if {[string  equal "$ch" {"}]} {
	  break
	} elseif  {[string equal "$ch" "\\"]} {
	  append result "[$self _getch]"
	} else {
	  append result "$ch"
	}
      }
      return "$result"
    }
    method import {} {
      set numpages "[$self _getline]"
      if {![string is integer -strict "$numpages"] || [$self _eof]} {
	error "Read error (numpages)"
        return
      }
      set numkeys "[$self _getline]"
      if {![string is integer -strict "$numkeys"] || [$self _eof]} {
	error "Read error (numkeys / cards)"
	return
      }
      set numcards $numkeys
      for {set i 0} {$i < $numkeys} {incr i} {
	catch {array unset tempcard}
	array set tempcard [array get _BlankCard]
	set p "[$self _ReadQuotedString]"
	if {[string equal "$p" {}]} {
	  error "Premature EOF on file (Card $i)"
	  return
	}
	set p "[string toupper $p]"
	while {![string equal "[$self _getch]" {#}] && 
	       ![$self _eof]} {}
	if {[$self _eof]} {
	  error "Premature EOF on file (Card $i)"
	  return
	}
	set tempcard(Key) [string toupper "$p"]
	set ch "[$self _getch]"
	if {![string equal "$ch" {C}]} {
	  error "Syntax error reading Card $i: expected a C, saw a $ch"
	  return
	}
	set ch "[$self _getch]"
	if {![string equal "$ch" {(}]} {
	  error "Syntax error reading Card $i: expected a (, saw a $ch"
	  return
	}
	while {![$self _eof]} {
	  while {![$self _eof]} {
	    set ch "[$self _getch]"
	    if {[string equal "$ch" {)}]} {
	      break
	    } else if {[string compare "$ch" { }] > 0} {
	      $self _putback "$ch"
	      break
	    }
	  }
	  if {[string equal "$ch" {)}]} {break}
	  set wordbuffer [string tolower "[$self _getword]"]
	  switch -exact "$wordbuffer" {
	    :TYPE {
	      set tempcard(Media) [$self _getword]
	    }
	    :AUTHOR{
	      set tempcard(Author) [string toupper "[$self _ReadQuotedString]"]
	    }
	    :TITLE {
	      set tempcard(Title) [string toupper "[$self _ReadQuotedString]"]
	    }
	    :PUBLISHER {
	      set tempcard(Publisher) "[$self _ReadQuotedString]"
	    }
	    :CITY {
	      set tempcard(PubLocation) "[$self _ReadQuotedString]"
	    }
	    :DESCRIPTION {
	      set tempcard(Description) "[$self _ReadQuotedString]"
	    }
	    :VOLUME {
	      set tempcard(Edition) [$self _getword]
	    }
	    :YEAR {
	      set tempcard(PubDate) "1-1-[$self _getword]"
	    }
	  }
	}
	Database::InsertCard tempcard
	update
      }
      set numkeys [$self _getline]
      if {![string is integer -strict "$numkeys"] || [$self _eof]} {
	error "Read error (numkeys / numtitles)"
	return
      }
      for {set i 0} {$i < $numkeys} {incr i} {
	set p "[$self _ReadQuotedString]"
	if {[string equal "$p" {}]} {
	  error "Premature EOF on file (Title $i)"
	  return
	}
	set p "[string toupper $p]"
	while {![string equal "[$self _getch]" {#}] && 
	       ![$self _eof]} {}
	if {[$self _eof]} {
	  error "Premature EOF on file (Title $i)"
	  return
	}
	set ch "[$self _getch]"
	if {![string equal "$ch" {(}]} {
	  error "Syntax error reading Title $i: expected a (, saw a $ch"
	  return
	}
	while {![$self _eof]} {
	  while {![$self _eof]} {
	    set ch "[$self _getch]"
	    if {[string equal "$ch" {)}]} {
	      break
	    } else if {[string compare "$ch" { }] > 0} {
	      $self _putback "$ch"
	      break
	    }
	  }
	  if {[string equal "$ch" {)}]} {break}
	  set k "[$self _ReadQuotedString]"
	  if {[string equal "$k" {}]} {
	    error "Premature EOF on file (Title $i)"
	    return
	  }
	}
	update
      }
      set numkeys [$self _getline]
      if {![string is integer -strict "$numkeys"] || [$self _eof]} {
	error "Read error (numkeys / numauthors)"
	return
      }
      for {set i 0} {$i < $numkeys} {incr i} {
	set p "[$self _ReadQuotedString]"
	if {[string equal "$p" {}]} {
	  error "Premature EOF on file (Author $i)"
	  return
	}
	set p "[string toupper $p]"
	while {![string equal "[$self _getch]" {#}] && 
	       ![$self _eof]} {}
	if {[$self _eof]} {
	  error "Premature EOF on file (Author $i)"
	  return
	}
	set ch "[$self _getch]"
	if {![string equal "$ch" {(}]} {
	  error "Syntax error reading Author $i: expected a (, saw a $ch"
	  return
	}
	while {![$self _eof]} {
	  while {![$self _eof]} {
	    set ch "[$self _getch]"
	    if {[string equal "$ch" {)}]} {
	      break
	    } else if {[string compare "$ch" { }] > 0} {
	      $self _putback "$ch"
	      break
	    }
	  }
	  if {[string equal "$ch" {)}]} {break}
	  set k "[$self _ReadQuotedString]"
	  if {[string equal "$k" {}]} {
	    error "Premature EOF on file (Author $i)"
	    return
	  }
	}
	update
      }
      set numkeys [$self _getline]
      set numkeywords $numkeys
      if {![string is integer -strict "$numkeys"] || [$self _eof]} {
	error "Read error (numkeys / numkeywords)"
	return
      }
      for {set i 0} {$i < $numkeys} {incr i} {
	set p "[$self _ReadQuotedString]"
	if {[string equal "$p" {}]} {
	  error "Premature EOF on file (Keyword $i)"
	  return
	}
	set p "[string toupper $p]"
	while {![string equal "[$self _getch]" {#}] && 
	       ![$self _eof]} {}
	if {[$self _eof]} {
	  error "Premature EOF on file (Keyword $i)"
	  return
	}
	set ch "[$self _getch]"
	if {![string equal "$ch" {(}]} {
	  error "Syntax error reading Keyword $i: expected a (, saw a $ch"
	  return
	}
	set keyword "$p"
	set keys {}
	while {![$self _eof]} {
	  while {![$self _eof]} {
	    set ch "[$self _getch]"
	    if {[string equal "$ch" {)}]} {
	      break
	    } else if {[string compare "$ch" { }] > 0} {
	      $self _putback "$ch"
	      break
	    }
	  }
	  if {[string equal "$ch" {)}]} {break}
	  set k "[$self _ReadQuotedString]"
	  if {[string equal "$k" {}]} {
	    error "Premature EOF on file (Keyword $i)"
	    return
	  }
	  set key [string toupper "$k"]
	  lappend keys "$key"
	}
	Database::InsertKeysForKeyword "$keyword" $keys
	update
      }
      return [list $numcards $numkeywords]
    }
  }
}


package provide ImportV1Ascii 1.0
