/*******************************
*Author : Sanya Srivastava 
*Contact :sanyasrivastava36@gmail.com
*Date: 

*Description: This is an evaluation for an intervantion that intends to increase the uptake of  XYZ services. 
This is not an experimental study and rather an observational one where in a pre and post design is levraged to assess 
the impact based on two rounds of data collection (Baseline and Midline).
Due to the design of this approach, the sample repsondents at basline will be compared to sample repsondents at 
midline (i.e. respondents at basline will act as a counterfactual) along key demographic 9such as age, income, education, marital status etc) 
and contributing variables that are likely to influence the outcome variables.

NOTE: The contents of code are only to demosntrate my coding skills. The variable names and results
have been changed to maintian ambiguity and so as to not allow any sort of identification. 

*Targets of the Code 
1. Input; Cleaning; Labelling
2. Weighting 
3. Tabulations
4. Analysis
*******************************/

/******************************
Table of contents: 
Section 1: Data Cleaning and Labelling
Section 2: Tabulations
Section 3: Cross Tabulations
Section 4: Outcome Vars(From Midline data collection)
Section 5: Regression (Baseline and Midline Append)
Section 6: Probit Regression (w and w/o controls)
Section 7: Subgroup Analysis
Section 8: Sample Balance Test (to understand if the two samples are similar in characteristics. This will be important to prove to 
establish that two samples are similar and hence comparable) 
*******************************/

***************************************************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************************************************

clear all
set more off
set matsize 800
macro drop _all
graph drop _all
set emptycells drop
*Install user written package for tabs
ssc install fre
//set trace on 

local inpath "C:\Users\sanya\OneDrive\Desktop\XYZ\Inpath\"
local outpath "C:\Users\sanya\OneDrive\Desktop\XYZ\Outpath\"

**********************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************

* SECTION 1: Data Cleaning and Labelling
*Import midline data 
import delimited "`inpath'XYZ.csv" , clear

*vars- 245 obs - 1693

* Midline Time Period Dummy 
gen timePrd = 1

*Weighting
bys block: gen Households = _N
hist Households, percent kden
tab Households, m
gen weightBlock = (34/Households)
gen weightBlockRound = round((weightBlock*100),1)

