*! version 1.0.0 , June-13-2022
*! version 1.0.0 , June-24-2022
*! Author: James C.D. Fisher 
*!         Joseph V. Terza 
*!         Abbie Zhang
*! Website: https://github.com/zhangyl334/bivpoisson
*! Support: yz97@iu.edu


*!***********************************************************!
*!     bivariate poisson regression     		        	*!
*!***********************************************************!


/* ESTIMATION */
	
program define bivpoisson, eclass
	version 1.1
	if replay(){
		if ("`e(cmd)'" != "bivpoisson") error 301
		Display `0'
		}
	
		else{	
			*!	bivpoisson estimation
			Estimate `0'
			ereturn local cmdline "bivpoisson `0'"
		}
	}

end

*! (based on biprobit program with revision)
program define Estimate, eclass sortpreserve
	version 1.0, missing
	/* SUR syntax */

	/* gettoken first : 0, match(paren). */
	
	gettoken first 0:0, parse(" ,[") match(paren)
		local left "`0'"
		local junk: subinstr local first ":" ":", count(local number)
		if "`number'" == "1" {
			gettoken dep1n first: first, parse(":")
			gettoken junk first: first, parse(":")
		}
		local first : subinstr local first "=" " "
		gettoken dep1 0: first, parse(" ,[") 
		_fv_check_depvar `dep1'
		tsunab dep1: `dep1'
		rmTS `dep1' 
		confirm variable `r(rmTS)'
		if "`dep1n'" == "" {
			local dep1n "`dep1'"
		}
		
		*! parse variables for equation 1
		
		* syntax is a high-level parsing command
		* gettooken is a low-level parsing command
		
		syntax [varlist(default=none ts fv)] [, /*
			*/	OFFset(varname numeric) noCONstant]

		local fvops = "`s(fvops)'" == "true" | _caller() >= 11

		local ind1 `varlist'
		local offset1 `offset' 
		local nc1 `constant'

					/* get second equation */
		local 0 "`left'"
		gettoken second 0:0, parse(" ,[") match(paren)
		if "`paren'" != "(" {
			dis in red "two equations required"
			exit 110
		}
		local left "`0'"
		local junk : subinstr local second ":" ":", count(local number)
		if "`number'" == "1" {
			gettoken dep2n second: second, parse(":")
			gettoken junk second: second, parse(":")
		}
		local second : subinstr local second "=" " "
		gettoken dep2 0: second, parse(" ,[") 
		_fv_check_depvar `dep2'
		tsunab dep2: `dep2' 
		rmTS `dep2'
		confirm variable `r(rmTS)'
		if "`dep2n'" == "" {
			local dep2n "`dep2'"
		}
		
		*! parse variables for equation 2
		syntax [varlist(default=none ts fv)] [, /*
			*/  OFFset(varname numeric) noCONstant ]

		if !`fvops' {
			local fvops = "`s(fvops)'" == "true"
		}

		local ind2 `varlist'
		local offset2 `offset' 
		local nc2 `constant'

		
	// Step 1: Check Basics //
	
	* mark samples*
	marksample 	touse
	markout		`touse' `dep1' `dep2' `indep1' `indep2'	
	
	*! constant term
	qui gen double `one' = 1 if `touse'

		
	_get_diopts diopts option0, `option0'
	
	if _caller() < 15{
		local parm rho:_cons
	}
	else{
		local parm /:rho
	}

	local diparm "diparm(rho, tanh label(rho))"
		
	if "`log'" == ""{
		local log "noisily"
	}
	else{
		local log "quietly"
	}
	
	if "`level'" != ""{
		local level "level(`level')"
	}
	
	local indep1raw `indep1'
	local indep2raw `indep2'
	
	* _rmcoll remove colinear variables *
	
	_rmcoll i.`dep2' `indep1'  if `touse'
	local indep1 "`r(varlist)'"
	
	_rmcoll `indep2' if `touse'
	local indep2 "`r(varlist)'"
	
	
	*!	Taken from "bicop" and modified a bit
	*! (not sure if I need this part)
	qui{
		tempvar y1 y2
		count	if `touse'
		egen `y1' = group(`dep1')
		egen `y2' = group(`dep2')
		
		count if `touse'
		local N = r(N)
		
		if `N' == 0{
			error 2000	// no obs.
		}
		
		tab `y1' if `touse'
		global Nthr1 = r(r) - 1	
		
		tab `y2' if `touse'
		global Nthr2 = r(r) - 1
		
		if $Nthr1 == 0{
			dis in red "There is no variation in `dep1'"
			exit 2000
		}
		if $Nthr2 == 0{
			dis in red "There is no variation in `dep2'"
			exit 2000
		}
		
		*!	0/1 values for depvar and depvar_en
		if $Nthr1 > 1{
			dis in red "There are more than two groups in `dep1'"
			exit 2000
		}
		if $Nthr2 > 1{
			dis in red "There are more than two groups in `dep2'"
			exit 2000
		}
	}
		
	qui: levelsof `dep1'
	if "`r(levels)'" != "0 1"{
		dis in green "{bf:`dep1'} does not vary; remember:"
        dis in green "0 = negative outcome, 1 = positive outcome"
		exit 2000
	}
	
	
	qui: levelsof `dep2'
	if "`r(levels)'" != "0 1"{
		dis in green "{bf:`dep2'} does not vary; remember:"
        dis in green "0 = negative outcome, 1 = positive outcome"
		exit 2000
	}
	
	
	`log' dis in green ""
	`log' dis in green "Univariate Poisson for starting values"
	
	
	// Step 2: Initialize estimates //
	
	
	** 2-1 Obtain starting values for coefficents
	** by Estimating two univariate poisson models
	** (eq.1: univariate poisson)
	
	qui: poisson `dep1' `indep1' 	if `touse' /*
				iter(`=min(1000,c(maxiter))') */
			
	if _rc == 0{
		tempname cb1
		mat `cb1' 	= e(b)
		local ll_1 = e(ll)
		mat coleq `cb1' = `dep1n'
	}
	

	*!	(eq.2: univariate poisson)
	qui: poisson `dep2' `indep2' if `touse' /*
				iter(`=min(1000,c(maxiter))') */

	local ll_str = e(crittype)
										
	if _rc == 0{
		tempname cb2
		mat `cb2' 	= e(b)
		local ll_2 = e(ll)
		mat coleq `cb2' = `dep2n'
	}
	
	
	*!	stack coefficient estimates
	local ll_p = `ll_1' + `ll_2'
	
	tempname from
	
	if ("`indep1'" != "") & ("`indep2'" != ""){
		mat `from' = `cb1', `cb2'
		
		dis in green "Comparison:	`ll_str' = " in yellow %10.0g `ll_p'
	}
	else if ("`indep1'" != "") & ("`indep2'" == ""){
		mat `from' = `cb1'
	}
	else if ("`indep1'" == "") & ("`indep2'" != ""){
		mat `from' = `cb2'
	}
	else if ("`indep1'" == "") & ("`indep2'" == ""){
		// inplausible case
	}
	
	
	*!	initial value for rho 
	tempname rho0
	mat `rho0' = (0)
	mat colnames `rho0' = `parm'
	mat `from' = `from', `rho0'
	
	local cont wald(2)
	
	*  below lines are ddded by me:
	*!	assign fixed value for bivquadpts (=30),later, allow user supplied value.
	tempname bivquad
	mat `bivquad' = (30)

	*!	assign fixed value for bivaraite normal random variables's diaganol elements
	tempname sigma1
	mat `sigma1' = (1)

	tempname sigma2
	mat `sigma2' = (1)
	

	** 2-2 Send basic information to Mata 

	// send all local variables of parameter initial values, and other 
	// necessary values for numerical integration to Mata

	mata: sigma1 = strtoreal(st_local("sigma1"))  // initial value of sigma1
	mata: sigma2 = strtoreal(st_local("sigma2"))  // initial value of sigma2

	mata: rho0 = strtoreal(st_local("rho0"))  // initial value of rho0 

	mata: beta1_1n = strtoreal(st_local("dep1n"))  // initial value of equation 1 beta from univriate poisson 
	mata: beta2_1n = strtoreal(st_local("dep2n"))  // initial value of equation 2 beta from univriate poisson 

	
	mata: quadpts = strtoreal(st_local("quadpts")) // predefined quadrature points 

	mata: st_view(limits=.,.,st_local("limits"),st_local("touse"))  // vector of limits

	// send data to Mata
	mata: st_view(Y1=.,.,"`depvar1'",st_local("touse"))
	mata: st_view(Y2=.,.,"`depvar2'",st_local("touse"))
	mata: st_view(X1=.,.,"`indepvar1' `one'",st_local("touse"))
	mata: st_view(X2=.,.,"`indepvar2' `one'",st_local("touse"))	
	
	
	// in Mata, all variables should be sent and refered to as Y1, Y2, X1, X2 
	// instead of depvar1, depvar2,...,, or real variable names in the dataset.
	
