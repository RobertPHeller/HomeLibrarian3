#* 
#* ------------------------------------------------------------------
#* DatabaseFunctions.tcl - Database functions
#* Created by Robert Heller on Mon Sep 11 21:46:41 2006
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
package require TclODBC
package require BWLabelComboBox

namespace eval Database {
  variable ConnectionString {}
  variable Environment {}
  variable Connection {}
  variable CardByKeyExact {}
  variable CardByKey {}
  variable CardByTitle {}
  variable CardByAuthor {}
  variable CardBySubject {}
  variable CardByKeyword {}
  variable KeywordsByKey {}
  variable DeleteKeywordsByKey {}
  variable InsertKeyword {}
  variable InsertCard {}
  variable UpdateCard {}
  variable DeleteCard {}
  variable SelectWhere {}

  variable CardsTableSQL {
Create Table Cards (
  Key CHAR(36) NOT NULL,
  Title CHAR(128) NOT NULL,
  Author CHAR(64) NOT NULL,
  Subject CHAR(128) NOT NULL,
  Description TEXT          ,
  Location CHAR(36)          ,
  Category CHAR(36)          ,
  Media CHAR(36)          ,
  Publisher CHAR(36)          ,
  PubLocation CHAR(36)          ,
  PubDate DATE			,
  Edition CHAR(36)		,
  ISBN    CHAR(20) )}
  variable KeyIndexSQL {Create Unique Index Key_index on Cards(Key)}
  variable TitleIndexSQL {Create        Index Title_index on Cards(Title)}
  variable AuthorIndexSQL {Create        Index Author_index on Cards(Author)}
  variable SubjectIndexSQL {Create        Index Subject_index on Cards(Subject)}
  variable KeywordsTableSQL {
Create Table Keywords (
  Keyword CHAR(64) NOT NULL,
  Key     CHAR(36) NOT NULL)}
  variable KeywordIndexSQL {Create        Index Keyword_index on Keywords(Keyword)}

