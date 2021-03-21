/*************************************************************/
/*PROC Lifetest example                                      */
/*************************************************************/
/* The following is code I wrote for a presentation about    */
/* the PROC LIFETEST procedure in SAS.                       */
/* Data are from Klein & Moeschberger: "Survival Analysis:   */ 
/* Techniques for Censored and Truncated Data"               */
/*************************************************************/   


/*************************************************************/
/*Read in the data                                           */
/*************************************************************/
data Lymph;
input Source$ Lymphoma$ Days d;
if Source = '1' then Source = 'Allo';
else Source ='Auto';
if Lymphoma = '1' then Lymphoma = 'Non Hodgkins';
else Lymphoma ='Hodgkins';
datalines;
1 1 28 1 
1 1 32 1
1 1 49 1 
1 1 84 1 
1 1 357 1 
1 1 933 0
1 1 1078 0
1 1 1183 0 
1 1 1560 0 
1 1 2114 0 
1 1 2144 0 
0 1 42 1 
0 1 53 1 
0 1 57 1 
0 1 63 1 
0 1 81 1 
0 1 140 1 
0 1 176 1 
0 1 210 0 
0 1 252 1 
0 1 476 0 
0 1 524 1 
0 1 1037 0 
1 0 2 1
1 0 4 1 
1 0 72 1 
1 0 77 1 
1 0 79 1 
0 0 30 1  
0 0 36 1 
0 0 41 1 
0 0 52 1 
0 0 62 1
0 0 108 1 
0 0 132 1 
0 0 180 0 
0 0 307 0 
0 0 406 0
0 0 446 0 
0 0 484 0
0 0 748 0
0 0 1290 0
0 0 1345 0 
;  


/*************************************************************/
/* Compute the Kaplan-Meier estimate of the survival function*/
/* and the Nelson-Aalen estimate of the cumulative hazard    */  
/* function.                                                 */ 
/* Sketch the Kaplan-Meier estimated survival curves for     */ 
/* different groups in the same plot with labels of groups.  */  
/*************************************************************/   

/* K-M estimation*/    
proc lifetest data=onepointfive method=km nelson plots=survival(cl)
	plots=(s,ls, lls) graphics outsurv=a;
	time Days*d(0);
	strata Source;
run;

proc lifetest data=onepointfive method=nelson plots=survival(cl)
	plots=(s,ls, lls) graphics outsurv=a;
	time Days*d(0);
	strata Source;
run;

data a2;
set a;
s=survival;
logH=log(-log(s));
lnorm=probit(1-s); /* for log normal distribution */
logit=log(s/(1-s)); /* for log-logistic distribution */
lDays=log(Days);
run;

proc print data=a2;
run;

/*
proc gplot data=a2;
symbol i=join;
plot lnorm*lweek=Source;
run;
*/

proc sgplot data=a2;
scatter x=lDays y=lnorm/ group=Source;
run;


proc sgplot data=a2;
scatter x=lDays y=logit/ group=Source;
run;


/* check for proportional hazard assumption
proc gplot data=a2;
symbol i=join;
plot logH*weeks=Source;
run;
*/


proc sgplot data=a2;
scatter x=Days y=logH/ group=Source;
run;

** Life-Table estimation;
proc lifetest data=onepointfive method=life intervals=10,20,30,40
	plots=(s,h) graphics outsurv=b;
	time Days*d(0);
	strata Source;
run;