*!	Main Estimation program in Mata 
	local title "Bivariate Count Seemingly Unrelated Regression Estimation"
	
	#d ;

	
mata 

LIMITS=-5,5
uniquadpts=15
bivquadpts=20
quadpts = bivquadpts

SIGMA=1, 0 \
      0, 1
sigmasqinit=SIGMA[1,1]

obs = rows(y1)
DELTA=1
Jstar = 50
JJstar = 50


/********************************************
*.  *! weights and abcissae calculations 
*  using predefined quadrature points and 
*  Adrian Mandor's GLQwtsandabs() function.
*********************************************/

matrix GLQwtsandabs(real scalar quadpts)
{
  i = (1..quadpts-1)
  b = i:/sqrt(4:*i:^2:-1) 
  z1 = J(1,quadpts,0)
  z2 = J(1,quadpts-1,0)
  CM = ((z2',diag(b))\z1) + (z1\(diag(b),z2'))
  V=.
  ABS=.
  symeigensystem(CM, V, ABS)
  WTS = (2:* V':^2)[,1]
  return(WTS,ABS') 
} 

wtsandabs=GLQwtsandabs(quadpts)	

end

mata: st_view(wtsandabs=.,.,st_local("wtsandabs"),st_local("touse"))  

	

/*********************************************************
MAIN MATA PROGRAM TO EXECUTE THE OPTIMIZATION PROBLEM
FOUR COMPONEMTS:
(1) algorithm to calculate weights and absicaes (done in previous code block)
(2) 2-D GLQ algorithm to calculate integrand values of the likelihood function
(3) Specifying the objective function and its values
(4) Moptimize routine to conduct nonlinear optimization in search for all parameter values


// All external used in the mata program has to be declared as local variables 
// prior to been referred/used in Mata.

**********************************************************/

Mata:

real matrix BivPoissNormIntegrand(xxu1,xxu2){

external Y1
external Y2
external xb1
external xb2
external sigma1
external sigma2
external rho0

lambda1=exp(xb1:+sigma1:*xxu1)
lambda2=exp(xb2:+sigma2:*xxu2)

poisspart=poissonp(lambda1,y1):*poissonp(lambda2,y2)

SIGMA=1,rho12 \
    rho12,1
		   
xxu=colshape(xxu1,1),colshape(xxu2,1)

factor=rowsum((xxu*invsym(SIGMA)):*xxu)

bivnormpart=(1:/(2:*pi():*sqrt(det(SIGMA))))/*
*/:*exp(-.5:*factor)

matbivnormpart=colshape(bivnormpart,cols(xxu1))

integrandvals=poisspart:*matbivnormpart
		 
return(integrandvals)
}


// assign fixed values for Upper and Lower LIMITS of the integral
*  LIMITS should be a global, fixed valued vector. Put here, or in the front.

	LIMITS=-5,5
	limits=LIMITS#J(rows(X),1,1)
	limits1=limits
    limits2=limits

// 2-D numerical integration routine

real matrix bivquadleg(pointer(function) func, /*
*/real matrix limits1, real matrix limits2, /*
*/real matrix wtsabs){


wts=wtsabs[.,1]'
abcissae=wtsabs[.,2]'

quadpts=rows(wtsabs)

constant11=(limits1[.,2]:-limits1[.,1]):/2
constant12=(limits1[.,2]:+limits1[.,1]):/2
constant21=(limits2[.,2]:-limits2[.,1]):/2
constant22=(limits2[.,2]:+limits2[.,1]):/2

abcissaeC=J(1,quadpts,1)#abcissae'
abcissaeR=abcissaeC'
vecabcissaeC=rowshape(abcissaeC,1)
vecabcissaeR=rowshape(abcissaeR,1)
bigargs1=vecabcissaeC#constant11:+constant12
bigargs2=vecabcissaeR#constant21:+constant22
funvals=(*func)(bigargs1,bigargs2)
bigwts=wts'*wts
vecbigwts=rowshape(bigwts,1)
summand=constant11:*constant21:*(vecbigwts:*funvals)
integapprox=colsum(summand')

return(integapprox')
}



// Specifying and calculating the value of the objective function 
// (as a funciton of the unkown parameters)
// by calling the integrand funciton together with the bivquadleg() numerical
//  approximation routine 
	
function BivPoissNormLF(transmorphic BivPoissNorm, /*
*/ real scalar todo, real rowvector b, fv, SS, HH) 
{

external Y1
external Y2
external xb1
external xb2
external sigma1
external sigma2
external rho0
external wtsandabs
external limits

y1 = moptimize_util_depvar(BivPoissNorm, 1)
y2 = moptimize_util_depvar(BivPoissNorm, 2)
xb1 = moptimize_util_xb(BivPoissNorm, b, 1)
xb2 = moptimize_util_xb(BivPoissNorm, b, 2)
sigma1 = moptimize_util_xb(BivPoissNorm, b, 3)
sigma2 = moptimize_util_xb(BivPoissNorm, b, 4)
rho12 = moptimize_util_xb(BivPoissNorm, b, 5)

likeval=bivquadleg(&BivPoissNormIntegrand(),/*
*/limits1,limits2,wtsandabs)

fv=ln(likeval)
}


// Start the Moptimize routine "BivPoissNorm" to conduct nonlinear optimization in search for 
// all beta parameter values (that eners in the form of expotentiated linear index) 
// and other ancilary parameter values.

limits1=limits
limits2=limits



BivPoissNorm=moptimize_init()

moptimize_init_evaluator(BivPoissNorm, &BivPoissNormLF())

moptimize_init_evaluatortype(BivPoissNorm, "lf0")

moptimize_init_depvar(BivPoissNorm, 1, Y1)

moptimize_init_depvar(BivPoissNorm, 2, Y2)

moptimize_init_eq_indepvars(BivPoissNorm, 1, X1)

moptimize_init_eq_indepvars(BivPoissNorm, 2, X2)

moptimize_init_eq_indepvars(BivPoissNorm, 3, "")

moptimize_init_eq_indepvars(BivPoissNorm, 4, "")

moptimize_init_eq_indepvars(BivPoissNorm, 5, "")

moptimize_init_eq_colnames(BivPoissNorm, 1, XXo1names)

moptimize_init_eq_colnames(BivPoissNorm, 2, XXo2names)

moptimize_init_eq_name(BivPoissNorm, 1, "Y1")

moptimize_init_eq_name(BivPoissNorm, 2, "Y2")

moptimize_init_eq_name(BivPoissNorm, 3, "sigmasq1")

moptimize_init_eq_name(BivPoissNorm, 4, "sigmasq2")

moptimize_init_eq_name(BivPoissNorm, 5, "sigma12")

/*
moptimize_init_search(BivPoissNorm,"off")
*/

moptimize_init_eq_coefs(BivPoissNorm, 1, beta1_1n)

moptimize_init_eq_coefs(BivPoissNorm, 2, beta1_1n)

moptimize_init_eq_coefs(BivPoissNorm, 3, 1)

moptimize_init_eq_coefs(BivPoissNorm, 4, 1)

moptimize_init_eq_coefs(BivPoissNorm, 5, rho0)

/*
moptimize_init_technique(BivPoissNorm, "bhhh")
*/

moptimize(BivPoissNorm)

// display full optimization results
moptimize_result_display(BivPoissNorm)


// display coefficient estimates and var-cov-matrix

esttau=moptimize_result_coefs(BivPoissNorm)
tauVhat = moptimize_result_V(BivPoissNorm)

coeffs=coeffs \ esttau


// Compute the log-likelihood 
ll_em = moptimize_result_scores(BivPoissNorm)



end

// Step 4: Report the results

title(`title') `level' `diparm' `diopts'
			;
	
	*! wald test (universal use)
	local r = _b[/rho]
	ereturn scalar rho = (exp(2*`r')-1) / (1+exp(2*`r'))
	
	if "`ll_p'" != "" & "`hascns'" == ""{
		ereturn scalar ll_c 	= `ll_p'
		ereturn scalar chi2_c	= abs(-2*(e(`ll_c') - e(ll)))	//	
		ereturn local chi2_ct "LR"
	}
	else{
		qui test _b[/rho] = 0
		ereturn scalar chi2_c = r(chi2)
		ereturn local chi2_ct "Wald"
	}
	
	
	*!	stored results
	ereturn scalar k_aux = 1
	/* store: the number of auxiliary parameters **/
	
	ereturn scalar N = `N'
	ereturn local depvar1 `depvar1'
	ereturn local depvar2 `depvar2'
	ereturn local indep2raw `indep2raw'
	ereturn local indep1raw `indep1raw'
	ereturn local cmd "bivpoisson"
	ereturn local title "Bivariate Count Seemingly Unrelated Regression Estimation"

	ereturn scalar k_eq_model = 2	
	ereturn local marginsok		"default P11 P10 P01 P00 PMARG1 PMARG2 PCOND1 PCOND2 PCOND10 XB1 XB2 PMARGCOND1"
	ereturn local marginsnotok	"STDP1 STDP2"
	

	*! display results
	Display, `level' `diopts'
	exit `e(rc)'
end



/* DISPLAY RESULTS */

program define Display

	syntax [, Level(cilevel) *]
	_get_diopts diopts, `options'
	
	version 1.1: ml display, level(`level') nofootnote `diopts'
	DispLr
	_prefix_footnote
end

**	Wald test results display 
**  taken from biprobit

program define DispLr

	if "`e(ll_c)'`e(chi2_c)'" == "" {
		exit
	}
	
	local chi : di %8.0g e(chi2_c)
	local chi = trim("`chi'")
	
	if "`e(ll_c)'"=="" {
		di in green "Wald test of rho=0: " ///
			in green "chi2(" in ye "1" in gr ") = " ///
			in ye "`chi'" ///
			in green _col(59) "Prob > chi2 = " in ye %6.4f ///
			chiprob(1,e(chi2_c))
		exit
	}
	
	di in green "LR test of rho=0: " ///
		in green "chi2(" in ye "1" in gr ") = " in ye `chi' ///
		in green _col(59) "Prob > chi2 = " in ye %6.4f ///
	chiprob(1,e(chi2_c))
end



/* AUXILIARY SUB-PROGRAMS */	

*!	taken from biprobit
program define rmTS, rclass

	local tsnm = cond( match("`0'", "*.*"),  		/*
			*/ bsubstr("`0'", 			/*
			*/	  (index("`0'",".")+1),.),     	/*
			*/ "`0'")

	return local rmTS `tsnm'
end



*!	parse endog() option (change from parse endog() option to equation 2)
program define Eq2
	
	args dep2 indep2 option2 colon equation2

	gettoken dep rest: equation2, parse(" =")
	_fv_check_depvar `dep'
	
	tsunab dep: `dep'			
	rmTS `dep'
	confirm variable `r(rmTS)'
	
	c_local `dep2' `dep'
	c_local dep2n `dep'
	
	*!	allow "=" after depvar_en
	gettoken equals 0 : rest, parse(" =")
	if "`equals'" != "=" { 
		local 0 `"`rest'"'
	}	

	
	*!	parse indepvar_en (based on biprobit and heckprobit) 	
	syntax [varlist(numeric default=none ts fv)], [*]
	
	local fvops2 = "`s(fvops)'" == "true" | _caller() >= 11
	local tsops2 = "`s(tsops)'" == "true" | _caller() >= 11
	
	c_local `indep2' `varlist'
	c_local `option2' `options'	
end
