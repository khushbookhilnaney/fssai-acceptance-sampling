cat("KNOWN-SIGMA VARIABLES PLAN\n")
KNOWN-SIGMA VARIABLES PLAN
> cat("==============================\n")
==============================
> 
> cat(
+   "Sample size n =",
+   optimal_known$n,
+   "\n"
+ )
Sample size n = 24 
> 
> cat(
+   "Acceptance constant k =",
+   round(optimal_known$k, 4),
+   "\n"
+ )
Acceptance constant k = 1.9806 
> 
> cat(
+   "P(accept at AQL) =",
+   round(optimal_known$Pa_AQL, 4),
+   "\n"
+ )
P(accept at AQL) = 0.9548 
> 
> cat(
+   "P(accept at LTPD) =",
+   round(optimal_known$Pa_LTPD, 4),
+   "\n"
+ )
P(accept at LTPD) = 0.05 
> 
> 
> # ============================================================
> # STEP 6: COMPARE WITH ATTRIBUTES PLAN
> # ============================================================
> 
> n_attributes <- 181
> 
> reduction_known <- (
+   (n_attributes - optimal_known$n) /
+     n_attributes
+ ) * 100
> 
> cat(
+   "\nSample-size reduction relative to attributes plan =",
+   round(reduction_known, 2),
+   "%\n"
+ )

Sample-size reduction relative to attributes plan = 86.74 %
> 
> 
> # ============================================================
> # STEP 7: DECISION RULE
> # ============================================================
> 
> cat("\nDecision rule:\n")

Decision rule:
> 
> cat(
+   "Take",
+   optimal_known$n,
+   "measurements of moisture content.\n"
+ )
Take 24 measurements of moisture content.
> 
> cat(
+   "Calculate Q = (U - Xbar) / sigma.\n"
+ )
Calculate Q = (U - Xbar) / sigma.
> 
> cat(
+   "Accept the lot if Q >=",
+   round(optimal_known$k, 4),
+   "\n"
+ )
Accept the lot if Q >= 1.9806 
> 
> 
> # ============================================================
> # IMPORTANT INTERPRETATION
> # ============================================================
> 
> cat("\nNOTE:\n")

NOTE:
> 
> cat(
+   "This result assumes that the true process standard deviation",
+   " sigma is known.\n"
+ )
This result assumes that the true process standard deviation  sigma is known.
> 
> cat(
+   "It is therefore treated as a theoretical efficiency benchmark",
+   " rather than the primary practical sampling plan.\n"
+ )
It is therefore treated as a theoretical efficiency benchmark  rather than the primary practical sampling plan.
