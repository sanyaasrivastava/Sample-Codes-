/*******************************
*Author : Sanya Srivastava 
*Contact :
*Date: 
*Description: Conducting an an A/B test to compare the effectiveness of gain vs loss framing
messages in registrations into an agricultural information system uisng administrative data with basic sociodemographic characteristics,
and data collected from the registration survey for the SMS campaign. The registration survey data has
information on the type of invitation SMS, respondents’ reply to the invitation SMS and response to the SMS
about the crops they would grow that season.
Targets of the Code 
1. Input
2. Cleaning
3. Tables
4. Regression
5. Graphs
*******************************/

/******************************

*******************************/

***************************************************************************************************************************************************************************************************************************
***************************************************************************************************************************************************************************************************************************

clear all
set more off
set matsize 800
macro drop _all
graph drop _all
set emptycells drop
*ssc install fre
*ssc install estout
*ssc install catplot

clear


/***************************************************************************************************************************************************************************************************************************
                                                                      
																	  SECTION 1 : PROBLEM 1 
																	  
***************************************************************************************************************************************************************************************************************************/


*1.1) Setting up a working directory
cd "/Users/sanyasrivastava/Desktop/-----/Input/"

*For outputs such as data sets (.dta), Tables, Graphs etc. 
local outpath "/Users/sanyasrivastava/Desktop/-----/Output/"


*Importing SMS Survey Data
insheet using "StataTestRegistrationSurveySMS.csv", clear

*Renaming the variables as STATA was not recognizing the first row as variables 
rename v1 id
rename v2 invdate
rename v3 invsms
rename v4 invresp
rename v5 cropresp

*Saving as temp file to be used later 
sort id, stable
tempfile SurveyData
save `SurveyData', replace

clear 


*Importing Administrative Data
import excel using "StataTestProfilesData.xlsx", firstrow

sort id, stable

*Checking for missing values
mdesc 

*1.2) merging the two data sets using a common identifier 
merge id using `SurveyData'

*checking for the extra observation that did not merge basis the identifier. 
br if _merge==2
*dropping the observation because there were no values for it 
drop if _merge==2
drop _merge

*Identifying string and numerical variables 
desc 

*Looking at summary stats for each of the vars to see whihc vars have value -99
foreach v of varlist age cropresp farmsize gender id invdate invresp invsms language phone_type region {
	sum `v'
}
.

*cross checking/verifying 
count if age==-99
count if farmsize==-99

*1.3) Recode missing values that were flagged as -99 in the administrative data.
foreach v of varlist age farmsize {
	replace `v'=. if `v'==-99
}
.



fre invsms
tab invsms, m

/*
1.4) Create an indicator variable equal to 1 if the loss-framed invitation SMS was sent and 0 if the
gain-framed invitation SMS was sent.
*/
gen iv_loss_gain=1 if invsms=="LOSS"
replace iv_loss_gain=0 if invsms=="GAIN"

*1.5) Generate a dummy variable equal to 1 if the respondent replied yes to the invitation SMS and 0 otherwise
gen dum_reply=1 if invresp=="YES"
replace dum_reply=0 if invresp=="NO"

*1.6) Add a categorical variable with the crop responses reported in CROPRESP to classify the respondents
*into four categories: maize, beans, potatoes, and peas. In CROPRESP, the codes are the following: A =
*maize, B = beans, C = potato, and D = peas.

gen crop="maize" if cropresp=="A"
replace crop="beans" if cropresp=="B"
replace crop="potatoes" if cropresp=="C"
replace crop="peas" if cropresp=="D"



/************************************************
1.7) and 1.8) LABELLING VARIABLES AND VALUES                                                              
*************************************************/																  

label variable age "Age of the Respondent"
note age : "Age of the Respondent"

label variable crop "Name of Crop"
note age : "Name of Crop"

label variable cropresp "Code Name of Crop"
note cropresp : "Code Name of Crop"

label variable dum_reply "Reply to SMS invite by Respondent (numeric)"
note dum_reply : "Reply to SMS invite by Respondent (numeric)"

label define reply 1 "Yes" 0 "No"
label values dum_reply reply

label variable farmsize "Farmsize of the Respondent"
note farmsize : "Farmsize of the Respondent"

label variable gender "Gender of the respondent"
note gender : "Gender of the respondent"

duplicates list id
label variable id "Unique Identifier- Respondent"
note id : "Unique Identifier- Respondent"

label variable invdate "Invitation Date"
note invdate : "Invitation Date"

label variable invresp "Reply to SMS invite by Respondent (string)"
note invresp : "Reply to SMS invite by Respondent (string)"

label variable invsms "Type of invitation sent to Respondent (string)"
note invsms : "Type of invitation sent to Respondent (string)"

label variable iv_loss_gain "Type of invitation sent to Respondent (numeric)"
note iv_loss_gain : "Type of invitation sent to Respondent (numeric)"

label define type_sms 1 "LOSS" 0 "GAIN"
label values iv_loss_gain type_sms


label variable language "Language of the Respondent"
note language : "Language of the Respondent"


label variable phone_type "Type of Phone"
note phone_type: "Type of Phone"

label variable phone_type "Respondent's Region"
note phone_type: "Respondent's Region"



