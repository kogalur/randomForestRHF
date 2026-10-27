# randomForestRHF 2.1.2

* Added `coe.aggregate = "max.robust"` as the default COE ensemble aggregation for new fits, with additional protection against repeated maximum tree contributions. The correction can also apply at `coe.trim = 0`; `trimmed.mean`, `median`, and `mean` remain available.
* Extended OOB trim selection and fitted hazard configuration to `max.robust`. Prediction reuses the fitted aggregation policy and selected trim, while restore recomputes the trim selection from OOB risk.
* Standardized `coe.trim = 0.5` as an explicit exact-median endpoint for both `max.robust` and `trimmed.mean`, including fixed, adaptively selected, and inherited prediction settings, with consistent risk evaluation and selected-aggregation metadata.
* Updated `auct.rhf()` to use the fitted `max.robust` rule when reconstructing cumulative/dynamic markers and recovering incident markers from retained tree-level arrays, including repeated-maximum correction and the exact-median endpoint.
* Reworked `plot.rhf()`. The default display is now each case's probability of an event in each interval of the time grid given it is at risk, `1 - exp(-dH)` from the case's OOB (or test) cumulative hazard (`type = "prob"`; `window` gives the probability over a window of fixed width), with the cumulative hazard (`type = "chf"`), the survival probability (`type = "surv"`) and the previous smoothed-hazard display (`type = "hazard"`, still the default for `smoothed.hazard.rhf` objects) also available. Curves are drawn only over each case's observed follow-up instead of setting missing values to zero, as steps, lines or lowess smooths (`curve`, `f`, `curve.lwd`), with legend labels by case id and an automatic time range that stops a little beyond the cases' follow-up and leaves out the very wide tail intervals of the grid. A `truth` argument overlays the true curves of a `hazard.simulation()` model on every display. The drawn values are returned invisibly. In the hazard display, `scale.hazard = TRUE` now multiplies each grid interval's hazard by that interval's width (the widths were previously recycled down the matrix of cases), `lty` applies to the curves, and cases with few observed grid points no longer fail.
* Documented when to use `importance.rhf(guided = TRUE)`: with many variables (roughly 50 or more) it gives a much sparser importance, at the cost of a second forest and of possibly zeroing weak effects, so `guided = FALSE` stays the default. `print.importance.rhf()` now points this out for unguided results with 50 or more variables.

# randomForestRHF 2.0.3
    
* Added direct `Surv(time, event)` support to fitting, prediction, restore, and tree-size tuning. Ordinary right-censored data are converted internally to one interval per subject, fitted forests retain the original response map, and `predict.rhf()` accepts test data using the original time/event column names; the four-argument counting-process interface remains available for time-dependent covariates.
* Distinguished public prediction domains by original response format across grow, restore, and outcome-bearing prediction. Right-censored, time-static fits now return hazard and CHF over the complete forest horizon; counting-process fits keep hazards `NA` outside supplied paths, keep CHF flat through internal gaps, and set CHF to `NA` after each subject's final stop.
* Made the tree-size tuning preflight use the same normalized data, event-process classification, and event-supported bounds as `rhf()`, including when an explicit upper bound is supplied.
* Corrected cumulative/dynamic `auct.rhf()` to reconstruct common-time markers from retained tree-level hazard/CHF arrays using the fitted ensemble aggregation rule, including Nelson--Aalen mean aggregation and the exact-median endpoint, while leaving public path-domain predictions unchanged. AUC output now records marker diagnostics and reports a clear error when required raw arrays are unavailable.
* Corrected the incident-AUC tuning example to use a feasible grouped-case threshold, preventing an all-nonfinite criterion when `--run-donttest` examples are checked.

# randomForestRHF 2.0.0

* Added the native Conservation-of-Events (COE) terminal-node hazard estimator and robust across-tree aggregation. The default adaptive protocol selects a winsorization fraction by OOB risk; median, mean, fixed trimming, and the legacy Nelson--Aalen estimator remain available.
* Corrected OOB hazard risk, cumulative-hazard integration, and case-specific trajectory construction to use exact start--stop/grid overlap.
* Case-specific hazards are now `NA` outside the supplied `(start, stop]` paths, while cumulative hazards remain flat through gaps and after follow-up.
* Made grow, restore, and outcome-bearing prediction share the fitted hazard configuration and return coherent risk, membership, tree-level hazard/CHF, and terminal-node `U`, `V`, and COE outputs.
* Strengthened counting-process validation and event bookkeeping. Unsupported recurrent-event histories are now detected and reported explicitly.
* Reworked default tree sizing and tree-size tuning to use observed event support, preserve time-grid and aggregation settings, and reproducibly refit the selected forest.
* Improved `auct.rhf()` subject-level bootstrapping and expanded time-localized VarPro tools with pilot-forest predictor weights and bar-matrix, dot-matrix, and line displays.
* Renamed the survival split rules to `hazard.loglik` and `hazard.nelson.aalen`. Importance plotting arguments now use dotted names, `xvar.wt.rhf()` uses the pilot/cache interface, and `treesize` should be numeric.

# randomForestRHF 1.0.1

* Maintenance update with bug fixes and CRAN-related cleanups.
* Added explicit POSIX socket/select header includes in `src/server.h` for improved musl/Alpine compatibility.
* Replaced unsuppressible console output in `print.rhf()`, `print.auct.rhf()`, and RHF importance helpers with suppressible message-based output.
* Hardened prediction and native-interface handling, including more robust checks for variable-level metadata passed from R to compiled code.
* Updated native routine registration to match the current C entry-point signatures and applied minor build/source cleanups.
  
# randomForestRHF 1.0.0

* Initial release.