  snit::type GetConnectionStringDialog {
    pragma -hastypeinfo    no
    pragma -hastypedestroy no
    pragma -hasinstances   no

    typecomponent dialog
    typecomponent driverScroll
    typecomponent driverLb
    typecomponent datasourceScroll
    typecomponent datasourceLb
    typecomponent saveIniLabCB
    typecomponent connectionstringEntry
    typeconstructor {
      set dialog [Dialog::create .getConnectionStringDialog \
			-class GetConnectionStringDialog \
			-side bottom -bitmap questhead \
			-modal local -title "Get Connection String" \
			-default 0 -cancel 1]
      $dialog add -name ok -text OK -command [mytypemethod _OK]
      $dialog add -name cancel -text Cancel -command [mytypemethod _Cancel]
      $dialog add -name help -text Help -command "BWHelp::HelpTopic GetConnectionStringDialog"
      set frame [$dialog getframe]
      set driverlf [LabelFrame::create $frame.driverlf \
				-text "Available Drivers" -side top]
      pack $driverlf -expand yes -fill both
      set driverScroll [$driverlf getframe].driverScroll
      ScrolledWindow::create $driverScroll -auto both -scrollbar both
      pack $driverScroll -expand yes -fill both
      set driverLb $driverScroll.lb
      ListBox::create $driverLb -selectfill yes -selectmode single -height 6
      $driverLb bindText <1> [mytypemethod _DriverB1]
      pack $driverLb -expand yes -fill both
      $driverScroll setwidget $driverLb
      set datasourcelf [LabelFrame::create $frame.datasourcelf \
				-text "Available Datasources" -side top]
      pack $datasourcelf -expand yes -fill both
      set datasourceScroll [$datasourcelf getframe].datasourceScroll
      ScrolledWindow::create $datasourceScroll -auto both -scrollbar both
      pack $datasourceScroll -expand yes -fill both
      set datasourceLb $datasourceScroll.lb
      ListBox::create $datasourceLb -selectfill yes -selectmode single \
						    -height 6
      pack $datasourceLb -expand yes -fill both
      $datasourceLb bindText <1> [mytypemethod _DatasourceB1]
      $datasourceScroll setwidget $datasourceLb
      set inifiles {}
      foreach inifile {/etc/hl.conf ~/.hlrc .hlrc} {
	if {[file writable $inifile]} {
	  lappend inifiles $inifile
	  continue
	} elseif {[file exists $inifile]} {
	  continue
	} elseif {[file writable [file dirname $inifile]]} {
	  lappend inifiles $inifile
	  continue
	}
      }
      if {[llength $inifiles] > 0} {
	set saveIniLabCB $frame.saveIni
	LabelComboBox::create $saveIniLabCB -label "Save in initfile:" \
					    -side left \
					    -values [concat none $inifiles] \
					    -editable no \
					    -text none
	pack $saveIniLabCB -fill x
      } else {
	set saveIniLabCB {}
      }
      set connectionstringEntry $frame.connectionstringEntry
      LabelEntry::create $connectionstringEntry -label "Connection String:" \
						-side left
      pack $connectionstringEntry -fill x
      $connectionstringEntry bind <Return> [mytypemethod _OK]
    }
    typevariable _Result
    typemethod _OK {} {
      set _Result "[$connectionstringEntry cget -text]"
      if {[string length "$_Result"] > 0} {
	$type _CheckSaveIni "$_Result"
	$dialog withdraw
	$dialog enddialog ok
      }
    }
    typemethod _Cancel {} {
      $dialog withdraw
      $dialog enddialog cancel
    }
    typemethod _DriverB1 {driverselection} {
      $connectionstringEntry configure -text "driver=[$driverLb itemcget $driverselection -data]"
    }
    typemethod _DatasourceB1 {datasourceselection} {
      $connectionstringEntry configure -text "dsn=[$datasourceLb itemcget $datasourceselection -data]"
    }
    typemethod _CheckSaveIni {cs} {
      if {[string equal "$saveIniLabCB" {}]} {return}
      set file [$saveIniLabCB cget -text]
      if {[string equal "$file" none]} {return}
      if {[catch [list open $file w] fp]} {return}
      puts $fp "[winfo class .].connectionString: $cs"
      close $fp
    }
    typemethod draw {args} {
      set environment [from args -evironment {}]
      if {[string length "$environment"] == 0} {
	return {}
      }
      $driverLb delete [$driverLb items]
      foreach driver [$environment drivers] {
	set dn [lindex $driver 0]
	$driverLb insert end $dn -text "$driver" -data $dn
      }
      $datasourceLb delete [$datasourceLb items]
      foreach datasource [$environment datasources] {
        set ds [lindex $datasource 0]
        $datasourceLb insert end $ds -text "$datasource" -data $ds
      }
      set button [$dialog draw]
      switch $button {
        ok {return $_Result}
	cancel {return {}}
      }
    }
  }
}

proc Database::GetConnectionString {environment} {
  return [GetConnectionStringDialog draw -evironment $environment]
}

proc Database::ConnectToDatabase {} {
  variable ConnectionString
  variable Connection
  variable Environment
  set ConnectionString [option get . connectionString ConnectionString]
  set Environment [database]
  while {1} {
#    puts stderr "*** Database::ConnectToDatabase (top of while loop): ConnectionString = '$ConnectionString'"
    if {[string equal "$ConnectionString" {}]} {
      Windows::HideSplash {
        set ConnectionString [GetConnectionString $Environment]
      }
      if {[string equal "$ConnectionString" {}]} {
        $Environment -delete
        Windows::Exit yes
      }
    }
    if {[catch [list $Environment connect "$ConnectionString"] Connection]} {
      tk_messageBox -type ok -icon error -message "$Connection"
      set Connection {}
      set ConnectionString {}
      continue
    } else {
      $Connection -acquire
    }
#    puts stderr "*** Database::ConnectToDatabase: Connection = '$Connection'"
    if {![HaveData]} {
      Windows::HideSplash {
	if {[AskCreateTables]} {
	  New 1
	} else {
	  $Connection -delete
	  set Connection {}
	  set ConnectionString {}
	  continue
	}
      }
    } else {
      break
    }
  }
#  puts stderr "*** Database::ConnectToDatabase (after while): ConnectionString = '$ConnectionString', Connection = '$Connection'"
  if {![HaveData]} {
    tk_messageBox -type ok -icon error \
	-message "Could not make a connection to a database server, sorry!"
    Windows::Exit yes
  }
}

