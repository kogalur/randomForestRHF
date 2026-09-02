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
