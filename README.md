# bivpoisson
Seemingly unrelated count regression

## Description
bivpoisson implements the count-valued seemingly unrelated regression (count SUR) estimator proposed in Terza and Zhang (2021). This paper shows that bivpoisson affords greater precision and accuracy than Linear Seemingly Unrelated Regression (stata package: sureg) when the underlying data are correlated and count-valued; see Terza and Zhang (2021, https://doi.org/10.7912/C2/2873) for details and illustrations. Post-Estimation command (in development) associated with this package will support predictions and causal effects parameter estimation (i.e., Average Treatment Effects).

## Getting Started

### Installing

The latest version can be obtained via

```
ssc install bivpoisson
```

### Model Estimation
bivpoisson is a user-written command that fits a count valued seemingly unrelated regression using maximum likelihood estimation. It is implemented as an lf0 ml evaluator. The model involves two equations: first equation with the first dependent variable (depvar1) and a second equation with the second dependent variable (depvar2). depvar2 and depvar1 are correlated. Both dependent variables depvar1 and depvar2 have to be count valued variables. Users are free to chose the same or different set of indepedent variabes in the two equations. (indepvars1 and indepvars2 can be the same, or different)


### Syntax

```
bivpoisson (depvar1 = indepvars1) (depvar2 = indepvars2) [if] 
```
where depvar1 is the first count valued outcome variable, indepvars1 are the independent variables of the firs outcome equation, depvar2 is the second count valued outcome variable, and indepvars2 are the independent variables of the second equation. Independent variables may contain a binary policy variable and a set of control variables and may be different or the same. bivpoisson is limited to a count valued seemingly unrelated regression model with two equations and provides a postestimation commands in estimating the average treatment effects (ATEs).

### Example 1

Set up
```
use "https://github.com/zhangyl334/bivpoisson/raw/main/Health_Data.dta", clear

```

Estimation of a seemingly unrelated count regression model
```
bivpoisson (ofp = privins black numchron) (ofnp = privins black numchron age) if fivepct_sample == 1

. bivpoisson (ofp = privins black numchron) (ofnp = privins black numchron age) if fivepct_sample == 1
initial:       f(p) = -898.14156
rescale:       f(p) = -898.14156
rescale eq:    f(p) = -889.97635
Iteration 0:   f(p) = -889.97635  (not concave)
Iteration 1:   f(p) = -878.49262  (not concave)
Iteration 2:   f(p) = -845.96974  (not concave)
Iteration 3:   f(p) = -840.21573  
Iteration 4:   f(p) = -832.94616  
Iteration 5:   f(p) = -832.69668  
Iteration 6:   f(p) = -832.69538  
Iteration 7:   f(p) = -832.69538  

                                                           Number of obs = 207

------------------------------------------------------------------------------
             | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
Y1           |
          x1 |   .3997619   .1830324     2.18   0.029     .0410251    .7584988
          x2 |  -.1335776   .1905022    -0.70   0.483     -.506955    .2397997
          x3 |   .2380122    .053071     4.48   0.000      .133995    .3420294
          x4 |   .6682984   .1939622     3.45   0.001     .2881394    1.048457
-------------+----------------------------------------------------------------
Y2           |
          x1 |   1.305625   .4458126     2.93   0.003     .4318483    2.179402
          x2 |  -2.151162   .9190452    -2.34   0.019    -3.952457   -.3498661
          x3 |   .2358258   .1392374     1.69   0.090    -.0370744     .508726
          x4 |  -.0809187   .3125795    -0.26   0.796    -.6935632    .5317257
          x5 |  -2.271814   2.292566    -0.99   0.322     -6.76516    2.221532
-------------+----------------------------------------------------------------
sigmasq1     |
       _cons |   .8514478    .130599     6.52   0.000     .5954785    1.107417
-------------+----------------------------------------------------------------
sigmasq2     |
       _cons |   3.478548   .6043013     5.76   0.000     2.294139    4.662956
-------------+----------------------------------------------------------------
sigma12      |
       _cons |   .4178385   .2111368     1.98   0.048      .004018     .831659
------------------------------------------------------------------------------

. ereturn list

scalars:
               e(rank) =  12
                  e(N) =  207
                 e(ic) =  7
                  e(k) =  12
               e(k_eq) =  5
               e(k_dv) =  2
          e(converged) =  1
                 e(rc) =  0

macros:
        e(ifstatement) : " if fivepct_sample == 1"
             e(indep2) : "privins black numchron age"
            e(depvar2) : "ofnp"
             e(indep1) : "privins black numchron"
            e(depvar1) : "ofp"
              e(title) : "Bivariate Count Seemingly Unrelated Regression Estimation"
                e(cmd) : "bivpoisson"
                e(opt) : "moptimize"
            e(predict) : "ml_p"
               e(user) : "BivPoissNormLF()"
          e(ml_method) : "lf0"
          e(technique) : "nr"
              e(which) : "max"
             e(depvar) : "Y1 Y2"
         e(properties) : "b V"

matrices:
                  e(b) :  1 x 12
                  e(V) :  12 x 12
               e(ilog) :  1 x 20
           e(gradient) :  1 x 12



### Example 2

Set up
```
use DemandforMedicalCare_NMES.dta, clear

```

Estimation of a bivariate poisson model
```
bivpoisson ofp = privins exclhlth poorhlth numchron adldiff noreast midwest west age black male married school faminc employed medicaid, equation2(ofnp = privins exclhlth poorhlth numchron adldiff noreast midwest west age black male married school faminc employed medicaid)


moptimize(BivPoissNorm)
initial:       f(p) = -18171.892
rescale:       f(p) = -18171.892
rescale eq:    f(p) = -18171.892
Iteration 0:   f(p) = -18171.892  
Iteration 1:   f(p) = -18117.361  (not concave)
Iteration 2:   f(p) = -18100.951  (not concave)
Iteration 3:   f(p) = -18095.334  
Iteration 4:   f(p) = -18076.699  
Iteration 5:   f(p) = -18076.317  
Iteration 6:   f(p) = -18076.313  
Iteration 7:   f(p) = -18076.313  


moptimize_result_display(BivPoissNorm)

                                                Number of obs     =      4,406

--------------------------------------------------------------------------------------
                     |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
---------------------+----------------------------------------------------------------
Y1                   |
       privinsurance |   .3932006   .0466143     8.44   0.000     .3018383    .4845629
            exclhlth |  -.3600516   .0783741    -4.59   0.000     -.513662   -.2064411
            poorhlth |   .3044274   .0447425     6.80   0.000     .2167337     .392121
num chronic diseases |   .2268467   .0116398    19.49   0.000     .2040331    .2496604
      adl difficulty |   .0518241   .0390032     1.33   0.184    -.0246206    .1282689
             noreast |   .0846727   .0449031     1.89   0.059    -.0033358    .1726812
             midwest |   .0186106   .0383204     0.49   0.627     -.056496    .0937172
                west |   .1195768   .0494807     2.42   0.016     .0225965    .2165571
                 age |  -.0192582   .0263179    -0.73   0.464    -.0708404    .0323239
               black |  -.1464985   .0534446    -2.74   0.006     -.251248   -.0417491
                male |   -.114134   .0350359    -3.26   0.001    -.1828031   -.0454649
             married |   .0003811   .0406668     0.01   0.993    -.0793244    .0800865
              school |    .027984   .0043535     6.43   0.000     .0194514    .0365166
       family income |    -.00278    .007234    -0.38   0.701    -.0169584    .0113985
            employed |   .0106799   .0717087     0.15   0.882    -.1298665    .1512263
            medicaid |   .3882471   .0636408     6.10   0.000     .2635134    .5129809
               _cons |   .4737264   .2111269     2.24   0.025     .0599252    .8875276
---------------------+----------------------------------------------------------------
Y2                   |
       privinsurance |   .6669447   .0965316     6.91   0.000     .4777461    .8561432
            exclhlth |  -.0073336    .118156    -0.06   0.951    -.2389151    .2242479
            poorhlth |  -.0554726   .1029883    -0.54   0.590     -.257326    .1463808
num chronic diseases |   .1615432   .0282349     5.72   0.000     .1062038    .2168826
      adl difficulty |   .1694178    .089679     1.89   0.059    -.0063499    .3451854
             noreast |   .4667993   .0943727     4.95   0.000     .2818322    .6517663
             midwest |    .635424   .0873236     7.28   0.000      .464273    .8065751
                west |   .7398896   .1022374     7.24   0.000     .5395079    .9402713
                 age |  -.2768868   .0568505    -4.87   0.000    -.3883117   -.1654619
               black |  -.3821754   .1160962    -3.29   0.001    -.6097197   -.1546311
                male |  -.1723405   .0721889    -2.39   0.017    -.3138281    -.030853
             married |   .0143905   .0762665     0.19   0.850    -.1350891    .1638702
              school |   .0641405   .0091262     7.03   0.000     .0462535    .0820276
       family income |  -.0256119   .0132946    -1.93   0.054    -.0516689     .000445
            employed |  -.1680773   .1151129    -1.46   0.144    -.3936943    .0575398
            medicaid |   .4747206   .1312957     3.62   0.000     .2173857    .7320556
               _cons |  -.8985506   .4519449    -1.99   0.047    -1.784346    -.012755
---------------------+----------------------------------------------------------------
sigmasq1             |
               _cons |   .8215566   .0269765    30.45   0.000     .7686836    .8744296
---------------------+----------------------------------------------------------------
sigmasq2             |
               _cons |   3.354385   .1149635    29.18   0.000     3.129061     3.57971
---------------------+----------------------------------------------------------------
sigma12              |
               _cons |   .5386813   .0414199    13.01   0.000     .4574997    .6198628
--------------------------------------------------------------------------------------



## Authors
James C.D. Fisher
jamescdf@gmail.com 

Joseph V. Terza
jvterza@iupui.edu

Abbie Yilei Zhang 
zhangyl334@gmail.com

## Version History

* 0.1
    * Initial Release

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [awesome-readme](https://github.com/matiassingers/awesome-readme)
* [PurpleBooth](https://gist.github.com/PurpleBooth/109311bb0361f32d87a2)
* [dbader](https://github.com/dbader/readme-template)
* [zenorocha](https://gist.github.com/zenorocha/4526327)
* [fvcproductions](https://gist.github.com/fvcproductions/1bfc2d4aecb01a834b46)
