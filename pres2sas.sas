/* Proportional hazards regression in SAS              */

/* The following is code I wrote for a presentation in */
/* Survival Analysis. It contains a proportional       */
/* hazards regression analysis carried out in SAS.     */
/*                                                     */
/* The dataset contains information about 137 lung     */
/* cancer patients with four disparate types of cancer */ 
/* cells. Each patient was treated with a standard     */
/* therapy or an experimental one, and several         */
/*  covariates are included.                           */   

/*******************************************************/
/*Import data and preprocessing steps                  */
/*******************************************************/


filename csvFile 
	url "https://github.com/ypaulsen/Survival-Analysis/raw/main/valung.csv";

proc import datafile=csvFile 
	out=valung replace dbms=csv; 
run;

/*Data structure:*/ 
/* 
treatment: therapy 
cancer type: cell = {Squamous, Small, Large, Adeno} 
time: t {time in days}
outcome: dead {dead, censored} 
Coviariates: 
Numeric: 
kps diagtime age 
Other: 
prior {Yes No}
*/

/*Rename*/ 
data lung; 
	set valung; 
run; 

/*Look at data*/
proc print data=valung; 
run; 	

/*Changing variables*/ 
/*Create new variable called 'dead_int' with "dead" recorded as 1 and "censored" as 0.*/
/*Create new variable called 'prior_int' with "Yes" recorded as 1 and "No" as 0.*/
data lung;
	set lung; 
	dead_int  = input(dead_int, 1.);   /*Create new variables*/
	prior_int  = input(prior_int, 1.); 
	if dead = 'dead' then dead_int = 1;      /*Assign values to new variables*/
	else dead_int = 0;
	if prior = 'yes' then prior_int = 1;      
	else prior_int = 0;
run;

/*Look at data*/
proc print data=lung; 
run;

/*******************************************************/
/*******************************************************/




/*******************************************************/
/* PROC Lifetest                                       */ 
/*******************************************************/


/*Proc lifetest*/    
proc lifetest data=lung method=km plots=survival(cl)
	graphics outsurv=a; 
	time t*dead_int(0); /*For lifetest, outcome variable is time*outcome. Here that's t*dead_int(0) where 0 is the condition*/ 
	strata therapy; 
run; 

/*
treatment: therapy 
cancer type: cell 
time: t 
outcome: dead dead_int 
Coviariates: kps diagtime age prior
*/

/*Testing covariates*/
proc lifetest data=lung method=km plots=(hazard(cl), survival(cl), ls, lls)
	graphics; /* ls for cummulative hazard, lls for proportional hazards */
	time t*dead_int(0);
	strata prior_int/ group=cell; /* test of cell within prior_int */
	test kps diagtime age prior_int;
run;

/*                                                     */
/*******************************************************/



/*******************************************************/
/* Graphically checking the distribution of Y.         */
/*                                                     */
/*******************************************************/
/* Below analyses are unnecessary in this case since   */
/* the plots above show that exp works here.           */
/* The code is included here for example puroses.      */

/*Generate data*/  
data a2;
	set a;
	s = survival;
	logH = log(-log(s));
	lnorm = probit(1-s);
	logit = log(s/(1-s));
	ltime = log(t);
run;

*proc print data=a2; 
*run; 

/*logit for log-logistic, logH for weibull and lnorm for log-normal distribution */
proc gplot data=a2;
	symbol1 i=join width=2 value=triangle c=steelblue;
	symbol2 i=join width=2 value=circle c=grey;
	plot logit*ltime=therapy logH*ltime=therapy lnorm*ltime=therapy; 
run;

/*                                                     */
/*******************************************************/



/*******************************************************/
/*PROC PHREG                                           */
/*******************************************************/

/* Full model with 3 estimates for ties      */
/* Breslow is default, but generally inferior*/
proc phreg data=lung;
	class cell;
    model t*dead_int(0) = kps diagtime age prior_int cell/ 	
	ties=breslow;
run;

proc phreg data=lung;
	class cell;
    model t*dead_int(0) = kps diagtime age prior_int cell/ 
	ties=efron;
run;

proc phreg data=lung;
	class cell;
    model t*dead_int(0) = kps diagtime age prior_int cell/ 
	ties=exact;
run;

/* Full model, efron method, with backwards selection.*/
/* Conduct model selction with efron method to save computation time.*/ 

proc phreg data=lung;
	class cell;
    model t*dead_int(0)=kps diagtime age prior_int cell/ 
	ties=efron selection=backward;
run;


/* Fit the *final* model with exact method.*/ 

proc phreg data=lung;
	class cell;
    model t*dead_int(0)=kps cell/ 
	ties=exact;
run;

proc print data=lung; 
run; 
