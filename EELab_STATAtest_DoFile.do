/*******************************
*Author : Sanya Srivastava
*Contact :sanyasrivstava@uchicago.edu
*Date: 11th February, 2023
*Description: STATA Test | EE Lab
Targets of the Code 
1. Input
2. Data Cleaning
3. Descriptive Analysis (Tables and Graphs)
4. Regression (log-log Model with fixed effects)
*******************************/

/******************************
Table of contents: 
Section 1: DATA PREPERATION 
Section 2: DATA INTRODUCTION
Section 3: DATA EXPLORATION
Section 4: INTERPRETATION
*******************************/

***************************************************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************************************************

clear all
set more off
set matsize 800
macro drop _all
graph drop _all
set emptycells drop
*set timeout1 90
*set timeout2 180
*ssc install fre
*ssc install estout

*Setting up a working directory
cd "/Users/sanyasrivastava/Desktop/EELab_STATATest/Input/"


*For outputs such as data sets (.dta), Tables, Graphs etc. 
local outpath "/Users/sanyasrivastava/Desktop/EELab_STATATest/Output/"

clear 

/***************************************************************************************************************************************************************************************************************************
                                                                      
																	  SECTION 2 :  DATA INTRODUCTION
																	  
***************************************************************************************************************************************************************************************************************************/

*Importing Barley Production Data (district level)
insheet using "Barley_production.csv", clear
*Only keeping relevant variables for analysis
keep year state stateansi agdistrict agdistrictcode value
sort stateansi
*Removing commas and covertig o long format
destring value, replace force ignore(",")
*Collapsing the data set to the state level
collapse (sum) value, by(year stateansi state)
rename value value_prod
sort stateansi, stable
*Saving as temp file to merge with barley price dataset
tempfile b_prod
save `b_prod', replace

clear 

*Importing Barley Price Data
insheet using "Barley_price.csv", clear
*Merging with production data using state and year combiantion as 
*a unique identifier 
merge 1:1 year stateansi state using `b_prod'
sort state year
*br if _merge==1

/*
*107 observations didn;t merge- missing valus for some states across all years
*or certain number of years. For eg; For Alaska production values are missing 
*across all years. For Delaware production values are missing from 1990-2008 
etc. 
*/ 

*Only keeping relevant variables for analysis
keep year state stateansi commodity value value_prod
rename value value_price
sort stateansi year, stable
*Saving the cleaned and merged dataset as 
*temp file to merge with barley price dataset
tempfile b_prod_price
save `b_prod_price', replace

clear 

/***************************************************************************************************************************************************************************************************************************
                                                                      
																	  SECTION 3 :  DATA EXPLORATION
***************************************************************************************************************************************************************************************************************************/

/*
*3.1) For each year, compute the weighted average of price over all states 
with both price and production data in that year, where each state’s weight 
is its production in bushels in that year. Then, plot this weighted average 
over years 1990-2017.
*/

u `b_prod_price'

*Sum of all production by year
bys year: egen tot=sum(value_prod)
*Calculating the weight for every state and every year
gen wt=value_prod/tot
*Calculating the weighted average basis production 
gen avg_price = value_price*wt
*Collapsing on year to get time series for 1990-2017
collapse (sum) avg_price, by(year)

*declares the data in memory to be a time series
tsset year
      
*Graph 
twoway (tsline avg_price), ytitle(Weighted average of price ($ per BU)) ///
ytitle(, size( small) margin(small)) ylabel(#8, tposition(crossing) nogrid) ///
ttitle(, size(zero) color(white) orientation(horizontal) ///
alignment(baseline)) tlabel(#30, labels labsize(small) ///
angle(forty_five) valuelabel ticks tposition(crossing)) ///
title("Weighted Average of Price of Barley : 1990-2017") note("Time Period", ///
size(vsmall) color(black) position(6) orientation(horizontal) ///
margin(medium) justification(left) alignment(bottom)) legend(off) ///
graphregion(fcolor(white))
*graph export "`outpath'Graph_avgprice.png", as(png) replace
 
clear


/*
3.2) Create a summary table where the rows are specific states 
(Idaho, Minnesota, Montana, North Dakota, and Wyoming) 
and the columns are decades (1990-1999, 2000-2009, and 2010-2017). 
The elements of the table are mean annual state-level production, 
by decade and state. Scale the production variable so that it is in units 
of millions of bushels.  
*/

u `b_prod_price'

drop commodity value_price
reshape wide value_prod, i(state stateansi) j(year)

egen mean1= rowmean(value_prod1990-value_prod1999)
egen mean2= rowmean(value_prod2000-value_prod2009)
egen mean3= rowmean(value_prod2010-value_prod2017)

drop value_prod*

foreach v of varlist mean* {
	replace `v' = `v'/1000000

}
.

rename mean1 meanprod_1991_1990
rename mean2 meanprod_2000_2009
rename mean3 meanprod_2010_2017

