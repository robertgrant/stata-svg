/* Stata-SVG project
	Grant und Morris 2017
	
	hexbin command
	
	this is part 2, taking a grid and count,
		plotting it as scatter
		and editing the SVG to draw hexagons
*/

/*
	Things to consider later:
		get aspect ratio from svg file
			tm - Stata's aspect ratio is not quite what it claims;
			I hope this doesn't affect getting it from svg
			rg - in retrospect, this hexbin command doesn't amend an existing Stata SVG, it
				makes a new one. We could allow an aspect ratio option, but we don't have to read it.
				However, it's easy as we just get the extent of the two axes in pixels.
		option for orientation of hexagons
			tm - requires redefining stuff from nrows in terms of ncols
			rg - yeah we'll leave that for now
!!!		write <symbol> and <use>s when you detect </svg> in the input file
		option to make hexs with d3
		
	Notes:
		there are alternate rows with nhexc and nhexc-1 hexagons;
			this implies parallel-horizontal orientation: <=>
			
*/

version 14.2

// macros you might wanna change or turn into arguments
global wdir "~/Dropbox/stata-svg/hexbin"
global nhexr 20 // number of hexagons per row
global aspect 1 // aspect ratio
matrix color_ramp = (100, 200, 180 \ ///
				     90, 190, 170 \ ///
				     80, 180, 160 \ ///
					 70, 170, 150)
global svgfile "scatter-for-hexbin.svg"
global replace "replace"

clear all
capture file close _all
capture log close
cd "$wdir"
log using "hexbin-part-2-log.smcl", replace smcl
global output "output.svg"

// calculate some other stuff once
global nhexc=1+floor($aspect * $nhexr) // note this is the wider row
global nhex=($nhexr * $nhexc) + floor($nhexr / 2) // SHOULD THIS BE MINUS?


//######################################################################################
// here's some fake data, pending part 1 which will get the temporary data of counts per hex
set obs $nhex
gen x=1+mod(_n-1, 2*$nhexc - 1)
replace x=x-($nhexc - 1) if x>($nhexc -1)
gen temp=(x==1)
gen y=sum(temp)
replace y=y*1.5 // this 1.5 changes with straight edge orientation
replace x=x-0.5 if mod(y,3)==0 // this 3 changes with straight edge orientation
replace x=x*sqrt(3) // this sqrt(3) changes with straight edge orientation
replace temp=sin(y/5)-(x/17)
egen colorcat=cut(temp), group(4)

* Quick & dirty idea of density in hexbin
//twoway scatter y x [aweight=temp], msym(o) msize(vsmall) aspect(.88)9
twoway (scatter y x if colorcat==0, mcolor("198 56 128")) ///
       (scatter y x if colorcat==1, mcolor("160 94 128")) ///
	   (scatter y x if colorcat==2, mcolor("122 132 128")) ///
	   (scatter y x if colorcat==3, mcolor("85 170 128")) ///
	   , legend(off) graphregion(color(white))
// do we need to specify aspect?
graph export "$svgfile", $replace
//######################################################################################

// put data to one side for later
preserve
clear
set obs $nhex
gen x=.
gen y=.
gen fill=""

//	open svg file
tempname fh
tempname fh2
tempname fh3
tempfile endfile
file open `fh' using "$svgfile", read text // write if replacing
file open `fh2' using "$output", write text replace // if writing to a new file, this holds the SVG up to the circles
file open `fh3' using "`endfile'", write text replace // this holds the SVG after the circles (gets deleted later)

