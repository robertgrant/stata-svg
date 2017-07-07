/* 
	Stata SVG manipulation commands
	Tim Morris & Robert Grant, 2017
*/

// #####################################################################
// ######################## add semi-transparency  #####################
// #####################################################################

/* 
	To do:
	this adds specified opacity (alpha channel) to all the circles (other objects can follow)
	it could become a more generic command to add or amend style attributes
	next, we will break down the objects by color or other attributes
	we also need to identify those in the plotregion
	we could allow actions on certain parts of the plotregion
	or individual objects 
	if hexalpha not alpha, convert
	if replace option then delete fin and rename fout with system calls
	require replace if outfile exists
	capture bracket makes sure the files are closed, no matter what
*/

/*
	Notes:
	This assumes ASCII files throughout. -file export .svg- makes UTF-8 encoded text files, so a
		character in the ASCII set will occupy one byte, and those beyond in Unicode occupy two bytes.
		Pure Unicode has two bytes everywhere. This matters because we get strpos() positions and that 
		counts the bytes. At present, we extract and manipulate things like "fill:#1A476F", which by SVG
		convention have no Unicode, but in future it might become an issue, especially around text that
		the user inserted, e.g. non-Latin alphabets in the labels and titles.
	We assume fill comes before stroke in the Stata svg.
*/


capture program drop semitrans
program define semitrans
syntax , Infile(string) [Outfile(string) Replace Alpha(real 0.5) Hexalpha(string) ]

if ("`outfile'"=="" & "`replace'"=="" ) {
	display as error "specify outfile or replace, or both if outfile exists"
	error 1
}
if (`alpha'<0 | `alpha'>1) {
	display as error "alpha should be between 0 and 1, or specify hexalpha with an 8-bit hexadecimal value"
	error 1
}
if "`hexalpha'"!="" {
	// convert
}
tempname fin
file open `fin' using "`infile'", read text
if "`replace'"=="replace" {
	tempfile newfile
}
tempname fout
file open `fout' using "`outfile'", write text replace

// find lines containing circles
file read `fin' linein
while r(eof)==0 {
	if substr(`"`macval(linein)'"',2,7)=="<circle" {
		// find fill position in line
		local fillpos = strpos(`"`macval(linein)'"',"fill:")
		local strokepos = strpos(`"`macval(linein)'"',"stroke:")
		local fill = substr(`"`macval(linein)'"',6+`fillpos',6) // not used now but will use to classify on color
		local stroke = substr(`"`macval(linein)'"',8+`strokepos',6)
		local lineout = substr(`"`macval(linein)'"',1,12+`fillpos') + ///
						"fill-opacity:`alpha';" + ///
						substr(`"`macval(linein)'"',`strokepos',15) + ///
						"stroke-opacity:`alpha';" + ///
						substr(`"`macval(linein)'"',15+`strokepos',.)
						
		file write `fout' `"`macval(lineout)'"' _n
	}
	else {
		file write `fout' `"`macval(linein)'"' _n
	}
	file read `fin' linein
}

file close `fin'
file close `fout'

end