label var meanprod_1991_1990 "Mean Annual State-Level Production:1991-1990(in Mil BU)"
label var meanprod_2000_2009 "Mean Annual State-Level Production:2000-2009(in Mil BU)"
label var meanprod_2010_2017 "Mean Annual State-Level Production:2010-2017(in Mil BU)"

keep state meanprod_1991_1990 meanprod_2000_2009 meanprod_2010_2017
keep if state=="IDAHO" | state=="MINNESOTA" | state=="MONTANA" | state=="NORTH DAKOTA" | state=="WYOMING"
cls
list
*export excel using "`outpath'Table1.xls", firstrow(varlabels) replace

/***************************************************************************************************************************************************************************************************************************
                                                                      
																	  SECTION 4 :  INTERPRETATION
Answers also attached in a PDF: 4.Interpretation
***************************************************************************************************************************************************************************************************************************/

clear 

insheet using "Barley_price.csv", clear
rename value value_price
keep year state stateansi value_price
sort stateansi year, stable
tempfile b_price
save `b_price', replace

clear 

insheet using "Barley_production.csv", clear
keep year state stateansi agdistrict agdistrictcode value
sort stateansi
destring value, replace force ignore(",")
rename value value_prod
sort stateansi year
merge stateansi year using `b_price'
drop _merge


/*
4.1) Linear Model
The equation of a linear model of production on price
𝑌 = 𝐵0 + 𝐵1𝑋+ 𝑈
where Y: Production Levels (District/BU) - Dependent/Response Variable
      X: Price Levels (State/$ per BU) - Independent/Control Variable 
𝐵1: Estimated slope
𝐵0: Estimated intercept
*/


/*
4.2 Your friend wants the coefficient of interest on price to have 
the interpretation of an elasticity. Write down a regression equation 
that satisfies your friend’s desire

log(𝑌) = 𝐵0 + 𝐵1log(𝑋)+ 𝑈
where Y: Production Levels (District; BU) - Dependent/Response Variable
      log(𝑌) : Log transformation of the dependent variable
      X: Price Levels (State; $ per BU) - Independent/Control Variable 
	  log(𝑋) : Log transformation of the independent variable
𝐵1: coefficient of interest on price/Estimated Slope/Elasticity
𝐵0: Estimated intercept
*/

gen lprod = log(value_prod)
gen lprice= log(value_price)
*To check if there are any negative values which need to be scaled
sum lprice
sum lprod

/*
4.3) Your friend wants to include time-invariant controls, but does not have 
the data  for these controls. Explain how state fixed effects can act 
as controls. For those unfamiliar with economic terminology, 
fixed effects refer to the set of indicator variables for each 
level of a categorical variable. 

Fixed effects is a technique that helps us to account for all variables, 
including both observable and unobservable, by considering them within a 
particular group that remains constant. Since the varibale "State" is 
time-invariant, basically if we observe the same state multiple times, 
across different years, it will remain the same every single time.
If we use state fixed effects, we’ll be removing any variation 
explained by State. Technically, We can “control for states” the same 
way we’d control for any categorical variable. In regression this means 
adding a set of dummies/binary indicators, one for each state. 
In a fixed effects specification the intercept of the regression model is 
allowed to vary freely across individuals or groups (or states). 
Here it is used to control for  any group (state)-specific attributes that do not 
vary across time. The fixed effects coefficient soaks 
up all the across-group noise.
*/




/*
4.4) Your friend also wants to include annual time fixed effects ​in addition 
to state fixed effects​. Write down an equation for this model. 
Run this regression on the provided data and report the coefficient estimate 
and standard error for the parameter of interest (price). 
Please provide a short interpretation of this result. 
*/

*Making string variables into numeric
encode state, generate(state2)
*OLS regression
reg lprod lprice i.state2 i.year, vce(robust) level(95)

/*
Coefficient of regression:  -.4751066
Standard Error : .193898
Pvalue: 0.014 
Confidence Interval:  -.855279 to -.0949343
*/


/*
The point estimate here corresponds to the coefficient of regression i.e. 
the coefficient of the log of price. This also measure the elasticity-
the term on the right-hand side is the percent change in X (price), and the term 
on the left-hand side is the percent change in Y (production). 
From our regression results we can see that the elasticity is –0.4751066, 
so a 1 percent increase in the price of barley
is associated with a 0.47 percent decrease in production of barley on 
average, ceterius paribus. 
*/

/*
The confidence interval associated with the coeefficient of price does not
cross zero. (if a statistic is significantly different from 0 at the 0.05 level, 
then the 95% confidence interval will not contain 0), so it is statiistically 
significant. Since the standard error is almost twice the coeeficent of 
regression, we reject the null hypothesis and the associated elasticity 
coefficient is significant. 
*/

/*
I have used robust standard errors as Robust standard errors account 
for heteroskedasticity i.e. if the amount of variation in the outcome 
variable is correlated with the explanatory variables, 
robust standard errors can take this correlation into account.
*/

sort stateansi year, stable
tempfile FinalDataSet
save `FinalDataSet', replace

*export excel using "`outpath'FinalDataSet.xls", replace


























