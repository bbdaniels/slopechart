// slope-chart program for gap/change illustration

cap prog drop slopechart
prog def slopechart

syntax anything ///
  , Over(string asis) [Reverse] [*]

// Setup
preserve
unab varlist : `anything'


// Set up temporary binary variable for categories regardless of underlying over-var

  // Check type of over-variable; convert to string if coded
  if !(substr("`:type `over''" , 1, 3) == "str") {
    tempvar fakeOverVar
    decode `over' , gen(`fakeOverVar')
    local over = "\`fakeOverVar'"
  }

  // Check only 2 levels in over-variable
  qui levelsof `over' , local(levels)
    local check : word count `levels'
    if (`check' > 2) {
      di as err "Too many levels in over-variable; only two categories allowed"
      error
    }

  // Create temporary variable
  tempvar temptype
    gen `temptype' = (`over' == "`: word 2 of `levels''")
    keep `temptype' `varlist'

  // Switch labels if [reverse] is specified
  if "`reverse'" != "" {
    replace `temptype' = 1-`temptype'
    local levels = "`: word 2 of `levels'' `: word 1 of `levels''"
  }

// Collapse to two observations summary statistics, preserving labels

  // Preserve variable labels
  foreach var of varlist `anything' {
  	local `var'L : var label `var'
  }

  // Collapse
  collapse (mean) `anything' , by(`temptype') fast
    sort `temptype'

  // Restore variable labels
  foreach var of varlist `anything' {
  	label var `var' "``var'L'"
  	cap label val `var' `var'_l
  }

// Set up plots for each variable
foreach var in `varlist' {
  // Red-green-black coloration
  if (`=`var'[2] - `var'[1]' > 0) {
    local lc dkgreen
  }
  else if (`=`var'[2] - `var'[1]' == 0) {
    local lc black
  }
  else {
    local lc maroon
  }

  // Get variable label
  local label : var label `var'
    gen l`var' = "`label'"

  // Plots
  local thePlots = "`thePlots' (line `var' `temptype' , lc(`lc') lw(thick))"
  local thePlots = "`thePlots' (scatter `var' `temptype' if `temptype' == 1, m(none) mlab(l`var') mlabc(black))"
} // End loop over variables

// Draw the graph
tw `thePlots' ///
  , xline(0 1 , lc(black) lw(thick)) ///
    xlab(-.025 " " 0 "`: word 1 of `levels''" 1 "`: word 2 of `levels''" 1.5 " " , notick) xtit(" ") ///
    xscale(noline) yscale(noline) `options' ylab(, notick)

// Cleanup
end
// End of adofile
