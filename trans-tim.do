* Two example plots of achieving translucency in svg graphics with only Stata

* Scatter plot using auto data
sysuse auto, clear
local opac 60
twoway scatter price length [pw=weight], mcol(%`opac') mlcol(%0) scheme(s2color)
	graph export scatter-trans-v15.svg, as(svg) replace
twoway scatter price length [pw=weight], scheme(s2color)
	tempfile a b
	graph export `a' , as(svg) replace
	filefilter `a' `b', from(fill:none;stroke:#1A476F;) to(fill:none;stroke:none;)
	filefilter `b' scatter-trans-tpm.svg, from(fill:#1A476F) to(fill:#1A476F;fill-opacity:0.`opac') replace
shell start scatter-trans-v15.svg
shell start scatter-trans-tpm.svg


* Lines and points using pig data
webuse pig, clear
sort id week
twoway (line weight week, lc(black%10)) (scatter weight week, msym(O) mcol(white)) (scatter weight week, msym(oh) mcol(black%80)), legend(off) scheme(s2color)
	graph export line-trans-v15.svg, replace
twoway (line weight week, lc(black)) (scatter weight week, msym(O) mcol(white)) (scatter weight week, msym(o) mcol(black)), legend(off) scheme(s2color)
	tempfile c d e f g
	graph export `c' , as(svg)
	filefilter `c' `d', from(fill:none;stroke:#000000;) to(fill:none;stroke:#000000;stroke-opacity:0.8)
	filefilter `d' `e', from(stroke:#000000;stroke-width:) to(stroke:#000000;stroke-opacity:0.1;stroke-width:) replace
	filefilter `e' `f', from(stroke:#FFFFFF;stroke-width:) to(stroke:#000000;stroke-opacity:0.1;stroke-width:) replace
	filefilter `f' `g', from(`"r="19.91" style="fill:#000000"/>"') to(`"r="19.91" style="fill:#000000;fill-opacity:0.2"/>"') replace
	filefilter `g' line-trans-tpm.svg, from(stroke:#FFFFFF;stroke-width:) to(stroke:#000000;stroke-opacity:0.1;stroke-width:1) replace
//shell start line-trans-v15.svg
shell start line-trans-tpm.svg