proc Database::CloseDatabase {} {
  variable ConnectionString
  variable Environment
  variable Connection
  variable CardByKeyExact
  variable CardByKey
  variable CardByTitle
  variable CardByAuthor
  variable CardBySubject
  variable CardByKeyword
  variable KeywordsByKey
  variable DeleteKeywordsByKey
  variable InsertKeyword
  variable InsertCard
  variable UpdateCard
  variable DeleteCard
  variable SelectWhere

  if {![string equal $DeleteCard {}]} {$DeleteCard -delete;set DeleteCard {}}
  if {![string equal $UpdateCard {}]} {$UpdateCard -delete;set UpdateCard {}}
  if {![string equal $InsertCard {}]} {$InsertCard -delete;set InsertCard {}}
  if {![string equal $DeleteKeywordsByKey {}]} {$DeleteKeywordsByKey -delete;set DeleteKeywordsByKey {}}
  if {![string equal $InsertKeyword {}]} {$InsertKeyword -delete;set InsertKeyword {}}
  if {![string equal $KeywordsByKey {}]} {$KeywordsByKey -delete;set KeywordsByKey {}}
  if {![string equal $CardByKeyword {}]} {$CardByKeyword -delete;set CardByKeyword {}}
  if {![string equal $CardBySubject {}]} {$CardBySubject -delete;set CardBySubject {}}
  if {![string equal $CardByAuthor {}]} {$CardByAuthor -delete;set CardByAuthor {}}
  if {![string equal $CardByTitle {}]} {$CardByTitle -delete;set CardByTitle {}}
  if {![string equal $CardByKey {}]} {$CardByKey -delete;set CardByKey {}}
  if {![string equal $CardByKeyExact {}]} {$CardByKeyExact -delete;set CardByKeyExact {}}
  if {![string equal $SelectWhere {}]} {$SelectWhere -delete;set SelectWhere {}}
  if {![string equal $Connection {}]} {
    if {![$Connection cget -attr_autocommit]} {$Connection commit}
    $Connection -delete
    set Connection {}
  }
  if {![string equal $Environment {}]} {$Environment -delete;set Environment {}}
  set ConnectionString {}
}
  
proc Database::HaveData {} {
#  puts stderr "*** Database::HaveData"
  variable Connection
#  puts stderr "*** Database::HaveData: Connection = '$Connection'"
  if {[string equal "$Connection" {}]} {return no}
  switch [$Connection cget -identifier_case] {
    mixed -
    sensitive {set c [$Connection run tables Cards]}
    upper {set c [$Connection run tables CARDS]}
    lower {set c [$Connection run tables cards]}
  }
#  puts stderr "*** Database::HaveData: c1 = '$c1', c2 = '$c2', c3 = '$c3'"
  if {[llength $c] < 1} {
    return no
  } else {
    return yes
  }
}

proc Database::IsWritableData {} {
  variable Connection
  if {[catch "$Connection cget -attr_access_mode" accmode]} {set accmode write}
  switch "$accmode" {
    read {return no}
    write {
        set user [$Connection cget -user_name]
	set INSERT no
	set UPDATE no
	set DELETE no
	switch [$Connection cget -identifier_case] {
	  mixed -
	  sensitive {set table Cards}
	  upper     {set table CARDS}
	  lower     {set table cards}
	}
	if {[catch {
		set s [$Connection statement tableprivileges]
		$s execute [list $table]
	        } error]} {
	  set INSERT yes
	  set UPDATE yes
	  set DELETE yes
	} else {
	  while {[$s fetch row {Cat Scheme Name Grantor Grantee Privilege 
			        Is_Grantable}]} {
	    parray row
	    if {[string equal "$row(Grantee)" "$user"]} {
	      if {[string equal "$row(Privilege)" INSERT]} {set INSERT yes}
	      if {[string equal "$row(Privilege)" UPDATE]} {set UPDATE yes}
	      if {[string equal "$row(Privilege)" DELETE]} {set DELETE yes}
	    }
	  }
	}
        return [expr {$INSERT && $UPDATE && $DELETE}]
    }
  }
}

