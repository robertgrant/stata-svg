// parse and tag Stata SVG files

// add ids

/* add classes: xaxis, yaxis, xtitle, ytitle, xtick, ytick, xlabel, ylabel, gridline, 
				√graphregion, √plotregion, line, area, marker, markerlabel, rspike, 
				rcapupper, rcaplower
*/

/* add comment block containing Stata code that would read the coordinates of the data in:
		both the pixels and the original variable values, also the pixels for the plotregion
		
	add option to allocate different classes to markers and lines depending on their color
	add option to allocate different classes to markers and lines, given the number of 
		observations in each superimposed graph
*/

cd "~/git/stata-svg"

capture program drop svgtag
program define svgtag, rclass
syntax anything [, Replace Metadata]
args inputfile outputfile


//arguments:
if `"`inputfile'"'=="" {
	dis as error "You must specify an input file"
	error 100
}
if `"`outputfile'"'=="" & "`replace'"=="" {
	dis as error "You must specify either an output filename or the replace option"
	error 100
}
if `"`outputfile'"'=="" & "`replace'"=="replace" {
	local outputfile `"`inputfile'"'
}

// check the inputfile exists
confirm file `"`inputfile'"'


tempname fi
tempname fo
file open `fi' using `"`inputfile'"', read text
file open `fo' using `"`outputfile'"', write text replace

local linecount 1
local rectcount 0
local circlecount 1
file read `fi' readline

// check that it's an svg file

while `"`readline'"'!="</svg>" {
	local writeverbatim=1 // indicator for writing unchanged at the end of the loop
	//dis "I'm writing line number `linecount': "
	//dis substr(`"`readline'"',1,20)
	
	// get Stata version
	if substr(`"`readline'"',1,21)=="<!-- This is a Stata " {
		local stataversion=substr(`"`readline'"',22,4) // this assumes the format of that comment line doesn't change
	}

	// get canvas size and viewBox
	if substr(`"`readline'"',1,12)=="<svg version" {
		local widthpos1=strpos(`"`readline'"',"width=")+7
		local widthpos2=strpos(`"`readline'"',"height=")-1	
		local heightpos1=strpos(`"`readline'"',"height=")+8
		local heightpos2=strpos(`"`readline'"',"viewBox=")-1	
		local viewBoxpos1=strpos(`"`readline'"',"viewBox=")+9	
		local viewBoxpos2=strpos(`"`readline'"',"xmlns=")-1
		local returnwidth=substr(`"`readline'"',`widthpos1',`widthpos2'-`widthpos1'-1)
		local returnheight=substr(`"`readline'"',`heightpos1',`heightpos2'-`heightpos1'-1)
		local returnviewBox=substr(`"`readline'"',`viewBoxpos1',`viewBoxpos2'-`viewBoxpos1'-1)
	}
	
	// identify graphregion and plotregion, extract dimensions, and add class
	if substr(`"`readline'"',2,5)=="<rect" & `rectcount'==0 {
		local xpos1=strpos(`"`readline'"',"x=")+3
		local xpos2=strpos(`"`readline'"',"y=")-1	
		local ypos1=strpos(`"`readline'"',"y=")+3
		local ypos2=strpos(`"`readline'"',"width=")-1	
		local returngrx=substr(`"`readline'"',`xpos1',`xpos2'-`xpos1'-1)
		local returngry=substr(`"`readline'"',`ypos1',`ypos2'-`ypos1'-1)
		local widthpos1=strpos(`"`readline'"',"width=")+7
		local widthpos2=strpos(`"`readline'"',"height=")-1	
		local heightpos1=strpos(`"`readline'"',"height=")+8
		local heightpos2=strpos(`"`readline'"',"style=")-1	
		local returngrwidth=substr(`"`readline'"',`widthpos1',`widthpos2'-`widthpos1'-1)
		local returngrheight=substr(`"`readline'"',`heightpos1',`heightpos2'-`heightpos1'-1)
		local graphregion1=substr(`"`readline'"',1,`heightpos2')
		local graphregion2=substr(`"`readline'"',`heightpos2'+1,.)
		file write `fo' `"`graphregion1' class="graphregion" `graphregion2'"' _n
		local writeverbatim=0
		local ++rectcount
	}
	else if substr(`"`readline'"',2,5)=="<rect" & `rectcount'==1 {
		local xpos1=strpos(`"`readline'"',"x=")+3
		local xpos2=strpos(`"`readline'"',"y=")-1	
		local ypos1=strpos(`"`readline'"',"y=")+3
		local ypos2=strpos(`"`readline'"',"width=")-1	
		local returnprx=substr(`"`readline'"',`xpos1',`xpos2'-`xpos1'-1)
		local returnpry=substr(`"`readline'"',`ypos1',`ypos2'-`ypos1'-1)
		local widthpos1=strpos(`"`readline'"',"width=")+7
		local widthpos2=strpos(`"`readline'"',"height=")-1	
		local heightpos1=strpos(`"`readline'"',"height=")+8
		local heightpos2=strpos(`"`readline'"',"style=")-1	
		local returnprwidth=substr(`"`readline'"',`widthpos1',`widthpos2'-`widthpos1'-1)
		local returnprheight=substr(`"`readline'"',`heightpos1',`heightpos2'-`heightpos1'-1)
		local plotregion1=substr(`"`readline'"',1,`heightpos2')
		local plotregion2=substr(`"`readline'"',`heightpos2'+1,.)
		file write `fo' `"`plotregion1' class="plotregion" `plotregion2'"' _n
		local writeverbatim=0
		local ++rectcount
	}

	// identify circles and add class and id
	if substr(`"`readline'"',2,7)=="<circle" {
		local stylepos1=strpos(`"`readline'"',"style=")
		local circle1=substr(`"`readline'"',1,`stylepos1'-1)
		local circle2=substr(`"`readline'"',`stylepos1',.)
		file write `fo' `"`circle1' class="markercircle" id="circle`circlecount'" `circle2'"' _n
		local ++circlecount
		local writeverbatim=0
	}

	// identify lines and add class
	
	// identify y-axis
	
	// identify y ticks, add class and extract variable-to-pixel conversion
	
	// identify x-axis
	
	// identify x ticks, add class and extract variable-to-pixel conversion
	
	
	if `writeverbatim'==1 {
		file write `fo' `"`readline'"' _n
	}
	
	// identify Stata comment and add our own (afterwards)
	if substr(`"`readline'"',1,20)=="<!-- This is a Stata" {
		if "`metadata'"=="metadata" {
			file write `fo' _n "<!-- Amended to add id, class and metadata using the svgtag command by Robert Grant and Tim Morris. -->" _n
		}
		else {
			file write `fo' _n "<!-- Amended to add id and class using the svgtag command by Robert Grant and Tim Morris. -->" _n
		}
	}

	file read `fi' readline
	local writeverbatim=1
	local ++linecount
}
file write `fo' "</svg>" _n _n

file close `fi'
file close `fo'

// return metadata
return local stataversion "`stataversion'"
return local width "`returnwidth'"
return local height "`returnheight'"
return local viewBox "`returnviewBox'"
return local plotregionwidth "`returnprwidth'"
return local plotregionheight "`returnprheight'"
return local plotregionx "`returnprx'"
return local plotregiony "`returnpry'"
return local graphregionwidth "`returngrwidth'"
return local graphregionheight "`returngrheight'"
return local graphregionx "`returngrx'"
return local graphregiony "`returngry'"

end

svgtag "hexbin/scatter-for-hexbin.svg" "tagged.svg", 
