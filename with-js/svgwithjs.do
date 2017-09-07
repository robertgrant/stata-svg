
capture program drop svgwithjs
program define svgwithjs
syntax anything [, Htmlfile(string) MOVar(string) MOHeading(string) Replace]
args svgfile

// arguments
if "`moheading'"!="" {
	local moheading "<h3>`moheading'</h3>" // add tags
}

// tag svg file
tempfile taggedfile
svgtag "`svgfile'", outputfile("`taggedfile'") replace

//	open svg file
tempname fi
tempname fo
file open `fi' using `"`taggedfile'"', read text 
file open `fo' using `"`htmlfile'"', write text replace 

// start up the HTML file
file write `fo' "<!DOCTYPE html>" _n
file write `fo' "<html>" _n
file write `fo' "<head>" _n
file write `fo' _tab "<script type='text/javascript' src='http://d3js.org/d3.v3.min.js'></script>" _n
file write `fo' "</head>" _n _n
file write `fo' "<body>" _n

// copy SVG into the HTML file
file read `fi' svgline
local loopcount=1
local writing=0
//dis `"this line is: `svgline'"' // ***waypoint***
while r(eof)==0 {
	//dis `"this line is: `svgline'"'
	if substr(`"`svgline'"',1,4)=="<svg" {
		local writing=1
	}
	if `writing'==1 {
		file write `fo' `"`svgline'"' _n
	}
	local ++loopcount
	file read `fi' svgline
}

// paragraph to hold the text
file write `fo' _n "`moheading'" _n
file write `fo' "<p class='showmo'></p>" _n _n

// start the JavaScript
file write `fo' "<script type='text/javascript'>" _n
file write `fo' _tab "var modata = [" _n

// add the extra variable as an array
qui count
local nn=r(N)-1
forvalues i=1/`nn' {
	local mo=`movar'[`i']
	file write `fo' _tab _tab `""`mo'","' _n
}
local mo=`movar'[`nn'+1]
file write `fo' _tab _tab `""`mo'"];"' _n _n

// add the D3 code
file write `fo' _tab "d3.select('svg')" _n
file write `fo' _tab(2) ".selectAll('circle.markercircle')" _n
file write `fo' _tab(3) ".on('mouseover', function(){" _n
file write `fo' _tab(4) "var myid = d3.select(this).attr('id').substring(6);" _n
file write `fo' _tab(4) "d3.select('p.showmo').text(modata[myid-1]);" _n
file write `fo' _tab(3) "});" _n
file write `fo' "</script>" _n

// finish the HTML file
file write `fo' "</body>"
file write `fo' "</html>"
end








// example run
clear
cd "~/git/stata-svg/with-js"
do "../svgtag.do"
cd "~/git/stata-svg/with-js"
sysuse auto
scatter price mpg
graph export "example.svg", replace
svgwithjs "example.svg", htmlfile("output.html") movar(make) moheading("The make of this car is:")

