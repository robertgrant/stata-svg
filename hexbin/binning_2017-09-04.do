* My attempt to get the binning algorithm going for circles
* I will regret not commenting it better later (24Aug2017)
* Obvs it can all be made more efficient but need to get it working first

drawnorm y x, n(500) clear
replace y = y+5 if runiform() > .7
* Scatterplot
//twoway scatter y x, aspect(1) ms(o) mc(%50) name(scatter, replace)

tempvar xsc ysc

* Inputs from user
local rows 13
local cols 17
local d 1 // d may be set to 1 in general so probably remove (unless useful later for y,x scaling)
local gridmax = max(`rows',`cols')
local aspect = (.5*sqrt(3)*(`rows'+1))/(`cols'+1) // Stata does something funny with aspect that is easy to see with hexes
di `aspect'

* Generate square grid.
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


* Next section starts counting (our first reference to y and x)
* Have to scale x and y data first
summ y //, meanonly
	local ymin = r(min) // needed for later when we will rescale the grid
	local ymax = r(max)
	gen float `ysc' = ((y-`r(min)')/(`r(max)'-`r(min)'))*(`rows')
summ x //, meanonly
	local xmin = r(min) // needed for later when we will rescale the grid
	local xmax = r(max)
	gen float `xsc' = ((x-`r(min)')/(`r(max)'-`r(min)'))*(`cols')


* Check scaling has worked as required
//twoway (scatter ysc `xsc', ms(o) msize(vsmall))	(scatter ygrid xgrid, ms(+) mc(black) msize(large)) , aspect(.92) legend(off) name(offsetdata, replace) ylab(0(1)`rows') xlab(0(1)`cols')


* Start counting
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


* demo with a circle bin
* The aspect only works if the bins fill the plotregion. It's hard to make this happen.
tw (scatter ygrid xgrid /*[fw=count]*/ , msym(o)),	///
	ylab(minmax, format(%9.2fc))	///
	xlab(minmax, format(%9.2fc))	///
	aspect(`aspect') name(circ_result, replace)

