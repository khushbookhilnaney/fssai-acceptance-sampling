# ============================================================
# PROJECT:
# Risk-Constrained Acceptance Sampling for Food Import
# Quality Assurance: A Milk-Powder Case Study
#
# SCRIPT:
# Variables Acceptance Sampling - Unknown Sigma
#
# NOTE:
# Unlike the known-sigma benchmark, process variability is
# estimated using the sample standard deviation S.
#
# AQL, LTPD, alpha, and beta are study design assumptions
# and are not FSSAI-prescribed sampling parameters.
# ============================================================


# ============================================================
# STEP 1: DEFINE PARAMETERS
# ============================================================

AQL   <- 0.01
LTPD  <- 0.05
alpha <- 0.05
beta  <- 0.05

# Upper specification limit for moisture (%)
U <- 5


# ============================================================
# STEP 2: DEFINE ACCEPTANCE PROBABILITY
#
# Quality statistic:
#
# Q = (U - Xbar) / S
#
# Accept lot if:
#
# Q >= k
#
# Under normality:
#
# T = sqrt(n) * (Xbar - U) / S
#
# follows a noncentral t distribution.
#
# If p = P(X > U), then
#
# z_p = qnorm(1 - p)
#
# and the noncentrality parameter is:
#
# ncp = -z_p * sqrt(n)
#
# Since Q >= k is equivalent to:
#
# T <= -k * sqrt(n)
#
# the acceptance probability can be calculated using pt().
# ============================================================

P_accept_unknown <- function(p, n, k) {

  z_p <- qnorm(1 - p)

  ncp <- -z_p * sqrt(n)

  pt(
    -k * sqrt(n),
    df = n - 1,
    ncp = ncp
  )
}


# ============================================================
# STEP 3: SEARCH FOR MINIMUM FEASIBLE PLAN
# ============================================================

results_unknown <- data.frame()

# Search over sample sizes
for (n in 2:500) {

  # Search over possible acceptance constants
  k_values <- seq(
    0.5,
    3.5,
    by = 0.0005
  )

  for (k in k_values) {

    Pa_AQL <- P_accept_unknown(
      AQL,
      n,
      k
    )

    Pa_LTPD <- P_accept_unknown(
      LTPD,
      n,
      k
    )

    # Risk constraints
    if (
      Pa_AQL >= (1 - alpha) &&
      Pa_LTPD <= beta
    ) {

      results_unknown <- rbind(
        results_unknown,
        data.frame(
          n = n,
          k = k,
          Pa_AQL = Pa_AQL,
          Pa_LTPD = Pa_LTPD
        )
      )

      # First feasible k is enough for this n
      break
    }
  }
}


# ============================================================
# STEP 4: FIND MINIMUM SAMPLE SIZE
# ============================================================

if (nrow(results_unknown) == 0) {

  stop(
    "No feasible unknown-sigma variables plan found."
  )
}

results_unknown <- results_unknown[
  order(results_unknown$n),
]

optimal_unknown <- results_unknown[1, ]

n_var <- optimal_unknown$n
k_var <- optimal_unknown$k


# ============================================================
# STEP 5: DISPLAY OPTIMAL PLAN
# ============================================================

cat("\n==============================\n")
cat("UNKNOWN-SIGMA VARIABLES PLAN\n")
cat("==============================\n")

cat(
  "Sample size n =",
  n_var,
  "\n"
)

cat(
  "Acceptance constant k =",
  round(k_var, 4),
  "\n"
)

cat(
  "P(accept at AQL) =",
  round(optimal_unknown$Pa_AQL, 4),
  "\n"
)

cat(
  "P(accept at LTPD) =",
  round(optimal_unknown$Pa_LTPD, 4),
  "\n"
)


# ============================================================
# STEP 6: ACTUAL RISKS
# ============================================================

actual_alpha <- 1 - optimal_unknown$Pa_AQL
actual_beta  <- optimal_unknown$Pa_LTPD

cat(
  "\nActual producer risk =",
  round(actual_alpha, 4),
  "\n"
)

cat(
  "Actual consumer risk =",
  round(actual_beta, 4),
  "\n"
)


# ============================================================
# STEP 7: COMPARE WITH ATTRIBUTES SAMPLING
# ============================================================

n_attributes <- 181

sample_reduction <- (
  (n_attributes - n_var) /
    n_attributes
) * 100

cat("\n==============================\n")
cat("COMPARISON WITH ATTRIBUTES PLAN\n")
cat("==============================\n")

cat(
  "Attributes sample size =",
  n_attributes,
  "\n"
)

cat(
  "Variables sample size =",
  n_var,
  "\n"
)

cat(
  "Sample-size reduction =",
  round(sample_reduction, 2),
  "%\n"
)


# ============================================================
# STEP 8: PRACTICAL DECISION RULE
# ============================================================

cat("\n==============================\n")
cat("DECISION RULE\n")
cat("==============================\n")

cat(
  "Take",
  n_var,
  "milk-powder moisture measurements.\n"
)

cat(
  "Calculate the sample mean Xbar and",
  "sample standard deviation S.\n"
)

cat(
  "Calculate Q = (5 - Xbar) / S.\n"
)

cat(
  "Accept the lot if Q >=",
  round(k_var, 4),
  "\n"
)

cat(
  "Otherwise reject the lot under",
  "the proposed statistical rule.\n"
)


# ============================================================
# STEP 9: SHOW FIRST FEASIBLE PLANS
# ============================================================

head(results_unknown, 10)


# ============================================================
# FINAL SUMMARY
# ============================================================

cat("\n==============================\n")
cat("FINAL SUMMARY\n")
cat("==============================\n")

cat(
  "Under the assumed normal model with unknown sigma,\n"
)

cat(
  "the optimized variables sampling plan requires n =",
  n_var,
  "observations with k =",
  round(k_var, 4),
  ".\n"
)

cat(
  "Compared with the attributes plan requiring 181 units,\n"
)

cat(
  "this represents a",
  round(sample_reduction, 2),
  "% reduction in required sample size.\n"
)