proc Database::CountMatchingCards {whereclause} {
  variable Connection

  if {![string equal "$whereclause" {}]} {
    set count [$Connection run "select distinct count(*) from cards where $whereclause"]
  } else {
    set count [$Connection run "select distinct count(*) from cards"]
  }
  return [lindex $count 0]
}

proc Database::StartWhereSelect {{whereclause {}} {orderbycolumn {}}} {
  variable Connection
  variable SelectWhere

  if {![string equal "$SelectWhere" {}]} {$SelectWhere -delete;set SelectWhere {}}
  set clauses {}
  if {![string equal "$whereclause" {}]} {
    append clauses "where $whereclause"
  }
  if {![string equal "$orderbycolumn" {}]} {
   append clauses " order by $orderbycolumn"
  }
  set SelectWhere [$Connection statement "select distinct * from cards $clauses"]
  $SelectWhere execute
}

proc Database::NextCard {rowvar} {
  upvar $rowvar row
  variable Connection
  variable SelectWhere

  if {[string equal "$SelectWhere" {}]} {return false}
  set result [$SelectWhere fetch row {Key Title Author Subject Description 
			     Location Category Media Publisher PubLocation 
			     PubDate Edition ISBN}]
  if {$result} {
    return true
  } else {
    $SelectWhere -delete
    set SelectWhere {}
    return false
  }
}


proc Database::GetCardByKey {key rowvar} {
  upvar $rowvar row
  variable Connection
  variable CardByKeyExact
  if {[string equal "$CardByKeyExact" {}]} {
    set CardByKeyExact [$Connection statement {select * from cards where key = ?}]
  }
  $CardByKeyExact execute [list [string toupper "$key"]]
  return [$CardByKeyExact fetch row {Key Title Author Subject Description 
			     Location Category Media Publisher PubLocation 
			     PubDate Edition ISBN}]
  
}
  
namespace eval Database {
  snit::widget SearchFrame {
    widgetclass SearchFrame
    hulltype frame
    component searchby
    component searcbutton
    component searchstring
    component resultscroll
    component  resultlb
    delegate method {listbox *} to resultlb
    option -selectmode -default none
    component resultbuttons
    delegate method {buttons *} to resultbuttons
    delegate option {-resultlbheight resultLbHeight ResultLbHeight} to resultlb as -height
    delegate option -relief to hull
    delegate option {-borderwidth borderWidth BorderWidth} to hull
    constructor {args} {
      $win configure -relief ridge -borderwidth 4
      install searchby using LabelComboBox::create $win.searchby \
			-label {Search Mode:} -labelwidth 14  \
			-values {Id Title Author Subject Keyword} \
			-text Title -editable no
      pack $searchby -fill x
      set sbef [frame $win.sbef -relief flat -borderwidth 0]
      pack $sbef -fill x
      install searcbutton using Button::create $sbef.searcbutton \
		-text {Search:} -width 10 -justify left -anchor w \
		-command [mymethod _DoSearch]
      pack $searcbutton -side left
      install searchstring using Entry::create $sbef.searchstring -text {}
      pack  $searchstring -side right -expand yes -fill x
      bind $searchstring <Return> [list $searcbutton invoke]
      install resultscroll using ScrolledWindow::create $win.resultscroll \
				-auto both -scrollbar both
      pack  $resultscroll -expand yes -fill both
      install resultlb using ListBox::create $resultscroll.lb -selectfill yes \
				-selectmode [from args -selectmode]
      pack $resultlb -expand yes -fill both
      $resultscroll setwidget $resultlb
      install resultbuttons using ButtonBox::create $win.resultbuttons \
	-orient horizontal -homogeneous no
      pack $resultbuttons -fill x
      $self configurelist $args
    }
    method _DoSearch {} {
      variable ::Database::Connection
      variable ::Database::CardByKey
      variable ::Database::CardByTitle
      variable ::Database::CardByAuthor
      variable ::Database::CardBySubject
      variable ::Database::CardByKeyword
  
      set mode [$searchby cget -text]
      set string "[string toupper [$searchstring cget -text]]"
      $resultlb delete [$resultlb items]
      switch -exact $mode {
	Id {
	  if {[string equal "$CardByKey" {}]} {
	    set CardByKey [$Connection statement {select distinct * from cards where key like ?}]
	  }
	  set search $CardByKey
	  set field {}
	}
	Title {
	  if {[string equal "$CardByTitle" {}]} {
	    set CardByTitle [$Connection statement {select distinct * from cards where title like ?}]
	  }
	  set search $CardByTitle
	  set field {}
	}
	Author {
	  if {[string equal "$CardByAuthor" {}]} {
	    set CardByAuthor [$Connection statement {select distinct * from cards where author like ?}]
	  }
	  set search $CardByAuthor
	  set field Author
	}
	Subject {
	  if {[string equal "$CardBySubject" {}]} {
	    set CardBySubject [$Connection statement {select distinct * from cards where subject like ?}]
	  }
	  set search $CardBySubject
	  set field Subject
	}
	Keyword {
	  if {[string equal "$CardByKeyword" {}]} {
	    set CardByKeyword [$Connection statement {select distinct * from cards where cards.key = keywords.key AND keywords.keyword LIKE ?}]
	  }
	  set search $CardByKeyword
	  set field {}
	}
      }
      $Windows::AnimatedHeader StartWorking
      set rcount 0
      $search execute [list "$string%"]
      while {[$search fetch row {Key Title Author Subject Description Location 
				 Category Media Publisher PubLocation PubDate 
				 Edition ISBN}]} {
#	parray row
	set elementText "$row(Key): "
	if {![string equal "$field" {}]} {
	  append elementText [string trim "$row($field)"]
	  append elementText { }
	}
	append elementText [string trim "$row(Title)"]
	$resultlb insert end $row(Key) -data "$row(Key)" -text "$elementText"
	incr rcount
      }
      if {$rcount == 0} {
	set message "Found no matches\nfor \"$string\""
      } else {
	set message "Found $rcount match"
	if {$rcount > 1} {append message "es"}
	append message "\nfor \"$string\""
      }
#      puts stderr "*** Database::Search:  message = '$message'"
      $Windows::AnimatedHeader EndWorking "$message" 
    }
  }
}  

