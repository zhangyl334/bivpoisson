# bivpoisson
Count Valued Seemingly Unrelated Regression 
# Project Title

bivpoisson

## Description

Stata module to estimate bivariate poisson regressions

## Getting Started

### Dependencies

* Describe any prerequisites, libraries, OS version, etc., needed before installing program.
* ex. Windows 10

### Installing

The latest version can be obtained via

ssc install bivpoisson

### Model Estimation
bivpoisson is a user-written command that fits a count valued seemingly unrelated regression using maximum likelihood estimation. It is implemented as an lf0 ml evaluator. The model involves two equations: first equation with the first dependent variable (depvar1) and a second equation with the second (correleated) dependent variable (depvar2). Both dependent variables depvar1 and depvar2 have to be count valued variables. Users are free to chose the same or different set of indepedent variabes in the two equations.


### Executing program

* How to run the program
* Step-by-step bullets
```
code blocks for commands
```

## Help

Any advise for common problems or issues.
```
command to run if program contains helper info
```

## Authors

ex. Abbie Zhang 
ex. yz97@iu.edu

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