//	get row & col distances
file read `fh' svgline
local loopcount=1
local circount=0
local marked=0
//dis `"this line is: `svgline'"' // ***waypoint***
while r(eof)==0 {
	//dis `"this line is: `svgline'"'
	local svglinelen=strlen(`"`svgline'"')
	if `svglinelen'>7 {
		local temp = substr(`"`svgline'"',2,7)
		//dis `"chars 2-7 are: `temp'"' // ***waypoint***
		if substr(`"`svgline'"',2,7)=="<circle" {
				local ++circount
			// locate first quotation mark (start of x)
				local svglinequot=strpos(`"`svgline'"',`"""')
				//dis "found a quote at pos `svglinequot'" // ***waypoint***
				local cutline = substr(`"`svgline'"',`svglinequot'+1,.)
				//dis `"cutline is: `cutline'"' // ***waypoint***
			// locate second quotation mark (end of x)
				local svglinequot=strpos(`"`cutline'"',`"""')
			// extract x
				local svgx=substr(`"`cutline'"',1,`svglinequot'-1)
				//dis "I think x is: `svgx'" // ***waypoint***
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// locate third quotation mark (start of y)
				local svglinequot=strpos(`"`cutline'"',`"""')
				//dis "found a quote at pos `svglinequot'" // ***waypoint***
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
				//dis `"cutline is: `cutline'"' // ***waypoint***
			// locate fourth quotation mark (end of y)
				local svglinequot=strpos(`"`cutline'"',`"""')
			// extract y
				local svgy=substr(`"`cutline'"',1,`svglinequot'-1)
				//dis "I think y is: `svgy'" // ***waypoint***
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// locate & extract fill color
				local svglinequot=strpos(`"`cutline'"',"fill:#")
				//dis "found a fill at pos `svglinequot'" // ***waypoint***
				local svgfill=substr(`"`cutline'"',`svglinequot'+6,6)
				//dis "I think fill is: `svgfill'" // ***waypoint***
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// add to data
				replace x=`svgx' in `circount'
				replace y=`svgy' in `circount'
				replace fill="`svgfill'" in `circount'
				local ++loopcount
		}
		// if not a circle, write the line to the output file
		else {
			if `circount'>0 & `marked'==0 {
				local marked=1 // if this is the first line after the circles
				file write `fh3' `"`svgline'"' _n	// start writing to endfile			
			}
			if `marked'==1 {
				file write `fh3' `"`svgline'"' _n // carry on writing to endfile
			}
			else {
				file write `fh2' `"`svgline'"' _n // carry on writing to output (not yet reached circles)
			}
		}
	}
	file read `fh' svgline
}
file close `fh'
file close `fh2'
file write `fh3' "</svg>" _n
file close `fh3'
file open `fh3' using "`endfile'", read text

// find y-distance between circles
tempfile working
save "`working'", replace
/* some possible speed ups:
	don't save and use, gen tempname=_n; sort y ... sort tempname; drop tempname;
	don't sort: summ y; local ymin=r(min); summ y if y!=`ymin'; local ymin2=r(min) ...
*/
sort y
collapse (mean) x, by(y)
local hexscale=(y[2]-y[1])/sqrt(3) // for vertical straight edge; 1.5 otherwise
use "`working'", replace
//	get points for <symbol> with required size hex
// needs to swap columns if horizontal straight edge
// vertical straight edge matrix: (0,1\0.866,0.5\0.866,-0.5\0,-1\-0.866,-0.5\-0.866,0.5\0,1)
local hb1=1*`hexscale'
local hb5=0.5*`hexscale'
local hb866=0.866*`hexscale'
local hexpoints = "0,`hb1' `hb866',`hb5' `hb866',-`hb5' 0,-`hb1' -`hb866',-`hb5' -`hb866',`hb5' 0,`hb1'"


// open output read write
file open `fh2' using "$output", read write text
file seek `fh2' eof  // move to end

// add symbol
file write `fh2' "<symbol>" _n
file write `fh2' _tab `"<polygon id="hexagon" points="`hexpoints'" />"' _n
file write `fh2' "</symbol>" _n

// add uses
file write `fh2' "<g>" _n
forvalues i=1/`circount' {
	local cx=x[`i']
	local cy=y[`i']
	local cf=fill[`i']
	file write `fh2' _tab `"<use href="#hexagon" x="`cx'" y="`cy'" style="fill:#`cf'; stroke:#`cf';"/>"' _n
}
file write `fh2' "</g>" _n

// add contents of endfile
file read `fh3' endline
while r(eof)==0 {
	file write `fh2' `"`endline'"' _n
	file read `fh3' endline
}

// close files
file close `fh2'
file close `fh3'

save "delete-me.dta", replace // ***waypoint***

// get data back
restore

capture log close
