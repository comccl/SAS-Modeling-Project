libname IPEDS '~/SASData/IPEDS';
options fmtsearch=(IPEDS);
* main table;

proc sql;
create table gradrate as
select grad.UnitID, gradextend.Total as cohort, grad.Total as comp, grad.Total / gradextend.Total as rate format=percent8.2,

gradextend.GRASIAT as asian, gradextend.GRBKAAT as black, gradextend.GRHISPT as hisp,
gradextend.GRWHITT as white, gradextend.GR2MORT as twomore,
(gradextend.GRAIANT + gradextend.GRNHPIT) as other, gradextend.GRUNKNT as unknown,
grad.Men as men, grad.Women as women, charac.Control as control,

charac.HLOffer as hloffer, tc.Tuition2 / 1000 as instate, tc.Tuition3 / 1000 as outstate
from ipeds.Graduation
(where=(group eq 'Completers within 150% of normal time')) as grad
inner join
ipeds.GraduationExtended
(where=(group contains 'Incoming' and Total ge 200)) as gradextend
on grad.UnitID = gradextend.UnitID
left join ipeds.Characteristics as charac on grad.UnitID = charac.UnitID
left join ipeds.TuitionAndCosts as tc on grad.UnitID = tc.UnitID
;
quit;
* median;

proc means data=gradrate median;
var rate;
run;

data gradrate2;
set gradrate;
if rate >= 0.599 then high = 1;
else if rate < 0.599 then high = 0;
run;
* check distribution;

proc freq data=gradrate2;
tables high control hloffer;
run;
* specs sheet;

ods output Position=specs;
proc contents data=gradrate2 varnum;
run;
ods output close;
proc print data=specs;
run;

* Model A: Forward Selection;

title "Model A: Forward Selection";
proc logistic data=gradrate2;
class control(ref=first) hloffer(ref=last) / param=ref;
model high(event='1') =
control hloffer instate outstate
asian black hisp white twomore other men
 / selection=forward slentry=0.05;

run;

* Model B: Backward Elimination;

title "Model B: Backward Elimination";
proc logistic data=gradrate2;
class control(ref=first) hloffer(ref=last) / param=ref;
model high(event='1') =
control hloffer instate outstate
asian black hisp white twomore other men
/ selection=backward slstay=0.05;

run;

* Model C: Stepwise Selection;

title "Model C: Stepwise Selection";
proc logistic data=gradrate2;
class control(ref=first) hloffer(ref=last) / param=ref;
model high(event='1') =
control hloffer instate outstate
asian black hisp white twomore other men
 / selection=stepwise slentry=0.05 slstay=0.05;
run;

* Model D: Interaction probe;

title "Model D: Interaction Check -- control*instate";
proc logistic data=gradrate2;
class control(ref=first) hloffer(ref=last) / param=ref;
model high(event='1') =
control hloffer instate
control*instate;
run;

title;