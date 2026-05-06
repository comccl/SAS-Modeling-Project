/** Modeling Project **/

/** Problem 1 **/

libname IPEDS '~/SASData/IPEDS';
options fmtsearch=(IPEDS);

/** Data Preporocessing **/
proc sql;
	create table GradRates as
		select Grads.UnitId, Grads.Total/Cohort.Total as GradRate, Cohort.Total as Cohort_Size
		from ipeds.Graduation(where=(group contains 'Completers')) as Grads
			inner join 
			ipeds.Graduation(where=(group contains 'Incoming')) as Cohort
		on Grads.UnitId eq Cohort.UnitId
       where Cohort_Size >= 200
       ;
quit;

proc sql;
    create table master as
    select *
    from GradRates, ipeds.characteristics(where=(cbsatype gt 0)), ipeds.tuitionandcosts
    where GradRates.UnitID eq Characteristics.UnitID eq tuitionandcosts.UnitID
    ;
run;

proc sql;
   alter table master
   drop column instnm, fips, instcat, board, cbsatype;
quit;

/** Finding Best Model **/

/** Basic Run **/
proc glmselect data=master seed=14;
    class iclevel control hloffer locale c21enprf room;
    model GradRate = Cohort_Size--boardamt;
run;

/** Stepwise **/
proc glmselect data=master seed=14;
    class iclevel control hloffer locale c21enprf room;
    model GradRate = Cohort_Size--boardamt / selection=stepwise(select=sl choose=cv);
run;

/** Backward **/
proc glmselect data=master seed=14;
    class iclevel control hloffer locale c21enprf room;
    model GradRate = Cohort_Size--boardamt / selection=backward(select=sl choose=cv);
run;

/** Forward **/
proc glmselect data=master seed=14;
    class iclevel control hloffer locale c21enprf room;
    model GradRate = Cohort_Size--boardamt / selection=forward(select=sl choose=cv);
run;

/** Lasso **/
proc glmselect data=master seed=14;
    class iclevel control hloffer locale c21enprf room;
    model GradRate = Cohort_Size--boardamt / selection=lasso;
run;

/** Elasticnet **/
proc glmselect data=master seed=14;
    class iclevel control hloffer locale c21enprf room;
    model GradRate = Cohort_Size--boardamt / selection=elasticnet;
run;