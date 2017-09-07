version 14.2

/*
	A CONVENTION:
	"vertical straight edge" means hexagons like this:
	 /\
	|  |
	 \/
	while "horizontal straight edge" means:
	 _
	/ \
	\_/
	 
*/

clear all
webuse iris
cd "~/git/stata-svg/hexbin"

// define program here
/*capture program drop svghex
program define svghex
syntax
*/


// ############## User inputs #############
local svgfile "irisgrid.svg"
local replace "replace"
local output "irishex.svg"
local rows 13
local cols 17 
local twopts "" // other twoway options, should come in asis
/* 
	With vertical straight edges, alternate rows of hexagons have (`cols'/2)+1 and (`cols'/2)-1 hexagons across.
	So, cols has to be an odd integer.
*/
local xvar "sepwid"
local yvar "seplen"
local ncat 4 // number of categories (hexagon colours)
matrix color_ramp = (100, 200, 180 \ ///
				     90, 190, 170 \ ///
				     80, 180, 160 \ ///
					 70, 170, 150) // replace with tokenized anything
local col1 "198 56 128"
local col2 "160 94 128"
local col3 "122 132 128"
local col4 "85 170 128" // replace with tokenized anything
// NEED TO CHECK IF N OF TOKENS = ncat

// ############### Derived macros ##################
local gridmax = max(`rows',`cols')
local aspect = (.5*sqrt(3)*(`rows'+1))/(`cols'+1)
local shortcols = floor(`cols'/2) // could there be rounding error here...?
local longcol = `shortcols'+1
local nhex=(`rows'*`shortcols') + floor(`rows'/2) 
dis "rows = `rows', short cols = `shortcols', long cols = `longcols', nhex = `nhex'"


tempname ygrid xgrid count
tempvar xsc ysc

// ############## Generate square grid ###############
preserve
* Because of fillin, it's good to make a large square of gridmax by gridmax
* then fillin and separate out the grids
if _N < `gridmax' set obs `gridmax'
gen int `ygrid' = 1+2*(_n-1) in 1/`=(`gridmax'+1)/2' // for first grid, y is only evens
gen int `xgrid' = 2*(_n-1) in 1/`=(`gridmax'+1)/2' // for first grid, y is only odds
fillin `xgrid' `ygrid' // fillin is pretty good, but must be a better way!
* convenient to put into mata to remove fillin-expanded rows
* (would be so easy with multiple datasets)
putmata YX1 = (`ygrid' `xgrid'), omitmissing replace
replace `ygrid' = `ygrid'-1 // now convert grid 1 to grid 2
replace `xgrid' = `xgrid'+1
putmata YX2 = (`ygrid' `xgrid'), omitmissing replace
mata: YX = YX1 \ YX2
	drop if _fillin
	drop `ygrid' `xgrid' _fillin
getmata (`ygrid' `xgrid') = YX, force
replace `ygrid' = . if `ygrid'>`rows'-1
replace `xgrid' = . if `xgrid'>`cols'-1


// ################# Scale and count x and y ####################
* Have to scale x and y data first (our first reference to y and x)
summ `yvar' //, meanonly
	local ymin = r(min) // needed for later when we will rescale the grid
	local ymax = r(max)
	gen float `ysc' = ((`yvar'-`r(min)')/(`r(max)'-`r(min)'))*(`rows')
summ `xvar' //, meanonly
	local xmin = r(min) // needed for later when we will rescale the grid
	local xmax = r(max)
	gen float `xsc' = ((`xvar'-`r(min)')/(`r(max)'-`r(min)'))*(`cols')
gen long `count' = . // the whole thing has been leading to this variable!
levelsof `ygrid', local(ylevs)
levelsof `xgrid', local(xlevs)
* Essentially we are checking if scaled x is within +/-1 and if y falls above or below the sloped lines (vertical flat edge)
quietly {
foreach yc of local ylevs {
	foreach xc of local xlevs {
		count if  `ygrid'==`yc' & `xgrid'==`xc' // only want to bother counting if the grid combo exists
		if r(N) > 0 {
			di as text "yc = " as result `yc' as text ", xc = " as result `xc'
 			qui count if (`xsc' > `xc' - (1))	///
				& (`xsc' < `xc' + (1))	///
				& (`ysc' < `yc' + 1 - (.5*(`xsc'-`xc'))) ///
				& (`ysc' < `yc' + 1 + (.5*(`xsc'-`xc'))) ///
				& (`ysc' > `yc' - 1 - (.5*(`xsc'-`xc'))) ///
				& (`ysc' > `yc' - 1 + (.5*(`xsc'-`xc')))
			replace `count' = `r(N)' if `ygrid'==`yc' & `xgrid'==`xc'
		}
	}
}
}
* Rescale the grids to actual var scale now that we have counts
replace `ygrid' = ((`ygrid'/`rows')*(`ymax'-`ymin')) + `ymin'
replace `xgrid' = ((`xgrid'/`cols')*(`xmax'-`xmin')) + `xmin'


// #################### Make interim SVG scatterplot ###################
egen colorcat=cut(`count'), group(`ncat')
// OPEN DO-FILE AND WRITE OUT EACH CATEGORY LINE LIKE THIS, THEN RUN
twoway (scatter `yvar' `xvar' if colorcat==0, mcolor("`col1'")) ///
       (scatter `yvar' `xvar' if colorcat==1, mcolor("`col2'")) ///
	   (scatter `yvar' `xvar' if colorcat==2, mcolor("`col3'")) ///
	   (scatter `yvar' `xvar' if colorcat==3, mcolor("`col4'")) ///
	   , xlab(minmax, format(%9.0fc)) ylab(minmax, format(%9.0fc))	///
		 aspect($aspect ) legend(off) graphregion(color(white))
// PASS TWOWAY OPTIONS ALONG HERE
graph export `"`svgfile'"', `replace' `twopts'


// #################### Examine interim SVG file and load details into data #######################
// make new data to hold what's in the interim SVG file in pixels, color codes etc
clear
set obs `nhex'
gen x=.
gen y=.
gen fill=""

//	open svg file
tempname fh
tempname fh2
tempname fh3
tempfile endfile
file open `fh' using `"`svgfile'"', read text // write if replacing
file open `fh2' using `"`output'"', write text replace // if writing to a new file, this holds the SVG up to the circles
file open `fh3' using "`endfile'", write text replace // this holds the SVG after the circles (gets deleted later)

//	get row & col distances
file read `fh' svgline
local loopcount=1
local circount=0
local marked=0
while r(eof)==0 {
	//dis `"this line is: `svgline'"'
	local svglinelen=strlen(`"`svgline'"')
	if `svglinelen'>7 {
		local temp = substr(`"`svgline'"',2,7)
		if substr(`"`svgline'"',2,7)=="<circle" {
				local ++circount
			// locate first quotation mark (start of x)
				local svglinequot=strpos(`"`svgline'"',`"""')
				local cutline = substr(`"`svgline'"',`svglinequot'+1,.)
			// locate second quotation mark (end of x)
				local svglinequot=strpos(`"`cutline'"',`"""')
			// extract x
				local svgx=substr(`"`cutline'"',1,`svglinequot'-1)
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// locate third quotation mark (start of y)
				local svglinequot=strpos(`"`cutline'"',`"""')
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// locate fourth quotation mark (end of y)
				local svglinequot=strpos(`"`cutline'"',`"""')
			// extract y
				local svgy=substr(`"`cutline'"',1,`svglinequot'-1)
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// locate & extract fill color
				local svglinequot=strpos(`"`cutline'"',"fill:#")
				local svgfill=substr(`"`cutline'"',`svglinequot'+6,6)
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// add to data
				replace x=`svgx' in `circount'
				replace y=`svgy' in `circount'
				replace fill="`="`svgfill''" in `circount'
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


// #################### Write hexagons to the output file ####################
file open `fh2' using `"`output'"', read write text
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

// #################### Copy the rest of the SVG to the output file ####################
file read `fh3' endline
while r(eof)==0 {
	file write `fh2' `"`endline'"' _n
	file read `fh3' endline
}

// close files
file close `fh2'
file close `fh3'

// ***waypoint***
//save "delete-me.dta", replace 

// get data back
restore

//end



log using "hexbin-log.smcl", replace smcl
//svghex ...
capture log close