proc Database::GetKeywordsForKey {key} {
  variable Connection
  variable KeywordsByKey

  if {[string equal "$KeywordsByKey" {}]} {
    set CardByKeyword [$Connection statement {select keyword from keywords where key = ?}]
  }
  $CardByKeyword execute [list [string toupper "$key"]]
  set keywords {}
  while {[$CardByKeyword fetch row {Keyword}]} {
    lappend keywords "$row(Keyword)"
  }
  return $keywords
}

proc Database::New {{dontask 0}} {
  variable Connection
  variable CardsTableSQL
  variable KeyIndexSQL
  variable TitleIndexSQL
  variable AuthorIndexSQL
  variable SubjectIndexSQL
  variable KeywordsTableSQL
  variable KeywordIndexSQL
  if {!$dontask} {set dontask [AskCreateTables]}
  if {!$dontask} {return}
  catch {
    $Connection run {drop Index Keyword_index}
    $Connection run {drop Table Keywords}
    $Connection run {drop Index Subject_index}
    $Connection run {drop Index Author_index}
    $Connection run {drop Index Title_index}
    $Connection run {drop Index Key_index}
    $Connection run {drop Table Cards}
  }
  $Connection run "$CardsTableSQL"
  $Connection run "$KeyIndexSQL"
  $Connection run "$TitleIndexSQL"
  $Connection run "$AuthorIndexSQL"
  $Connection run "$SubjectIndexSQL"
  $Connection run "$KeywordsTableSQL"
  $Connection run "$KeywordIndexSQL"
}

proc Database::AskCreateTables {} {
  return [tk_messageBox -type yesno -icon question\
		-message "Do you really want to (Re-)Create the database?"]
}

