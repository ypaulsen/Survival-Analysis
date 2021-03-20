*\ BSTA 665 Presentation #2 code;


*\Import data from local drive;
proc import datafile = 'C:/Users/yalep/Desktop/School/Classes/Bsta 665/Presentations/Presentation 2/valung.csv'
  out = lungs 
  dbms = CSV;
run;

*\Rename; 
data lung; 
	set lungs; 
run; 

*\Look at data;
proc print data=lung; 
run; 	

*\Changing variables; 
*\Create new variable called 'deadnum' with deaths recorded as 1s and 0s;
data lung;
	set lung; 
	deadnum  = input(dead, 1.);             *\Create new variable;
	if dead = 'dead' then deadnum = 1;      *\Assign values to new variable;
	else deadnum = 0;
run;

*\Proc lifetest; 
proc lifetest data=lung method=km plots=survival(cl)
	graphics outsurv=a; 
	time t*deadnum(0); 
	strata therapy; 
	symbol1 color=black line=1;
	symbol2 color=black line=2;
run; 

