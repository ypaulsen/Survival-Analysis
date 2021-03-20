/* BSTA 665 Presentation #2 code*/


/*Import data from local drive;*/
proc import datafile = 'C:/Users/yalep/Desktop/School/Classes/Bsta 665/Presentations/Presentation 2/valung.csv'
  out = lungs 
  dbms = CSV;
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
	set lungs; 
run; 

/*Look at data*/
proc print data=lung; 
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
	strata prior_int/ group=cell; /* test of fin within race */
	test kps diagtime age prior_int;
run;


