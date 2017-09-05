version 14.2

clear all
capture file close _all
capture log close
cd "~/Dropbox/stata-svg/hexbin"
log using "hexbin-log.smcl", replace smcl

// define program here




// ############## Part 1 user inputs #############
local rows 13
local cols 17
local d 1 // d may be set to 1 in general so probably remove (unless useful later for y,x scaling)
local gridmax = max(`rows',`cols')
local aspect = (.5*sqrt(3)*(`rows'+1))/(`cols'+1) // Stata does something funny with aspect that is easy to see with hexes
di `aspect'
// ###############################################


// ############## Part 2 user inputs #############
global wdir "~/Dropbox/stata-svg/hexbin"
global nhexr 20 // number of hexagons per row
global aspect 1 // aspect ratio
matrix color_ramp = (100, 200, 180 \ ///
				     90, 190, 170 \ ///
				     80, 180, 160 \ ///
					 70, 170, 150) // replace with tokenized anything
global svgfile "scatter-for-hexbin.svg"
global replace "replace"
global output "output.svg"
global nhexc=1+floor($aspect * $nhexr) // note this is the wider row
global nhex=($nhexr * $nhexc) + floor($nhexr / 2) // SHOULD THIS BE MINUS?
global aspect = ($nhexr *sqrt(3)/2)/$nhexc // aspect ratio
// ###############################################







// ############# Tim's fake data ################
drawnorm y x, n(500) clear
replace y = y+5 if runiform() > .7
// ##############################################



// ############## Part 1 : Generate square grid ###############
* Because of fillin, it's good to make a large square of gridmax by gridmax
* then fillin and separate out the grids
gen int ygrid = 1+2*(_n-1) in 1/`=(`gridmax'+1)/2' // for first grid, y is only evens
gen int xgrid = 2*(_n-1) in 1/`=(`gridmax'+1)/2' // for first grid, y is only odds
fillin xgrid ygrid // fillin is pretty good, but must be a better way!
//scatter yg xg
* convenient to put into mata to remove fillin-expanded rows
* (would be so easy with multiple datasets)
putmata YX1 = (ygrid xgrid), omitmissing replace
replace ygrid = ygrid-1 // now convert grid 1 to grid 2
replace xgrid = xgrid+1
putmata YX2 = (ygrid xgrid), omitmissing replace
mata: YX = YX1 \ YX2
	drop if _fillin
	drop ygrid xgrid _fillin
getmata (ygrid xgrid) = YX, force
replace ygrid = . if ygrid>`rows'-1
replace xgrid = . if xgrid>`cols'-1
//scatter ygrid xgrid, ylab(0(1)`=`rows'-1') xlab(0(1)`=`cols'-1') // check grid vals are as required
// ############################################################


// ################# Part 1 - scale and count x and y ####################
* Have to scale x and y data first (our first reference to y and x)
summ y //, meanonly
	local ymin = r(min) // needed for later when we will rescale the grid
	local ymax = r(max)
	gen float `ysc' = ((y-`r(min)')/(`r(max)'-`r(min)'))*(`rows')
summ x //, meanonly
	local xmin = r(min) // needed for later when we will rescale the grid
	local xmax = r(max)
	gen float `xsc' = ((x-`r(min)')/(`r(max)'-`r(min)'))*(`cols')
gen long count = . // the whole thing has been leading to this variable!
levelsof ygrid, local(ylevs)
levelsof xgrid, local(xlevs)
* Essentially we are checking if scaled x is within =/-1 and if 
quietly {
foreach yc of local ylevs {
	foreach xc of local xlevs {
		count if  ygrid==`yc' & xgrid==`xc' // only want to bother counting if the grid combo exists
		if r(N) > 0 {
			di as text "yc = " as result `yc' as text ", xc = " as result `xc'
 			qui count if (`xsc' > `xc' - (1*`d'))	///
				& (`xsc' < `xc' + (1*`d'))	///
				& (`ysc' < `yc' + 1 - (.5*(`xsc'-`xc'))) ///
				& (`ysc' < `yc' + 1 + (.5*(`xsc'-`xc'))) ///
				& (`ysc' > `yc' - 1 - (.5*(`xsc'-`xc'))) ///
				& (`ysc' > `yc' - 1 + (.5*(`xsc'-`xc')))
			replace count = `r(N)' if ygrid==`yc' & xgrid==`xc'
		}
	}
}
}
* Rescale the grids to actual var scale now that we have counts
replace ygrid = ((ygrid/`rows')*(`ymax'-`ymin')) + `ymin'
replace xgrid = ((xgrid/`cols')*(`xmax'-`xmin')) + `xmin'
// #######################################################################


// ################### Part 1 demo with a circle bin ####################
* The aspect only works if the bins fill the plotregion. It's hard to make this happen.
tw (scatter ygrid xgrid /*[fw=count]*/ , msym(o)),	///
	ylab(minmax, format(%9.2fc))	///
	xlab(minmax, format(%9.2fc))	///
	aspect(`aspect') name(circ_result, replace)
// ######################################################################




// ############# Robert's fake data ################
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
twoway (scatter y x if colorcat==0, mcolor("198 56 128")) ///
       (scatter y x if colorcat==1, mcolor("160 94 128")) ///
	   (scatter y x if colorcat==2, mcolor("122 132 128")) ///
	   (scatter y x if colorcat==3, mcolor("85 170 128")) ///
	   , xlab(minmax, format(%9.0fc)) ylab(minmax, format(%9.0fc))	///
		 aspect($aspect ) legend(off) graphregion(color(white))
graph export "$svgfile", $replace
// #################################################






// ######################## Part 2 ############################
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

// ***waypoint***
//save "delete-me.dta", replace 

// get data back
restore
// ####################################################################

capture log close


