# Independent read-only review: review-final4

Static review corroborates v1→v2 epoch correction and independent raw lookahead formula against pwm_three_phase.sv45–59 / pwm_timebase.sv19–30. Actual full-file diff contains only monitor sampling and additional golden check; allv1 calls retained in order, no stimulus/DUT/timing/adapter changes.

44 original assertion callsites refer to ../pwm_cut_sdf_20261113_1631/v1/pwm_cut_tb.sv, not thisroundv1: round4v1 has50, finalv2 has51. static_validation.json measured exact old-to-final ordered check-call preservation (excluding taskdeclaration); no hashes used.

Scope caveat: external pclk sampling of debugrequest aligns logical epochs; it does NOT independently prove internal outputFF physical clockarrival/data sampling equivalence underSDF. All native timingchecks remainenabled; output/Q/deadtime/atomicbank assertions still independentlyrequired. Nonvalley rawgolden uses DUTactive_compare plus existing atomicbankchecks, pendinguses sourceoffered[live_id] underoneinflightprotocol. Formula hardcodes existing10000/5000 parameters and applies within safe&&started only; inhibit/reset/cancel covered by separate retained checks. These limitations mustremain in finalreport. Do not claim fullphysicalFFsamplingprooffromthismonitoralone.
