# ============================================================
# PROJECT:
# Risk-Constrained Acceptance Sampling for FSSAI Food Imports
# ============================================================

# Install once if required
# install.packages("ggplot2")

library(ggplot2)


# ============================================================
# STEP 1: DEFINE QUALITY AND RISK PARAMETERS
# ============================================================

AQL  <- 0.01
LTPD <- 0.05
alpha <- 0.05
beta  <- 0.05
cat("AQL =", AQL, "\n")
cat("LTPD =", LTPD, "\n")
cat("Producer risk alpha =", alpha, "\n")
cat("Consumer risk beta =", beta, "\n")


# ============================================================
# STEP 2: PROBABILITY OF ACCEPTING A LOT
#
# For an attributes sampling plan (n,c):
#
# Accept shipment if number of defectives <= c
#
# X ~ Binomial(n,p)
#
# P(accept) = P(X <= c)
# ============================================================

P_accept <- function(p, n, c) {
  pbinom(c, size = n, prob = p)
}


# ============================================================
# STEP 3: SEARCH FOR THE MINIMUM SAMPLE SIZE
#
# Requirements:
#
# P(accept | p = AQL) >= 1 - alpha
#
# P(accept | p = LTPD) <= beta
# ============================================================

results <- data.frame()

for (n in 1:1000) {
  
  for (c in 0:min(n, 30)) {
    
    Pa_AQL  <- P_accept(AQL, n, c)
    Pa_LTPD <- P_accept(LTPD, n, c)
    
    if (Pa_AQL >= (1 - alpha) &&
        Pa_LTPD <= beta) {
      
      results <- rbind(
        results,
        data.frame(
          n = n,
          c = c,
          Pa_AQL = Pa_AQL,
          Pa_LTPD = Pa_LTPD
        )
      )
    }
  }
}


# ============================================================
# STEP 4: FIND OPTIMAL PLAN
# ============================================================

if (nrow(results) == 0) {
  
  stop("No feasible sampling plan found. Increase search range.")
  
}

results <- results[order(results$n, results$c), ]

optimal <- results[1, ]

n_opt <- optimal$n
c_opt <- optimal$c

cat("\n==============================\n")
cat("OPTIMAL SAMPLING PLAN\n")
cat("==============================\n")

cat("Sample size n =", n_opt, "\n")
cat("Acceptance number c =", c_opt, "\n")

cat(
  "Probability of accepting AQL lot =",
  round(optimal$Pa_AQL, 4),
  "\n"
)

cat(
  "Probability of accepting LTPD lot =",
  round(optimal$Pa_LTPD, 4),
  "\n"
)


# ============================================================
# STEP 5: ACTUAL PRODUCER AND CONSUMER RISKS
# ============================================================

actual_alpha <- 1 - optimal$Pa_AQL
actual_beta  <- optimal$Pa_LTPD

cat("\nActual producer risk =", round(actual_alpha, 4), "\n")
cat("Actual consumer risk =", round(actual_beta, 4), "\n")


# ============================================================
# STEP 6: GENERATE OC CURVE
# ============================================================

p_values <- seq(0, 0.10, by = 0.0005)

Pa_values <- P_accept(
  p_values,
  n_opt,
  c_opt
)

oc_data <- data.frame(
  defect_rate = p_values,
  acceptance_probability = Pa_values
)


# ============================================================
# STEP 7: PLOT OC CURVE
# ============================================================

ggplot(
  oc_data,
  aes(
    x = defect_rate * 100,
    y = acceptance_probability
  )
) +
  
  geom_line(linewidth = 1.2) +
  
  geom_point(
    data = data.frame(
      defect_rate = c(AQL, LTPD),
      acceptance_probability = c(
        P_accept(AQL, n_opt, c_opt),
        P_accept(LTPD, n_opt, c_opt)
      )
    ),
    aes(
      x = defect_rate * 100,
      y = acceptance_probability
    ),
    size = 3
  ) +
  
  geom_vline(
    xintercept = AQL * 100,
    linetype = "dashed"
  ) +
  
  geom_vline(
    xintercept = LTPD * 100,
    linetype = "dashed"
  ) +
  
  labs(
    title = "Operating Characteristic Curve",
    subtitle = paste(
      "Optimal Sampling Plan: n =",
      n_opt,
      ", c =",
      c_opt
    ),
    x = "Actual Defective Rate (%)",
    y = "Probability of Accepting Shipment"
  ) +
  
  theme_minimal(base_size = 13)


# ============================================================
# STEP 8: DISPLAY FIRST FEASIBLE SAMPLING PLANS
# ============================================================

head(results, 10)


