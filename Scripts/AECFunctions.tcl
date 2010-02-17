#* 
#* ------------------------------------------------------------------
#* AECFunctions.tcl - Amazon E-Commerce Functions
#* Created by Robert Heller on Wed Sep 13 19:21:00 2006
#* ------------------------------------------------------------------
#* Modification History: $Log: AECFunctions.tcl,v $
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
package require SearchWindow
set httpV [package require http]
#puts stderr "*** AECFunctions: loaded http $httpV"
set xmlV [package require xml]
#puts stderr "*** AECFunctions: loaded xml $xmlV"

namespace eval AmazonECommerce {
  variable BaseURL {http://webservices.amazon.com/onca/xml?Service=AWSECommerceService}
  variable DWSAccessKeyID {0XD7CD0X6G5QAPH28A02}
  snit::widget AmazonSearch {
    widgetclass AmazonSearch
    hulltype frame

    typeconstructor {
      global imageDir
      image create photo AmazonECommerce::AmazonLogo -file [file join "$imageDir" AmazonLogo.gif]
    }

    variable _ElementStack {}
    variable _Item_ASIN {}
    variable _Item_Title {}
    variable _Item_ProductGroup {}
    variable _Item_Author {}
    component searchFrame
    component   searchIndexCB
    component   searchKeywordsLE
    component   amazonLogoL
    component   searchButtonB
    component lookupFrame
    component   asinLE
    component   lookupB
    component resultsFrame
    component   scrollW
    component     resultsLB
    component resultbuttons
    method _URLEncode {in} {
      regsub -all {%}  $in "%25" in
      regsub -all { }  $in "%20" in
      regsub -all {\?} $in "%3f" in
      return $in
    }
    method _FormItemSearchRequest {searchIndex keywords} {
      set URL "$AmazonECommerce::BaseURL"
      set keywords [$self _URLEncode "$keywords"]
      append URL "&AWSAccessKeyId=$AmazonECommerce::DWSAccessKeyID"
      append URL "&Operation=ItemSearch"
      append URL "&SearchIndex=$searchIndex"
      append URL "&Keywords=$keywords"
      append URL "&ResponseGroup=Small"
      return "$URL"
    }
    method _FormItemLookupRequest {itemid} {
      set URL "$AmazonECommerce::BaseURL"
      append URL "&AWSAccessKeyId=$AmazonECommerce::DWSAccessKeyID"
      append URL "&Operation=ItemLookup"
      append URL "&ItemId=$itemid"
      append URL "&ResponseGroup=Small"
      return "$URL"
    }
    method viewItem {{parent .}} {
      set URL [$self formSelectedItemResponseGroupURL Large]
      if {[string equal "$URL" {}]} {return}
      AmazonECommerce::ViewAmazonData .viewAmazonData%AUTO% -url "$URL" \
		-transientparent $parent
    }
    method formSelectedItemResponseGroupURL {responseGroup} {
      set selecteditems [$resultsLB selection get]
      if {[llength $selecteditems] < 1} {return {}}
      set URL "$AmazonECommerce::BaseURL"
      append URL "&AWSAccessKeyId=$AmazonECommerce::DWSAccessKeyID"
      append URL "&Operation=ItemLookup"
      append URL "&ItemId=[join $selecteditems {,}]"
      append URL "&ResponseGroup=$responseGroup"
      return "$URL"
    }

    method _DoSearch {} {
      set URL [$self _FormItemSearchRequest "[$searchIndexCB cget -text]" \
					"[$searchKeywordsLE cget -text]"]
      $Windows::AnimatedHeader StartWorking
      if {[catch {
      set token [::http::geturl "$URL" -blocksize 2048 \
					-progress [mymethod _UpdateIdle]]
      switch [::http::status $token] {
	ok {	
	    $resultsLB delete [$resultsLB items]
	    set parser [::xml::parser \
			-elementstartcommand [mymethod _ElementStart] \
			-characterdatacommand [mymethod _CharacterData] \
			-elementendcommand [mymethod _ElementEnd]]
	    $parser parse [::http::data $token]
	    set rcount [llength [$resultsLB items]]
	    set string "[$searchKeywordsLE cget -text]"
	    if {$rcount == 0} {
	      set message "Found no matches\nfor \"$string\""
	    } else {
	      set message "Found $rcount match"
	    if {$rcount > 1} {append message "es"}
	      append message "\nfor \"$string\""
	    }	    
	}
        eof {
	    set message "No Response from Amazon."
	}
	error {
	    set message "[::http::error $token]"
	}
      }
      ::http::cleanup $token
      } error]} {set message "$error"}
      $Windows::AnimatedHeader EndWorking "$message"
    }
    method _ElementStart {name attlist args} {
      switch -exact "$name" {
	Item {
	  set _Item_ASIN {}
	  set _Item_Title {}
	  set _Item_ProductGroup {}
	  set _Item_Author {}
	}
	Creator {
	  set index [lsearch $attlist Role]
	  if {$index >= 0} {
	    set name [lindex $attlist [expr {$index + 1}]]
	  }
	}
      }
      set _ElementStack [concat $name $_ElementStack]
    }
    method _ElementEnd {name args} {
      set _ElementStack [lrange $_ElementStack 1 end]
      if {[string equal "$name" Item]} {
        $resultsLB insert end $_Item_ASIN \
		-text [format {%10s %-30s %s (%s)} $_Item_ASIN $_Item_Author \
					   $_Item_Title $_Item_ProductGroup] \
		-data [list $_Item_ASIN $_Item_Title $_Item_ProductGroup \
			    $_Item_Author]
      }
    }
    method _CharacterData {data} {
      switch [lindex $_ElementStack 0] {
	ASIN {set _Item_ASIN "$data"}
	Title {set _Item_Title "$data"}
	ProductGroup {set _Item_ProductGroup "$data"}
	Creator -
	Artist -
	Actor -
        Director -
        Foreword -
	Contributor -
	Author {lappend _Item_Author "$data"}
      }
    }
    method _RemoveDashes {ISBN} {
      regsub -all -- {-} "$ISBN" {} ISBN
      regsub -all {[[:space:]]} "$ISBN" {} ISBN
      return "$ISBN"
    }
    method _DoLookup {} {
      set URL [$self _FormItemLookupRequest "[$self _RemoveDashes [$asinLE cget -text]]"]
      $Windows::AnimatedHeader StartWorking
      if {[catch {
      set token [::http::geturl "$URL" -blocksize 2048 \
					-progress [mymethod _UpdateIdle]]
      switch [::http::status $token] {
	ok {	
	    $resultsLB delete [$resultsLB items]
	    set parser [::xml::parser \
			-elementstartcommand [mymethod _ElementStart] \
			-characterdatacommand [mymethod _CharacterData] \
			-elementendcommand [mymethod _ElementEnd]]
	    $parser parse [::http::data $token]
	    set rcount [llength [$resultsLB items]]
	    set string "[$asinLE cget -text]"
	    if {$rcount == 0} {
	      set message "Found no matches\nfor \"$string\""
	    } else {
	      set message "Found $rcount match"
	    if {$rcount > 1} {append message "es"}
	      append message "\nfor \"$string\""
	    }	    
	}
        eof {
	    set message "No Response from Amazon."
	}
	error {
	    set message "[::http::error $token]"
	}
      }
      ::http::cleanup $token
      } error]} {set message "$error"}
      $Windows::AnimatedHeader EndWorking "$message"
    }
    method _UpdateIdle {token total current} {update idle}
    delegate method {buttons *} to resultbuttons
    option {-responsegroup responseGroup ResponseGroup} -readonly yes \
			-default Small
    delegate option {-resultlbheight resultLbHeight ResultLbHeight} to resultsLB as -height
    delegate method {listbox *} to resultsLB
    delegate option -relief to hull
    delegate option {-borderwidth borderWidth BorderWidth} to hull
    constructor {args} {
      $win configure -relief ridge -borderwidth 4
#      install searchFrame using LabelFrame::create $win.searchFrame \
#			-text Search -side top -relief flat -borderwidth 0
      install searchFrame using frame $win.searchFrame
      pack $searchFrame -expand yes -fill both
#      set f [$searchFrame getframe]
      set f $searchFrame
      install searchIndexCB using LabelComboBox::create \
			$f.searchIndexCB -label Search: \
			-labelwidth 10 -values {Books DVD Music VHS Video} \
			-editable no -text Books
      grid configure $searchIndexCB -column 0 -row 0 -sticky we
      install searchKeywordsLE using LabelEntry::create \
			$f.searchKeywordsLE -label Keywords: \
			-labelwidth 10 -text {}
      grid configure $searchKeywordsLE -column 0 -row 1 -sticky we
      install amazonLogoL using Label::create $f.amazonLogoL \
			-image AmazonECommerce::AmazonLogo
      grid configure $amazonLogoL -column 1 -row 0 -sticky e
      install searchButtonB using Button::create $f.searchButtonB \
			-text {Search Amazon.com} \
			-width 17 -command [mymethod _DoSearch]
      grid configure $searchButtonB -column 1 -row 1 -sticky we
      $searchKeywordsLE bind <Return> "$searchButtonB invoke"
      grid columnconfigure $f 0 -weight 1 
      grid columnconfigure $f 1 -weight 0
#      install lookupFrame using LabelFrame::create $win.lookupFrame \
#			-text Lookup -side top -relief flat -borderwidth 0
      install lookupFrame using frame $win.lookupFrame
      pack $lookupFrame -expand yes -fill both
#      set f [$lookupFrame getframe]
      set f $lookupFrame
      install asinLE using LabelEntry::create \
		$f.asinLE -label ASIN/ISBN: -labelwidth 10 -text {}
      pack $asinLE -side left -expand yes -fill x
      install lookupB using Button::create $f.lookupB \
			-text {Lookup Amazon.com} \
			-width 17 -command [mymethod _DoLookup]
      pack $lookupB -side right
      $asinLE bind <Return> "$lookupB invoke"
#      install resultsFrame using LabelFrame::create $win.resultsFrame \
#			-text Results -side top -relief flat -borderwidth 0
      install resultsFrame using frame $win.resultsFrame
      pack $resultsFrame -expand yes -fill both
#      set f [$resultsFrame getframe]
      set f $resultsFrame
      install scrollW using ScrolledWindow::create $f.scrollW \
			-auto both -scrollbar both
      pack $scrollW -expand yes -fill both
      install resultsLB using ListBox::create $scrollW.lb -selectfill yes \
				-selectmode single
      pack $resultsLB -expand yes -fill both
      $scrollW setwidget $resultsLB
      install resultbuttons using ButtonBox::create $win.resultbuttons \
	-orient horizontal -homogeneous no
      pack $resultbuttons -fill x
      $self configurelist $args
    }
  }
  snit::type stack {
    variable _TheStack {}
    method push {element} {
      set _TheStack [lreplace $_TheStack -2 -1 "$element"]
      return "$element"
    }
    method pop {} {
      set top "[lindex $_TheStack 0]"
      set _TheStack [lrange $_TheStack 1 end]
      return "$top"
    }
    method top {} {
      return "[lindex $_TheStack 0]"
    }
    method emptyP {} {
      return [eval {[llength $_TheStack] == 0}]
    }
    constructor {} {
      set _TheStack {}
    }
    destructor {
      unset _TheStack
    }
  }
  snit::type AmazonDataProcessor {
    component _ElementStack
    option -url -readonly yes -default {}
    option -callback -readonly yes -default {}
    constructor {args} {
      $self configurelist $args
      set _ElementStack [AmazonECommerce::stack %AUTO%]
    }
    destructor {
      catch {$_ElementStack destroy}
    }
    method _ElementStart {name attlist args} {
      $_ElementStack push [list "$name" "$attlist"]
    }
    method _ElementEnd {name args} {
      set top "[$_ElementStack pop]"
    }
    method _CharacterData {data} {
      set top "[$_ElementStack top]"
      if {[string length "$options(-callback)"] > 0} {
	set command $options(-callback)
	lappend command "$top"
	lappend command "$data"
	uplevel #0 "$command"
      }
    }
    method _UpdateIdle {token total current} {update idle}
    method process {} {
      set token [::http::geturl "$options(-url)" -blocksize 2048 \
				-progress [mymethod _UpdateIdle]]
      switch [::http::status $token] {
	ok {
	     set parser [::xml::parser \
			-elementstartcommand [mymethod _ElementStart] \
			-characterdatacommand [mymethod _CharacterData] \
			-elementendcommand [mymethod _ElementEnd]]
	     $parser parse [::http::data $token]
	}
	eof {
	     tk_messageBox -type ok -icon warning -message "No Response from Amazon."
	}
	error {
	     tk_messageBox -type ok -icon error -message "[::http::error $token]"
	}
      }
      ::http::cleanup $token
    }
  }
  snit::widgetadaptor ViewAmazonData {
    option -transientparent -readonly yes -default .
    option -url -readonly yes -default {}
    delegate option -menu to hull
    delegate option -width to hull
    delegate option -height to hull
    component titleLE
    component authorLE
    component dateLE
    component publisherLE
    component isbnLE
    component editionLE
    component mediaLE
    component descriptionLF
    component   descriptionSW
    component     descriptionTX
    component buttons
    constructor {args} {
      set options(-transientparent) [from args -transientparent]
      installhull using Windows::HomeLibrarianTopLevel \
		-transientparent $options(-transientparent)
      set frame [$hull getframe]
      install titleLE using LabelEntry::create $frame.titleLE \
		-label "Title:" -labelwidth 15 -editable no
      pack $titleLE -fill x
      install authorLE using LabelEntry::create $frame.authorLE \
		-label "Author:" -labelwidth 15 -editable no
      pack $authorLE -fill x
      install dateLE using LabelEntry::create $frame.dateLE \
		-label "Date:" -labelwidth 15 -editable no
      pack $dateLE -fill x
      install publisherLE using LabelEntry::create $frame.publisherLE \
		-label "Publisher:" -labelwidth 15 -editable no
      pack $publisherLE -fill x
      install isbnLE using LabelEntry::create $frame.isbnLE \
		-label "ISBN/ASIN:" -labelwidth 15 -editable no
      pack $isbnLE -fill x
      install editionLE using LabelEntry::create $frame.editionLE \
		-label "Edition:" -labelwidth 15 -editable no
      pack $editionLE -fill x
      install mediaLE using LabelEntry::create $frame.mediaLE \
		-label "Media:" -labelwidth 15 -editable no
      pack $mediaLE -fill x
      install descriptionLF using LabelFrame::create $frame.descriptionLF \
		-text Description: -width 15
      pack $descriptionLF -expand yes -fill both
      set f [$descriptionLF getframe]
      install descriptionSW using ScrolledWindow::create $f.descriptionSW \
		-scrollbar vertical -auto vertical
      pack $descriptionSW  -expand yes -fill both
      install descriptionTX using rotext $descriptionSW.descriptionTX \
		-wrap word
      pack $descriptionTX -expand yes -fill both
      $descriptionSW setwidget $descriptionTX
      install buttons using ButtonBox::create $frame.buttons -orient horizontal
      pack $buttons -expand yes -fill both
      $buttons add -name print -text {Print Info} \
		-command [mymethod _PrintInfo]
      $buttons add -name dismis -text {Dismis} \
		-command [list destroy $self] \
		-default active
      $buttons add -name help -text {Help} \
		-command "BWHelp::HelpTopic ViewAmazonData"
      $self configurelist $args
      AmazonECommerce::GetAmazonData "$options(-url)" [mymethod _FillInData]
    }
    method _PrintInfo {} {
      set infoText {}
      append infoText "Title:        [$titleLE cget -text]\n"
      append infoText "Author:       [$authorLE cget -text]\n"
      append infoText "Date:         [$dateLE cget -text]\n"
      append infoText "Publisher:    [$publisherLE cget -text]\n"
      append infoText "ISBN/ASIN:    [$isbnLE cget -text]\n"
      append infoText "Edition:      [$editionLE cget -text]\n"
      append infoText "Media:        [$mediaLE cget -text]\n"
      append infoText "Description:  [$descriptionTX get 1.0 end-1c]"
      Print::PrintText "$infoText" -title "[$titleLE cget -text]" \
				   -pstitle "[$titleLE cget -text]"
    }
    method _FillInData {field value} {
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
	    $authorLE configure -text "$value ($name)"
	  } else {
	    $authorLE configure -text "$authorSoFar, $value ($name)"
	  }
	  $hull configure -title "[$authorLE cget -text]: [$titleLE cget -text]"
	}
	Creator {
	  set authorSoFar "[$authorLE cget -text]"
	  set roleI [expr {[lsearch -regexp $attlist {[rR]ole}] + 1}]
	  if {$roleI > 0} {
	    append value " ([lindex $attlist $roleI])"
	  }
	  if {[string equal "$authorSoFar" {}]} {
	    $authorLE configure -text "$value"
	  } else {
	    $authorLE configure -text "$authorSoFar, $value"
	  }
	  $hull configure -title "[$authorLE cget -text]: [$titleLE cget -text]"
	}
	Title {
	  set titleSoFar "[$titleLE cget -text]"
	  if {[string equal "$titleSoFar" {}]} {
	    $titleLE         configure -text "$value"
	    $hull configure -title "[$authorLE cget -text]: [$titleLE cget -text]"
	  }
	}
	ReleaseDate -
	PublicationDate {
	  set dateSoFar "[$dateLE cget -text]"
	  if {[string equal "$dateSoFar" {}]} {
	    $dateLE configure -text "$value"
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
	ListmaniaLists  -
	ListmaniaList  -
	RequestId -
	RequestProcessingTime  -
	IsValid -
	ItemId -
	ResponseGroup -
	SalesRank -
	Amount -
	CurrencyCode -
	FormattedPrice -
	Manufacturer -
	NumberOfItems -
	TotalNew -
	TotalUsed -
	TotalCollectible -
	TotalRefurbished -
	TotalOffers -
	TotalOfferPages -
	MerchantId -
	GlancePage -
	Condition -
	SubCondition -
	OfferListingId -
	Availability -
	IsEligibleForSuperSaverShipping -
	AverageRating -
	TotalReviews -
	TotalReviewPages -
	Rating -
	HelpfulVotes -
	CustomerId -
	TotalVotes -
	Date -
	ASIN -
	BrowseNodeId -
	Name -
	ListId  -
	ListName {
	}
	Height -
	Width -
	Length -
	Weight {
	  set unitsI [expr {[lsearch -regexp $attlist {[Uu]nits}] + 1}]
	  if {$unitsI > 0} {
	    set units "[lindex $attlist $unitsI]"
	    if {![string  equal -nocase "$units"  "pixels"]} {
	      $descriptionTX insert end "$name $value $units\n"
	    }
	  } else {
	    $descriptionTX insert end "$name $value\n"
	  }
	}	
	default {
	  $descriptionTX insert end "$name $attlist $value\n"
	}
      }
    }
  }
}

proc AmazonECommerce::GetAmazonData {url callback} {
  set dataproc [AmazonECommerce::AmazonDataProcessor \
			%AUTO% -url "$url" -callback "$callback"]
  $dataproc process
  $dataproc destroy
}




package provide AECFunctions 1.0
