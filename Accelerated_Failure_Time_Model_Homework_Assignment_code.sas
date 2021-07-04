*******************************************************************************;
*******************************************************************************;
*******************************************************************************;
*******************************************************************************;


data leuk; 
    input graft$ disease$ time status score wait;
    datalines;
1 1 28 1 90 24
1 1 32 1 30 7
1 1 49 1 40 8
1 1 84 1 60 10
1 1 357 1 70 42
1 1 933 0 90 9
1 1 1078 0 100 16
1 1 1183 0 90 16
1 1 1560 0 80 20
1 1 2114 0 80 27
1 1 2144 0 90 5
1 2 2 1 20 34
1 2 4 1 50 28
1 2 72 1 80 59
1 2 77 1 60 102
1 2 79 1 70 71
2 1 42 1 80 19
2 1 53 1 90 17
2 1 57 1 30 9
2 1 63 1 60 13
2 1 81 1 50 12
2 1 140 1 100 11
2 1 81 1 50 12
2 1 252 1 90 21
2 1 524 1 90 39
2 1 210 0 90 16
2 1 476 0 90 24
2 1 1037 0 90 84
2 2 30 1 90 73
2 2 36 1 80 61
2 2 41 1 70 34
2 2 52 1 60 18
2 2 62 1 90 40
2 2 108 1 70 65
2 2 132 1 60 17
2 2 180 0 100 61
2 2 307 0 100 24
2 2 406 0 100 48
2 2 446 0 100 52
2 2 484 0 90 84
2 2 748 0 90 171
2 2 1290 0 90 20
2 2 1345 0 80 98
run; 

/* 
Create a new variable 'type' which combines the information from the first two 
columns.  
*/
data leuk; 
    set leuk; 
    if graft='1' and disease='1' then type='1';
    else if graft='1' and disease='2' then type='2';
    else if graft='2' and disease='1' then type='3';
    else type='4';
run; 
proc print data=leuk; 
run; 

/*
I think maybe I do graft with type as a covariate. 
*/

/*
Looking at the distribution of Y using proc lifetest
*/

/*
Start by looking at the two diseases seperately: 
*/
proc lifetest data=leuk outsurv=out; 
    time time*status(0); 
    strata disease /group=graft adjust=tukey; 
run;

/*
Using 'type' to look at the distribution while accounting for covariates.
*/
proc lifetest data=leuk outsurv=out; 
    time time*status(0); 
    strata type; 
run;

data dists;
    set out; 
    s=survival; 
    logits=log((1-s)/s);        /* for log-logistic model */
    logneglog=log(-log(s));     /* for weibull model */
    lnorm=probit(1-s);          /* for lognormal model */
    ldays=log(time);
run;

proc gplot data=dists; 
    symbol1 value=circle i=join;
    plot logits*ldays=type logneglog*ldays=type lnorm*ldays=type;
run;

/*
All of these plots look more or less the same.
I will proceed to check the distribution of Y by looking at the fit of some 
well known models.  
*/

/* Benchmark: generalized gamma distribution (AIC=117.392) */
proc lifereg data=leuk; 
    class type;
    model time*status(0)=type score wait   
        /dist=gamma;            
run;

/* log-normal (AIC=129.396) */
proc lifereg data=leuk; 
    class type;
    model time*status(0)=type score wait   
        /dist=lnormal;          
run;  

/* log-logistic (AIC=128.114) */
proc lifereg data=leuk; 
    class type;
    model time*status(0)=type score wait   
        /dist=llogistic; 
run;  

/* Weibull (AIC=126.405) */
proc lifereg data=leuk; 
    class type graft disease;
    model time*status(0)=type score wait   
        /dist=weibull; 
run;  

/*
GG has the smallest AIC (AIC=329.042), but the algorithm fails to converge.
The algorithm does converge using all of the other models and the smallest 
AIC among them is that of the Weibull distribution (AIC=338.055) so I will
proceed to build a model on that distribution. 
*/

proc lifereg data=leuk; 
    class type;
    model time*status(0)=type score wait   
        /dist=weibull; 
run;

/*
Using that model all betas are significant at the alpha=0.05 level. 
The p-values are all highly significant except for that of wait which is 
0.0494 so is borderline, but still significant. 
*/

/* Check prob plot. */
proc lifereg data=leuk; 
    class type;
    model time*status(0)=type score wait   
        /dist=weibull; 
    output out=o_put cdf=f xbeta=xB p=median STD=se;
    probplot;
run;


/* Cox-Snell residuals */
data csnell;
   set o_put;
   e=-log(1-f);
run;

proc lifetest data=csnell plots=(ls) notable graphics;
   time e*status(0);
   symbol1 v=none;
run;







proc lifereg data=leuk; 
    class type;
    model time*status(0)=graft disease type score wait   
        /dist=gamma;            
run;


proc lifereg data=leuk; 
    class type;
    model time*status(0)=type score wait   
        /dist=gamma;            
run;