# ============================================================
# STEP 9: COMPARE MULTIPLE SAMPLING PLANS
# ============================================================

plans <- head(results, 4)

comparison <- data.frame()

for (i in 1:nrow(plans)) {
  
  temp <- data.frame(
    p = p_values,
    Pa = P_accept(
      p_values,
      plans$n[i],
      plans$c[i]
    ),
    Plan = paste0(
      "n=", plans$n[i],
      ", c=", plans$c[i]
    )
  )
  
  comparison <- rbind(comparison, temp)
}


ggplot(
  comparison,
  aes(
    x = p * 100,
    y = Pa,
    linetype = Plan
  )
) +
  
  geom_line(linewidth = 1) +
  
  geom_vline(
    xintercept = AQL * 100,
    linetype = "dotted"
  ) +
  
  geom_vline(
    xintercept = LTPD * 100,
    linetype = "dotted"
  ) +
  
  labs(
    title = "Comparison of Feasible Acceptance Sampling Plans",
    x = "Defective Rate (%)",
    y = "Probability of Acceptance"
  ) +
  
  theme_minimal(base_size = 13)


# ============================================================
# STEP 10: FINITE LOT CORRECTION
#
# Binomial assumes an effectively large population.
# For a finite shipment, use Hypergeometric distribution.
#
# Example shipment size = 5000 units
# ============================================================

N_lot <- 5000

P_accept_hyper <- function(p, N, n, c) {
  
  D <- round(p * N)       # defective units in entire shipment
  
  phyper(
    c,
    m = D,
    n = N - D,
    k = n
  )
}


Pa_AQL_hyper <- P_accept_hyper(
  AQL,
  N_lot,
  n_opt,
  c_opt
)

Pa_LTPD_hyper <- P_accept_hyper(
  LTPD,
  N_lot,
  n_opt,
  c_opt
)

cat("\n==============================\n")
cat("FINITE LOT VALIDATION\n")
cat("==============================\n")

cat("Lot size =", N_lot, "\n")

cat(
  "Hypergeometric P(accept at AQL) =",
  round(Pa_AQL_hyper, 4),
  "\n"
)

cat(
  "Hypergeometric P(accept at LTPD) =",
  round(Pa_LTPD_hyper, 4),
  "\n"
)


# ============================================================
# STEP 11: SENSITIVITY ANALYSIS FOR CONSUMER RISK
# ============================================================

beta_values <- c(0.10, 0.05, 0.025, 0.01)

sensitivity <- data.frame()

for (B in beta_values) {
  
  found <- FALSE
  
  for (n in 1:1500) {
    
    for (c in 0:min(n, 40)) {
      
      Pa_good <- P_accept(AQL, n, c)
      Pa_bad  <- P_accept(LTPD, n, c)
      
      if (
        Pa_good >= 1 - alpha &&
        Pa_bad <= B
      ) {
        
        sensitivity <- rbind(
          sensitivity,
          data.frame(
            beta = B,
            n = n,
            c = c,
            Pa_AQL = Pa_good,
            Pa_LTPD = Pa_bad
          )
        )
        
        found <- TRUE
        break
      }
    }
    
    if (found) break
  }
}

print(sensitivity)


# ============================================================
# STEP 12: PLOT SAFETY vs INSPECTION BURDEN
# ============================================================

ggplot(
  sensitivity,
  aes(
    x = beta * 100,
    y = n
  )
) +
  
  geom_line(linewidth = 1) +
  
  geom_point(size = 3) +
  
  scale_x_reverse() +
  
  labs(
    title = "Consumer Protection vs Inspection Burden",
    subtitle = "Stricter consumer risk requires larger samples",
    x = "Maximum Consumer Risk (%)",
    y = "Minimum Required Sample Size"
  ) +
  
  theme_minimal(base_size = 13)


# ============================================================
# FINAL SUMMARY
# ============================================================

cat("\n==============================\n")
cat("FINAL PROJECT SUMMARY\n")
cat("==============================\n")

cat(
  "For AQL =", AQL * 100, "% and LTPD =", LTPD * 100, "%,\n"
)

cat(
  "with alpha =", alpha,
  "and beta =", beta, ",\n"
)

cat(
  "the minimum binomial acceptance sampling plan is:\n"
)

cat(
  "n =", n_opt,
  "and c =", c_opt, "\n"
)

cat(
  "Therefore, randomly inspect",
  n_opt,
  "units from the imported shipment.\n"
)

cat(
  "Accept the shipment if no more than",
  c_opt,
  "defective units are observed.\n"
)

cat(
  "Reject the shipment if more than",
  c_opt,
  "defective units are observed.\n"
) This?
