## Note! I no longer use Github. This repo may be out of date.

All my ex-Github repos are now stored and maintained at [my personal website](http://www.robertgrantstats.co.uk/code.html).

Why did I leave Github? Because I consider the compulsory imposition of 2-factor authentication to be inappropriate for people writing software, including cryptography, which can attract severe punishments in certain jurisdictions. We all know that the organisations that hold the 2nd factors (mobile telephony providers, tech companies) are compromised, willingly or otherwise, in their relationships with security agencies, benign or otherwise.

Why not just close it down? Because you might use it programmatically, via http or API, and I don't want to hurt you (by breaking your code) while trying to help you (by raising issues of privacy and confidentiality).



# Stata commands for manipulating SVG graphics

These require Stata 14 and up.

## Semi-transparency

**semi-trans/trans-tim.do** shows how to add opacity to the SVG styles using **filefilter**. It's easy, though you might have to be clever about what to search for and replace. One problem is where you have overlaid twoway plots of the same type of SVG object (line, circle) and want to add opacity to some and not others.

### To do

* link to **svgtag**

---

## Hexagonal binning

**hexbin.do** is unlike other commands here that take an extant SVG file and make it funky. This one takes data and uses SVG to give you something new. Specifically, given x and y variables, **ncat** number of categories and a colorramp, you get a hexbin .svg file.

### To do
* make an actual functioning command, with options and all that stuff
* We should accept any twoway options and pass them on. A particular thing people will want is to have no axes, for maps and such.
* At present, you have to have vertical straight edges (see the do-file for what this means). We should allow horizontal too.
* Include an option to leave count=0 hexagons out completely (make them totally transparent)

---

## Embedding in HTML with JavaScript to get some interactivity

**svgwithjs.do** takes an SVG file and wraps it up in an .html file, with some D3 JavaScript. At present, it adds a heading (with text specified in the **moheading** option) under the chart when viewed in the web browser, and on rolling the mouse over a circle, the corresponding value of the variable named in the **movar** option is displayed under that.
It assumes that movar in the open dataset is in the same order as the circles in the SVG file. This will be true if you have made the SVG with a single **scatter** command, there's no missing data in the xvar or yvar or movar, and you didn't do daft things like sorting the data in the meantime.
This depends on **svgtag**.

### To do
* We have used D3 here but we could do it without any third-party libraries at all
* We should allow an option to include all JS libraries inside the one .html file, so it is all self-contained
* We should offer a local link rather than an online one to d3js.org
* We should think about ways of linking other variables in superimposed twoway plots

---

## Background utilities: svgtag

**svgtag.do** takes in an SVG file, looks for lines and tags them with a class such as 'plotregion', and markers with an id such as 'circle123'. At present it only finds circles, graphregion and plotregion, and returns various values in r(). Of these, the pixel locations of the plotregion are useful.

### To do
* Write metadata as a comment block containing do-file code that would read the coordinates of the data in: both the pixels and the original variable values, also the pixels for the plotregion
* Add classes: xaxis, yaxis, xtitle, ytitle, xtick, ytick, xlabel, ylabel, gridline, line, area, markers other than circles, markerlabel, rspike, rcapupper, rcaplower
* add option to allocate different classes to markers and lines depending on their color
* add option to allocate different classes to markers and lines, given the number of observations in each superimposed graph
* allow a 'notag' option that returns to r() but writes nothing into the file.

---

## Background utilities: svgbackground

**svgbackground.do** adds a raster image over the graphregion and plotregion but under everything else. It depends on **svgtag**. SVG standards include .jpg, .png and .svg itself (the last of these may be rendered as raster and lose quality). Specific browsers may allow others but there's no guarantee.

### To do
* Check image file type
* allow different preserveAspectRatio values
