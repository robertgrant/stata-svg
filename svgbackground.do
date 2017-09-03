/* to do:
	verify earliest Stata version that can run this
*/

version 14
capture program drop svgbackground
program define svgbackground
syntax anything [, Replace]
args inputfile imagefile outputfile

//arguments:
confirm file `"`inputfile'"'
confirm file `"`imagefile'"'
if `"`outputfile'"'=="" & "`replace'"=="" {
	dis as error "You must specify either an output filename or the replace option"
	error 100
}
if `"`outputfile'"'=="" & "`replace'"=="replace" {
	tempfile tempout
	local outputfile `"`tempout'"'
}

// get the plotregion
tempfile rubbish
svgtag `"`inputfile'"' "`rubbish'"
local prx=r(plotregionx)
local pry=r(plotregiony)
local prw=r(plotregionwidth)
local prh=r(plotregionheight)

tempname fi
tempname fo
file open `fi' using `"`inputfile'"', read text
file open `fo' using `"`outputfile'"', write text replace

local linecount 1
local rectcount 0
local done 0
file read `fi' readline
while `"`readline'"'!="</svg>" {
	if `rectcount'<2 & `done'==0 {
		if substr(`"`readline'"',2,5)=="<rect" {
			local ++rectcount
		}
	}
	file write `fo' `"`readline'"' _n
	if `rectcount'==2 & `done'==0 {
		file write `fo' `"<image href="`imagefile'" x="`prx'" y="`pry'" height="`prh'" width="`prw'" preserveAspectratio="xMinYMax" />"' _n
		local done 1
	}
	local ++linecount
	file read `fi' readline
}
file write `fo' "</svg>" _n _n

file close `fi'
file close `fo'

// replace option
if `"`outputfile'"'=="" & "`replace'"=="replace" {
	if lower("$S_OS")=="windows" {
		shell del `"`inputfile'"'
		shell rename `"`outputfile'"' `"`inputfile'"'
	}
	else {
		shell rename -f `"`outputfile'"' `"`inputfile'"'
	}
}

end

svgbackground "hexbin/scatter-for-hexbin.svg" "mapbox.png" "scatter-with-image.svg"
