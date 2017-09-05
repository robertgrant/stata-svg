* TPM 25 Aug 2017
* Check that functions defining 4 sloped hex edges are correct
* So much easier than I thought before!
* d is the length of an edge (radius of smallest circle that contains whole hex)


* Input co-ordinates of a hex centred at (0,0) with d=1
input y x
y	x
0	0
.5	-.8660254
1	0
.5	.8660254
-.5	-.8660254
-.5	.8660254
-1	0
end

local d 1 
* Plot functions that define hex
#delimit ;
twoway
	(function (1 - ((1-(.5*`d'))/(0-(0.5*sqrt(3)*`d'))*x)), range(-1 .2) lc(purple))
	(function (1 + ((1-(.5*`d'))/(0-(0.5*sqrt(3)*`d'))*x)), range(-.2 1) lc(purple))
	(function (-1 - ((1-(.5*`d'))/(0-(0.5*sqrt(3)*`d'))*x)), range(-.2 1) lc(purple))
	(function (-1 + ((1-(.5*`d'))/(0-(0.5*sqrt(3)*`d'))*x)), range(-1 .2) lc(purple))
	(scatter y x, msym(O) mc(black))
	, legend(off) aspect(1)
	;
delimit cr

* now remove the sqrt(3) scaling and re-do
clear

input y x
y	x
0 0
.5 -1
1 0
.5 1
-.5 -1
-.5 1
-1 0
end

local d 1
#delimit ;
twoway (scatter y x, msym(O) aspect(1))
	(function 1 - ((1-(.5*`d'))/(0-`d')*x), range(-1 .2) lc(mrcpurple))
	(function 1 + ((1-(.5*`d'))/(0-`d')*x), range(-.2 1) lc(mrcpurple))
	(function -1 - ((1-(.5*`d'))/(0-`d')*x), range(-.2 1) lc(mrcpurple))
	(function -1 + ((1-(.5*`d'))/(0-`d')*x), range(-1 .2) lc(mrcpurple))
	, legend(off)
	;
delimit cr

* These are the functions we need for counting
