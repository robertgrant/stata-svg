/* Stata-SVG project
	Grant und Morris 2017
	
	hexbin command
	
	this is part 2, taking a grid and count,
		plotting it as scatter
		and editing the SVG to draw hexagons
*/

/*
	Things to do:
		get aspect ratio from svg file
		option for orientation of hexagons
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

// calculate some other stuff once
global nhexc=1+floor($aspect * $nhexr) // note this is the wider row
global nhex=($nhexr * $nhexc) + floor($nhexr / 2)

// here's some fake data, pending part 1 which will get the temporary data of counts per hex
set obs $nhex
gen x=1+mod(_n-1, 2*$nhexc - 1)
replace x=x-($nhexc - 1) if x>($nhexc -1)
gen temp=(x==1)
gen y=sum(temp)
replace x=x-0.5 if mod(y,2)==0
replace temp=sin(y/5)-(x/10)
egen colorcat=cut(temp), group(4)

twoway (scatter y x if colorcat==0) ///
       (scatter y x if colorcat==1) ///
	   (scatter y x if colorcat==2) ///
	   (scatter y x if colorcat==3) ///
	   , legend(off) graphregion(color(white))
graph export "$svgfile", $replace

// put data to one side for later
preserve

//	open svg file
tempname fh
file open `fh' using "$svgfile", read write text

//	get row & col distances
file read `fh' svgline
//dis `"this line is: `svgline'"' // ***waypoint***
while r(eof)==0 {
	dis `"this line is: `svgline'"'
	local svglinelen=strlen(`"`svgline'"')
	if `svglinelen'>7 {
		local temp = substr(`"`svgline'"',2,7)
		//dis `"chars 2-7 are: `temp'"' // ***waypoint***
		if substr(`"`svgline'"',2,7)=="<circle" {
			// locate first quotation mark (start of x)
				local svglinequot=strpos(`"`svgline'"',`"""')
				//dis "found a quote at pos `svglinequot'" // ***waypoint***
				local cutline = substr(`"`svgline'"',`svglinequot'+1,.)
				//dis `"cutline is: `cutline'"' // ***waypoint***
			// locate second quotation mark (end of x)
				local svglinequot=strpos(`"`cutline'"',`"""')
			// extract x
				local svgx=substr(`"`cutline'"',1,`svglinequot')
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
				local svgy=substr(`"`cutline'"',1,`svglinequot')
				//dis "I think y is: `svgy'" // ***waypoint***
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
			// locate fill color
				local svglinequot=strpos(`"`cutline'"',"fill:#")
				dis "found a quote at pos `svglinequot'" // ***waypoint***
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
				dis `"cutline is: `cutline'"' // ***waypoint***
			// extract y
				local svgy=substr(`"`cutline'"',1,`svglinequot')
				dis "I think y is: `svgy'" // ***waypoint***
				local cutline = substr(`"`cutline'"',`svglinequot'+1,.)
		}
	}
	file read `fh' svgline
}
file close `fh'

//	write <defs> with required size 
//	add multiple <use> elements

// get data back
restore

capture log close
