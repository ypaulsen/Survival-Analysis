/* BSTA 665 Presentation #2 code*/


/*Import data from local drive;*/
proc import datafile = 'C:/Users/yalep/Desktop/School/Classes/Bsta 665/Presentations/Presentation 2/valung.csv'
  out = lungs 
  dbms = CSV;
run;

/*Data structure:*/ 
/* 
treatment: therapy 
cancer type: cell = {Squamous, Small, Large, Adeno 
time: t 
outcome: dead
Coviariates: kps diagtime age prior
*/

/*Rename*/ 
data lung; 
	set lungs; 
run; 

/*Look at data*/
proc print data=lung; 
run; 	

/*Changing variables*/ 
/*Create new variable called 'deadnum' with deaths recorded as 1s and 0s*/
data lung;
	set lung; 
	dead_int  = input(dead_int, 1.);             /*Create new variable*/
	if dead = 'dead' then dead_int = 1;      /*Assign values to new variable*/
	else dead_int = 0;
run;

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
	*strata spk/ trend; /* test for trend on educ */
	*strata race/ group=fin; /* test of fin within race */
	test fin age race wexp mar paro prio educ;
run;


