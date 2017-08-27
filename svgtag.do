// parse and tag Stata SVG files

// add ids

/* add classes: xaxis, yaxis, xtitle, ytitle, xtick, ytick, xlabel, ylabel, gridline, 
				graphregion, plotregion, line, area, marker, markerlabel, rspike, 
				rcapupper, rcaplower
*/

/* add comment block containing Stata code that would read the coordinates of the data in:
		both the pixels and the original variable values, also the pixels for the plotregion
*/

cd "~/git/stata-svg"

//arguments:
global inputfile "hexbin/scatter-for-hexbin.svg"
global outputfile "tagged.svg"

tempname fi
tempname fo
file open `fi' using "$inputfile", read text
file open `fo' using "$outputfile", write text replace

local linecount 1
file read `fi' readline
while `"`readline'"'!="</svg>" {
	dis "I'm writing line number `linecount': "
	dis substr(`"`readline'"',1,20)
	
	// get canvas size and viewBox
	if substr(`"`readline'"',1,12)=="<svg version" {
		local widthpos1=strpos(`"`readline'"',"width=")+7
		local widthpos2=strpos(`"`readline'"',"height=")-1	
		local heightpos1=strpos(`"`readline'"',"height=")+8
		local heightpos2=strpos(`"`readline'"',"viewBox=")-1	
		local viewBoxpos1=strpos(`"`readline'"',"viewBox=")+9	
		local heightpos2=strpos(`"`readline'"',"xmlns=")-1
		local returnwidth=substr(`"`readline'"',`widthpos1',`widthpos2'-`widthpos1')
	}
	
	// identify graphregion and plotregion and add class
	
	// identify 
	
	file write `fo' `"`readline'"' _n
	// identify Stata comment and add our own (afterwards)
	if substr(`"`readline'"',1,20)=="<!-- This is a Stata" {
		file write `fo' _n "<!-- Amended to add id, class and metadata using the svgtag command by Robert Grant and Tim Morris. -->" _n
	}

	file read `fi' readline
	local ++linecount
}
file write `fo' "</svg>" _n _n

file close `fi'
file close `fo'

return local width "`returnwidth'"
return local height "`returnheight'"
return local viewBox "`viewBox'"