/*
1.9) Generating two new variables, region id, equal to the first two letters of the variable id, and farmer id,
equal to the numeric component of id. Report the number of unique values of region id and farmer id.
Does the variable farmer id uniquely identify observations of the administrative level
*/

gen region_id =substr(id,1,2)
gen farmer_id=substr(id,3,5)
destring farmer_id, replace

tab region_id
*region ID unique values = 5 



duplicates list farmer_id 
sum farmer_id 
*farmer ID unique values = 50,000
*The variable farmer_id uniquely identifies observations at the administrative 
*level since there are no duplicates

/*
1.10 Use a loop or a function (like a foreach command in Stata) and string functions to remove leading and
trailing blanks, and convert all letters to lowercase in the following string variables: region, gender,
language & phone_type.
*/

foreach v of varlist gender language phone_type region {
	replace `v' = trim(lower(`v'))

}
.

/*
1.11) Save a clean dataset ready for analysis in dta format (for Stata and for R, always saving dta format).
*/

save "`outpath'/CleanData.dta", replace

sort id, stable
tempfile CleanData
save `CleanData', replace



/***************************************************************************************************************************************************************************************************************************
                                                                      
																	  SECTION 2 : PROBLEM 2 
																	  
***************************************************************************************************************************************************************************************************************************/
clear 

u `CleanData'

/*
2.1) Create a table that reports the average characteristics (gender, age, farm size) for the respondents
that accepted the invitation to register into the platform and those who did not. Report the average
characteristics table in your response. Try to create the table using a professional format, similar to
tables presented in academic papers. (Hint: you can use esttab or outreg2 (Stata) or stargazer and
kable R.)
*/
*creating dummies for gender (categorical var)
tabulate gender, gen(dum_gender)

*summary stats for varibales in question
summarize age dum_gender1 dum_gender2 farmsize invresp

rename dum_gender1 female
rename dum_gender2 male

label var female "Respondent Gender: Female"
label var male "Respondent Gender: Male"
*
estpost summarize age female male farmsize invresp
eststo accept: estpost summarize age female male farmsize if invresp=="YES"
eststo reject: estpost summarize age female male farmsize if invresp=="NO"
esttab accept reject using table1.rtf, replace main(mean %6.2f) aux(sd) mtitle("Invite reply: YES/Accepted" "Invite reply: No/Rejected") ///
title(Average socio-demographic charecteristics)




/***************************************************************************************************************************************************************************************************************************
                                                                      
																	  SECTION 3 : PROBLEM 3 
																	  
***************************************************************************************************************************************************************************************************************************/

clear 
u `CleanData'

/*
3.1 Add to your do-file/script the regression analysis to estimate the effect of the loss-framed invitation
SMS on registrations into the platform in comparison with the gain-framed invitation SMS. Use
Ordinary Least Squares. Include region fixed-effects and use robust standard errors. Report the results
in a regression table and describe your specification choice. Try and create the regression table using a 
professional format, similar to tables presented in academic papers. (Hint: you can use esttab or
outreg2 (Stata) or stargazer and kable R.)
*/
encode region_id, generate(region_id2)
reg dum_reply iv_loss_gain i.region_id2 , vce(robust) level(95)
eststo: quietly regress dum_reply iv_loss_gain i.region_id2 , vce(robust)


/*
Now use a new specification that includes covariates of sociodemographic characteristics and report
the results. What is the coefficient of determination in this specification? Does the proportion of the
variance in the dependent variable that is predicted by the independent variable increase or decrease
compared to the specification used in 3.1?
*/

encode gender, generate(gender2)
reg dum_reply iv_loss_gain i.region_id2 gender2 age farmsize , vce(robust) level(95)
eststo: quietly regress dum_reply iv_loss_gain i.region_id2 gender2 age farmsize , vce(robust)


*esttab using table2.rtf, replace varwidth(38) label title(Results from Regression - OLS, (1): Without Controls/ (2): With Controls)



/***************************************************************************************************************************************************************************************************************************
                                                                      
																	  SECTION 4 : PROBLEM 4
																	  
***************************************************************************************************************************************************************************************************************************/


/*
4.1) The Agronomic team is developing new content for the users in each region for the upcoming rainy
season. Their plan is to focus on the most common crop in each region based on users’ responses in
the registration survey. In your do-file/script, create a bar chart showing the frequencies of the crop
categories in each region. Include the bar chart in your responses.
*/

clear 

u `CleanData'

catplot crop region_id, ///
percent(crop) ///
ylabel(, nogrid) ///
graphregion(color(white)) ///
xsize(3) ysize(2.2) ///
var1opts(label(labsize(vsmall))) ///
var2opts(label(labsize(vsmall))) ///
ytitle("Percent of Respondents by Crops within a Region", size(vsmall)) ///
title("Crop Frequency by Region" ,span size(medium)) ///
blabel(bar, format(%4.1f) size(vsmall)) ///
intensity(25) ///
asyvars ///
legend(rows(1) stack size(vsmall))
graph export "`outpath'Graph/crop_freq_region.png", as(png) replace




/***************************************************************************************************************************************************************************************************************************
                                                                        
																		END OF .DO FILE 

***************************************************************************************************************************************************************************************************************************/