*Splitting block for block numbers (needed for clustering SE's) 
split block, p("-")
drop block block1
rename block2 block
destring block, replace 

 
*Labelling A: Variables of interest to the study  

label define xyz 1	"A" 2	"B" 3	"C" 4	"D"  5	"E"   88	"Others" 99	"Don't know/ Can't say" 
label value V1 xyz

label define yesnoother 1 "A"  2	"B" 88	"Others (specify)"
label value V2 yesnoother

label define highestlevel 1	"A" 2	"B" 3	"C" 4	"D" 5	"E" 88	"Others (Specify)" 99	"Don't know/ Can't say" 
label value V3 highestlevel

label define currentlyemployed 1	"A" 2	"B"  3	"C" 4	"D" 88	"Others (Specify)"
label value V4 currentlyemployed


**Labelling B: Variables of interest to the study  

label define noyes 0 "no" 1 "yes" 
label value q201_1 q201_2 q201_3 q201_4 q201_5 q201_6 q201_7 q201_8 q201_9 q201_0 q201_11 q201_12 q201_13 q201_88 q201_77 noyes 

label variable q201_1 "A"
label variable q201_2 "B"
label variable q201_3 "C"
label variable q201_4 "D"
label variable q201_5 "E"
label variable q201_6 "F"
label variable q201_7 "G"
label variable q201_8 "H"
label variable q201_9 "I"
label variable q201_10 "J"
label variable q201_11 "K"
label variable q201_12 "L"
label variable q201_13 "M"
label variable q201_77 "Refused"
label variable q201_88 "Others"
label variable q201_99 "Don't Know"


*q202_*

label value q202_1 q202_2 q202_3 q202_4 q202_5 q202_6 q202_7 q202_8 q202_9 q202_10 q202_11 q202_88 noyes 

label variable q202_1 "A"
label variable q202_2 "B"
label variable q202_3 "C"
label variable q202_4 "D"
label variable q202_5 "E"
label variable q202_6 "F"
label variable q202_7 "G"
label variable q202_8 "H"
label variable q202_9 "I"
label variable q202_10 "J"
label variable q202_11 "K"
label variable q202_88 "Others (Specify)"


**Labelling C: Variables of interest to the study  

*Similarly for other vars 

**Labelling D: Variables of interest to the study 
*Similarly for other vars 

********************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************

*** SECTION 2 : Tabulations 
fre age [aw=weightBlock]
fre internet [aw=weightBlock]
fre phone [aw=weightBlock]
fre edu [aw=weightBlock]

*Binary var (0/1) for access to phone 
gen access_phone = 1 if resp_phone == "Yes"
replace access_phone = 0 if access_phone ==.
fre access_phone [aw=weightBlock]

*Household Income
fre income1 [aw=weightBlock]

*Household Income in categories
gen hhs_income = 1 if income1 < 10000
replace hhs_income = 2 if income1 >= 10000 & income1 < 30000
replace hhs_income = 3 if income1 >= 30000
label define income 1 "<1000" 2 "10000-less than 30000" 3 "Greater than 30000"
label value hhs_income income1
tab hhs_income [aw=weightBlock], m

*q101 : list down the question here 
foreach v of varlist q101 q101a ///
q102 q102a q102a_other  {
	tab `v'[aw=weightBlock],m
}
*q102/103 : list down the question here 
foreach v of varlist q102b ///
q102b_other q103 q103_other  {
	tab `v'[aw=weightBlock], m
}
**Knowledge of 3 types of X

*Heard about X1 - Spont (==1) and Pompt(==2) (Composite Indicator)
gen heard_X1 = 1 if q305a == 1 | q305a == 2
replace heard_X1 = 0 if q305a == 3
fre heard_X1 [aw=weightBlock]

*Heard about X2 - Spont (==1) and Pompt(==2) (Composite Indicator)
gen heard_X2 = 1 if q306a == 1 | q306a == 2
replace heard_X2 = 0 if q306a == 3
fre heard_X2 [aw=weightBlock]

*Heard about X3 - Spont (==1) and Pompt(==2) (Composite Indicator)
gen heard_X3 = 1 if q307a== 1 | q307a == 2
replace heard_X3 = 0 if q307a == 3
fre heard_X3 [aw=weightBlock]

*Heard of all 3 X's (Composite Indicator)
gen X = 0
replace X = 1 if heard_X1== 1 & heard_X2 == 1 &  heard_X3 == 1
fre X [aw=weightBlock]


*** SECTION 3 : Cross tabs
tab q421 age [aw=weightBlock] ,m
tab q405 age [aw=weightBlock] ,m


*Composite Indicator for var q416 which is a dummy and has alot of categories 
gen iden = 0 if q416_1 == 1 
replace iden = 1 if q416_2 ==1| q416_3==1| q416_4==1| q416_5==1| q416_6==1| q416_7==1| q416_8==1| q416_9==1| q416_10==1| q416_11==1| q416_12==1| q416_13==1| q416_14==1| q416_15==1|q416_88==1
fre iden [aw=weightBlock]


* Cross tab for composite indicator var q416 (i.e. iden) and var Y
tab iden Y [aw=weightBlock]
drop iden

*save as tempfile (midline data)
tempfile Data_m
save `Data_m', replace

********************************************************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************************************************

*****SECTION 4: Regression

clear 

* import baseline data 
import delimited "`inpath'Baseline.csv" , clear

* vars- 442 obs- 1868

*weighting 
bys block_code: gen Households = _N
tab Households, m
gen weightBlock = (34/Households)
gen weightBlockRound = round((weightBlock*100),1)

*Tempfile baseline Data
tempfile Data_b
save `Data_b', replace

*Reanaming vars relevant to the analysis as per midline for appending the data 
rename block_code block
rename q508 q416 
rename q508_1 q416_1
rename q508_2 q416_2 
rename q508_3 q416_3

*Baseline Time Period Dummy 
gen timePrd = 0

****** Appending Baseline and Midline data
append using `Data_m',force

tempfile Data
save `Data', replace


**SECTION 5 : Outcome vars computation
**Outcome Vars (Present in both Midline and Baseline) : Converting all the outcome vars into Binary Vars (0/1) by replacing Don't know (99), Others (88) and Refused (77) to missing values 
**for probit regression 

* 1. Outcome var 1 
replace q421 = . if q421 ==3|q421 ==77|q421 ==99
replace q421 = 0 if q421 ==2

*2. Outcome var 2  
replace q302 = . if q302 ==77|q302 ==99
replace q302 = 0 if q302 ==2

*3. Outcome var 3
replace q307 = . if q307 == 77| q307 == 99
replace q307 = 0 if q307 == 2

**********************************************************************************************************************************************************************************************************************************
**********************************************************************************************************************************************************************************************************************************

******SECTION 6: Probit Regression***********
*6.1. Without controls 

  //1. q421 - Outcome var 1 
probit q421 timePrd [pw=weightBlock], cluster(block)
margins, dydx(*)
marginsplot, plotr(margin(bargraph)) ytick(#5) recast(bar) ///
	ytitle("{it: Average marginal effects of baseline-midline variable}", height(5)) ///
	xtitle("") ///
	title("{bf:Marginal effects imputed from Probit Regression}" , position (12) span) ///
	subtitle("{bf:Dependent variable: XYZ}" ///
	" " ///
	"{it: Specification does not include controls; bars reflect 95% CI}",  position (12) span) ///
	ciopts(recast(cap) msize(small)) ///
	plotopts(barwidth(0.5) color(navy*.6)) ///
	b1title("{it:Time Period Dummy: Baseline/Midline}", height(5) size(mediumsmall))

// Save
*graph export "`outpath'Graph/ABC_WC.png", as(png) replace
	
	//2. q302- Outcome var 2  
probit q302 timePrd [pw=weightBlock], cluster(block)
margins, dydx(*)
marginsplot, plotr(margin(bargraph)) ytick(#5) recast(bar) ///
	ytitle("{it: Average marginal effects of baseline-midline variable}", height(5)) ///
	xtitle("") ///
	title("{bf:Marginal effects from Probit Regression}" ,  position (12) span) ///
	subtitle("{bf:Dependent variable: GHI }" ///
	" " ///
	"{it: Does not include controls; bars reflect 95% CI}",  position (12) span) ///
	ciopts(recast(cap) msize(small)) ///
	plotopts(barwidth(0.5) color(navy*.6)) ///
	b1title("{it:Time Period Dummy: Baseline/Midline}", height(5) size(mediumsmall))

// Save
*graph export "`outpath'Graph/GHI_WC.png", as(png) replace

    //3. q307b - Outcome var 3 
probit q307b timePrd [pw=weightBlock], cluster(block)
margins, dydx(*)
marginsplot, plotr(margin(bargraph)) ytick(#5) recast(bar) ///
	ytitle("{it: Average marginal effects of baseline-midline variable}", height(5)) ///
	xtitle("") ///
	title("{bf:Marginal effects from Probit Regression}" ,  position (12) span) ///
	subtitle("{bf:Dependent variable: DEF }" ///
	" " ///
	"{it: Does not include controls; bars reflect 95% CI}",  position (12) span) ///
	ciopts(recast(cap) msize(small)) ///
	plotopts(barwidth(0.5) color(navy*.6)) ///
	b1title("{it:Time Period Dummy: Baseline/Midline}", height(5) size(mediumsmall))
	
// Save
*graph export "`outpath'Graph/DEF_WC.png", as(png) replace

* 6.2. With controls
/*	
**Controls 
**Demographic
•	Age - age
•	Household income -income
•	Marital Status -marriage
•	Education Status - studying
•	Access to a mobile phone and/or internet - access_phone
•	B/M - Baseline/midline Dummy 
•	timePrd - Time Period Dummy
*/
   //1.  q421 - Outcome var 1
probit q421 timePrd age income marriage studying  access_phone  [pw=weightBlock], cluster(block)
margins, dydx(*)
marginsplot, plotr(margin(bargraph)) ytick(#5) xlabel(1 "B/M" 2 "Age" 3 "Household Expense" 4 "Marital Status" 5"Education" ///
6 "Access to Phone" , labels angle(30)labsize(*0.8) tstyle(show_ticks(yes))) recast(bar) ///
	ytitle("{it: Average marginal effects of baseline-midline variable}", height(4) margin(tiny)) ///
	xtitle("") ///
	title("{bf: Marginal effects from Probit Regression}" , position (12) span) ///
	subtitle("{bf:Dependent variable: ABC}" ///
	" " ///
	"{it: Includes controls; bars reflect 95% CI}" , position (12) span) ///
	ciopts(recast(cap) msize(small)) ///
	plotopts(barwidth(0.5) color(navy*.6)) ///
	b1title("{it:Time Period Dummy: Baseline/Midline}", height(5) size(mediumsmall))

// Save
*graph export "`outpath'Graph/ABC_C.png", as(png) replace

*cross -checking results in OLS regresssion 
reg q421 timePrd age income marriage studying access_phone [aw=weightBlock], cluster(block)

    //2. q302- Outcome var 2 	
probit q302 timePrd age income marriage studying  access_phone [pw=weightBlock], cluster(block)
margins, dydx(*)
marginsplot, plotr(margin(bargraph)) ytick(#5) xlabel(1 "B/M" 2 "Age" 3 "Household Expense" 4 "Marital Status" 5"Education" ///
6 "Access to Phone" , labels angle(30)labsize(*0.8) tstyle(show_ticks(yes))) recast(bar) ///
	ytitle("{it: Average marginal effects of baseline-midline variable}", height(4) margin(tiny)) ///
	xtitle("") ///
	title("{bf: Marginal effects from Probit Regression}" , position (12) span) ///
	subtitle("{bf:Dependent variable: GHI}" ///
	" " ///
	"{it: Includes controls; bars reflect 95% CI}" , position (12) span) ///
	ciopts(recast(cap) msize(small)) ///
	plotopts(barwidth(0.5) color(navy*.6)) ///
	b1title("{it:Time Period Dummy: Baseline/Midline}", height(5) size(mediumsmall))

// Save
*graph export "`outpath'Graph/GHI_C.png", as(png) replace


*cross -checking results in OLS regresssion 
reg q302 timePrd age income marriage studying access_phone [aw=weightBlock], cluster(block)

   
   //3. q307b - Outcome var 3
probit q307b timePrd age income marriage studying access_phone [pw=weightBlock], cluster(block)
margins, dydx(*)
marginsplot, plotr(margin(bargraph)) ytick(#5) xlabel(1 "B/M" 2 "Age" 3 "Household Expense" 4 "Marital Status" 5"Education" ///
6 "Access to Phone" , labels angle(30)labsize(*0.8) tstyle(show_ticks(yes))) recast(bar) ///
	ytitle("{it: Average marginal effects of baseline-midline variable}", height(4) margin(tiny)) ///
	xtitle("") ///
	title("{bf: Marginal effects from Probit Regression}" , position (12) span) ///
	subtitle("{bf:Dependent variable:DEF }" ///
	" " ///
	"{it: Includes controls; bars reflect 95% CI}" , position (12) span) ///
	ciopts(recast(cap) msize(small)) ///
	plotopts(barwidth(0.5) color(navy*.6)) ///
	b1title("{it:Time Period Dummy: Baseline/Midline}", height(5) size(mediumsmall))

// Save
*graph export "`outpath'Graph/DEF_C.png", as(png) replace

*cross -checking results in OLS regresssion 
reg q307b timePrd  age income marriage studying access_phone [aw=weightBlock], cluster(block)

clear

*************************************************************************************************************************************************************************************
*************************************************************************************************************************************************************************************

**********SECTION 8: SUBGROUP ANALYSIS***************

u `Data_e', clear 

keep if q501  == 1
* 501==1 is a subgroup
*(1,531 observations deleted)

***Tabulations 
fre resp_age [aw=weightBlock]
fre resp_internet [aw=weightBlock]
fre resp_phone [aw=weightBlock]
fre resp_edu [aw=weightBlock]

fre access_phone [aw=weightBlock]

fre hhs_income [aw=weightBlock]

foreach v of varlist q101 q101a ///
q102 q102a  {
	fre `v'[aw=weightBlock]
}
**********************************************************************************************************************************************************************************************
*********************************************************************************************************************************************************************************************

****** Section 9: SAMPLE BALANCE TESTS************
u `Data', clear

**Chi-square test for Categorical Vars
* Demographic vars like age, HHS income, relationship status, marital status, education status, employment status etc. 
tab age  timePrd , m  chi2
tab q101 timePrd , m chi2
tab q102 timePrd ,m chi2
tab q102a timePrd , m chi2
tab q102b timePrd , m chi2
tab q103 timePrd , m chi2
tab hhs_income timePrd , m  chi2

** T -Test for Binary Vars
replace q101= 2 if q101== 99 
*(replace 99 with 2 to make it uniform)
ttest q101, by(timePrd)
ttest access_phone , by(timePrd)

clear
**********************************************************************************************************************************************************************************************
*********************************************************************************************************************************************************************************************













