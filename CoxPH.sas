/*******************************************************/
/* Proportional hazards regression in SAS              */
/*******************************************************/
/* The following is code I wrote for a presentation in */
/* Survival Analysis. It contains a proportional       */
/* hazards regression analysis carried out in SAS.     */
/*                                                     */
/* The dataset contains information about 137 lung     */
/* cancer patients with four disparate types of cancer */ 
/* cells. Each patient was treated with a standard     */
/* therapy or an experimental one. Several covariates  */
/* are included.                                       */   
/*******************************************************/










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
Covariates: 
  Numeric: 
    kps diagtime age 
  Other: 
    prior {Yes No}
*/

/*Look at data*/
proc print data=valung; 
run; 	

/*Rename*/ 
data lung; 
	set valung; 
run; 

/*Code categorical variables as integers*/ 

data lung;
	set lung; 
	dead_int  = input(dead_int, 1.);         /*Create new variables*/
	if dead = 'dead' then dead_int = 1;      /*Assign values to new variables*/
	else dead_int = 0;
run;

/*Look at data*/
proc print data=lung; 
run;

/*******************************************************/
/*  End of data processing steps                       */  
/*******************************************************/







/*******************************************************/
/* PROC Lifetest                                       */ 
/*******************************************************/
/* Preliminary analyses                                */
/*******************************************************/



/* Data:  
treatment: therapy 
z: time: t 
delta: outcome: dead_int 
cancer type: cell
Coviariates: kps diagtime age prior
*/




/*******************/
/* testing therapy */
/*******************/

/* Kaplan Meier survivor estimates with                */
/* Nelson Aalen cummulative hazard functions           */
proc lifetest data=lung method=km nelson plots=(survival(cl), ls, lls) 
	outsurv=a1; 
/* lls for proportional hazards */
/* ls for cummulative hazard */
	time t*dead_int(0);
	strata therapy; 
run;


/* Testing all numerical covariates with forward       */
/* stepwise elimination.                               */
proc lifetest data=lung method=km plots = (survival(cl), ls, lls); 
	time t*dead_int(0);
	test kps diagtime age; 
run; 

/* Looking at categorical variables individually       */

/* Looking at cell */
proc lifetest data=lung method=km plots = (survival(cl), ls, lls); 
	time t*dead_int(0);
	strata cell; 
run; 

/* Looking at prior */
proc lifetest data=lung method=km plots = (survival(cl), ls, lls); 
	time t*dead_int(0);
	strata prior; 
run; 





/*******************************************************/
/* testing therapy within cell types                   */
/*******************************************************/


/* Kaplan Meier survivor estimates*/   
proc lifetest data=lung method=km nelson plots=(survival(cl), ls, lls)
	outsurv=a2; 
	time t*dead_int(0);
	strata cell/ group = therapy; 
run;


/*******************************************************/
/* End of proc lifetest section.                       */
/*******************************************************/







/*******************************************************/
/* Graphically checking the distribution of Y.         */
/*                                                     */
/*******************************************************/      
/* Most linear plot == best model for distribution     */
/* The code is included here for example puroses.      */
/*******************************************************/

/*Generate data*/  
data a3;
	set a1;
	s = survival;
	logH = log(-log(s));
	lnorm = probit(1-s);
	logit = log(s/(1-s));
	ltime = log(t);
run;


/*logit for log-logistic, logH for weibull and lnorm for log-normal distribution */
proc gplot data=a3;
	symbol1 i=join width=2 value=triangle c=steelblue;
	symbol2 i=join width=2 value=circle c=grey;
	plot logit*ltime=kps logH*ltime=kps lnorm*ltime=kps; 
run;



proc gplot data=a3;
	symbol1 i=join width=2 value=triangle c=steelblue;
	symbol2 i=join width=2 value=circle c=grey;
	plot logit*ltime=therapy logH*ltime=therapy lnorm*ltime=therapy; 
run;


proc gplot data=a3;
	title "Graphically checking the proportional hazards assumption";
	plot logH*t=therapy;
	symbol1 i=join width=2 value=triangle c=steelblue;
	symbol2 i=join width=2 value=circle c=grey;
run;
title; 
/*******************************************************/
/* End of cum hazard plots                             */
/*******************************************************/






/*******************************************************/
/*PROC PHREG                                           */
/*******************************************************/

/* Full model with 2 methods for partial likelihood    */
/* estimation.                                         */
/* ties = Breslow is default, but generally inferior   */
/* for heavily tied data.                              */
/* Fit with all three: if similar, then the data are   */
/* not heavily tied.                                   */ 
/* If it fails to converge (not the case here) then    */
/* look at preliminary analyses to find out which      */
/* features are unimportant -> drop those and it may   */
/* converge.                                           */ 
title;

proc phreg data=lung;
	class cell therapy prior;
    model t*dead_int(0) = therapy kps diagtime age prior cell/ 
	ties=efron;
run;

/* Full model, efron method, with backwards selection. */
/* Conduct model selection with efron method to save   */
/* computation time on large datasets.                 */ 

proc phreg data=lung;
	class cell therapy prior;
    model t*dead_int(0)= therapy kps diagtime age prior cell/ 
	ties=efron selection=backward;
run;





/* Fit the *final* model with exact method.           */

proc phreg data=lung;
	class cell;
    model t*dead_int(0)= kps cell/ 
	ties=exact;
run;

/*******************************************************/
/* Plotting the Baseline Survival function             */
/*******************************************************/


/*Easier to turn cell into an integer*/
data lung2;
	set lung; 
	cell_int  = input(cell_int, 1.);         /*Create new variables*/
	if cell = 'Squamous' then cell_int = 4;  /*Assign values to new variables*/
	else if cell = 'Adeno' then cell_int = 1;
	else if cell = 'Large' then cell_int = 2;
	else cell_int = 3;
run;

proc print data=lung2; 
run; 


proc phreg data=lung2;
	class cell_int; 
	model t*dead_int(0)= kps cell_int 
	/ties=exact;
 run;


/* Baseline survival                 */
/* Cell type 4 = Squoamous = Baseline*/
data null;
	input kps cell_int;
	cards;
0 4
run; 

proc phreg data=lung2;
	class cell_int; 
	model t*dead_int(0)= kps cell_int 
	/ties=exact covb;
   	baseline out=a covariates=null survival=s lower=lcl upper=ucl
	cumhaz=H lowercumhaz=lH uppercumhaz=uH;
run;


/* Baseline survival & cumulative hazard functions */
proc gplot data=a;
	title "Baseline Survival Function";
	symbol1 i=join width=1.5 value=dot H=.55 c=grey;
	plot s*t;
run;


proc gplot data=a; 
	title "Baseline Cumulative Hazard Function";
	plot H*t;
run;

/*******************************************************/






/*******************************************************/
/* checking proportional hazard assumption             */
/* with resampling                                     */
/*******************************************************/


proc phreg data=lung;
	class cell; 
	model t*dead_int(0)= kps cell/ ties=exact;
	assess ph/ resample;
run;









/*******************************************************/
/*******************************************************/
/* Proportional Hazards Assumption Fails on all        */ 
/* significant covariates                              */ 
/*******************************************************/
/*******************************************************/