proc Database::InsertCard {dataArray {LogText {}}} {
  variable InsertCard
  variable Connection
  upvar $dataArray data

  if {[string equal "$InsertCard" {}]} {
    set InsertCard [$Connection statement {insert into cards values (?,?,?,?,?,?,?,?,?,?,?,?,?)}]
  }
  set res [catch {$InsertCard run [list \
		[string toupper "$data(Key)"] \
		[string toupper "$data(Title)"] \
		[string toupper "$data(Author)"] \
		[string toupper "$data(Subject)"] \
		"$data(Description)" \
		"$data(Location)" \
		"$data(Category)" \
		"$data(Media)" \
		"$data(Publisher)" \
		"$data(PubLocation)" \
		"$data(PubDate)" \
		"$data(Edition)" \
		"$data(ISBN)" \
	]} error]
  if {![string equal "$LogText" {}]} {
    $LogText insert end "InsertCard: $error\n"
  }
  return [expr {$res == 0}]
}

proc Database::InsertKeywordsForKey {key keywordlist {LogText {}}} {
  variable Connection
  variable InsertKeyword

  set key [string toupper "$key"]
  if {[string equal "$InsertKeyword" {}]} {
    set InsertKeyword [$Connection statement {insert into Keywords values(?,?)}]
  }
  set res 0
  foreach kw $keywordlist {
    incr res [catch {$InsertKeyword run [list [string toupper "$kw"] "$key"]} error]
    if {![string equal "$LogText" {}]} {
      $LogText insert end "InsertKeyword: $error\n"
    }
  }
  return [expr {$res == 0}]
}

proc Database::InsertKeysForKeyword {keyword keylist {LogText {}}} {
  variable Connection
  variable InsertKeyword

  if {[string equal "$InsertKeyword" {}]} {
    set InsertKeyword [$Connection statement {insert into Keywords values(?,?)}]
  }
  set res 0
  set keyword [string toupper "$keyword"]
  foreach key $keylist {
    set key [string toupper "$key"]
    incr res [catch {$InsertKeyword run [list "$keyword" "$key"]} error]
    if {![string equal "$LogText" {}]} {
      $LogText insert end "InsertKeyword: $error\n"
    }
  }
  return [expr {$res == 0}]
}

proc Database::DeleteKeywordsForKey {key {LogText {}}} {
  variable DeleteKeywordsByKey
  variable Connection

  if {[string equal "$DeleteKeywordsByKey" {}]} {
    set DeleteKeywordsByKey [$Connection statement {delete from Keywords where key = ?}]
  }
  set res [catch {$DeleteKeywordsByKey run [list [string toupper "$key"]]} error]
  if {![string equal "$LogText" {}]} {
    $LogText insert end "DeleteKeywordsByKey $error\n"
  }
  return [expr {$res == 0}]
}

proc Database::UpdateCard {dataArray {LogText {}}} {
  variable UpdateCard
  variable Connection
  upvar $dataArray data

  if {[string equal "$UpdateCard" {}]} {
    set UpdateCard [$Connection statement {update cards set Title = ?,
							    Author = ?,
							    Subject = ?,
							    Description = ?,
							    Location = ?,
							    Category = ?,
							    Media = ?,
							    Publisher = ?,
							    PubLocation = ?,
							    PubDate = ?,
							    Edition = ?,
							    ISBN = ? where key = ?}]
  }
  set res [catch {$UpdateCard run [list \
		[string toupper "$data(Title)"] \
		[string toupper "$data(Author)"] \
		[string toupper "$data(Subject)"] \
		"$data(Description)" \
		"$data(Location)" \
		"$data(Category)" \
		"$data(Media)" \
		"$data(Publisher)" \
		"$data(PubLocation)" \
		"$data(PubDate)" \
		"$data(Edition)" \
		"$data(ISBN)" \
		[string toupper "$data(Key)"] \
	]} error]
  if {![string equal "$LogText" {}]} {
    $LogText insert end "UpdateCard: $error\n"
  }
  return [expr {$res == 0}]
}

proc Database::DeleteCard {key {LogText {}}} {
  variable DeleteCard
  variable Connection

  if {[string equal "$DeleteCard" {}]} {
    set DeleteCard [$Connection statement {delete from cards where key = ?}]
  }
  set res [catch {$DeleteCard run [list [string toupper "$key"]]} error]
  if {![string equal "$LogText" {}]} {
    $LogText insert end "DeleteCard: $error\n"
  }
  return [expr {$res == 0}]
}

proc Database::QuoteValue {string} {
  regsub -all {['\\]} "$string" {\\\0} string
  return "'$string'"
}

package provide DatabaseFunctions 1.0

