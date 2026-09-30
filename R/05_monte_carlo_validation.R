# ============================================================
# PROJECT:
# Risk-Constrained Acceptance Sampling for Food Import
# Quality Assurance: A Milk-Powder Case Study
#
# SCRIPT:
# Monte Carlo Validation of Variables Sampling Plan
#
# Plan:
# n = 70
# k = 1.99
#
# Purpose:
# Compare theoretical noncentral-t acceptance probabilities
# with empirical Monte Carlo acceptance probabilities.
# ============================================================

library(ggplot2)


# ============================================================
# STEP 1: PARAMETERS
# ============================================================

U <- 5

n <- 70
k <- 1.99

# Assumed standard deviation for simulation
sigma <- 0.30

# Number of Monte Carlo replications per quality level
R <- 10000

# True nonconforming proportions
p_values <- c(
  0.005,
  0.01,
  0.02,
  0.03,
  0.04,
  0.05,
  0.075,
  0.10
)

# Reproducibility
set.seed(123)


# ============================================================
# STEP 2: THEORETICAL ACCEPTANCE PROBABILITY
#
# Under normality:
#
# z_p = qnorm(1-p)
#
# ncp = -z_p * sqrt(n)
#
# P(accept) =
# P[T <= -k*sqrt(n)]
#
# where T follows a noncentral t distribution.
# ============================================================

P_accept_theoretical <- function(p) {

  z_p <- qnorm(1 - p)

  ncp <- -z_p * sqrt(n)

  pt(
    -k * sqrt(n),
    df = n - 1,
    ncp = ncp
  )
}


# ============================================================
# STEP 3: MONTE CARLO FUNCTION
# ============================================================

P_accept_MC <- function(p) {

  # Choose mu so that:
  #
  # P(X > U) = p
  #
  # under X ~ Normal(mu, sigma^2)

  z_p <- qnorm(1 - p)

  mu <- U - sigma * z_p

  accepted <- logical(R)

  for (r in 1:R) {

    # Generate sample
    x <- rnorm(
      n,
      mean = mu,
      sd = sigma
    )

    # Calculate variables-sampling statistic
    Q <- (U - mean(x)) / sd(x)

    # Apply decision rule
    accepted[r] <- Q >= k
  }

  mean(accepted)
}


# ============================================================
# STEP 4: RUN SIMULATION
# ============================================================

theoretical_Pa <- sapply(
  p_values,
  P_accept_theoretical
)

MC_Pa <- sapply(
  p_values,
  P_accept_MC
)


# ============================================================
# STEP 5: RESULTS TABLE
# ============================================================

validation_results <- data.frame(
  p = p_values,
  theoretical = theoretical_Pa,
  monte_carlo = MC_Pa
)

validation_results$error <- (
  validation_results$monte_carlo -
    validation_results$theoretical
)

validation_results$absolute_error <- abs(
  validation_results$error
)

print(validation_results)


# ============================================================
# STEP 6: MEAN ABSOLUTE ERROR
# ============================================================

MAE <- mean(
  validation_results$absolute_error
)

cat("\n==============================\n")
cat("MONTE CARLO VALIDATION\n")
cat("==============================\n")

cat(
  "Replications per quality level =",
  R,
  "\n"
)

cat(
  "Mean absolute error =",
  MAE,
  "\n"
)

cat(
  "Mean absolute error (rounded) =",
  round(MAE, 4),
  "\n"
)


# ============================================================
# STEP 7: CREATE SMOOTH THEORETICAL OC CURVE
# ============================================================

p_curve <- seq(
  0.001,
  0.10,
  by = 0.0005
)

theoretical_curve <- sapply(
  p_curve,
  P_accept_theoretical
)

curve_data <- data.frame(
  p = p_curve,
  Pa = theoretical_curve
)


# ============================================================
# STEP 8: PLOT MONTE CARLO VS THEORY
# ============================================================

mc_plot <- ggplot() +

  geom_line(
    data = curve_data,
    aes(
      x = p * 100,
      y = Pa
    ),
    linewidth = 1.1
  ) +

  geom_point(
    data = validation_results,
    aes(
      x = p * 100,
      y = monte_carlo
    ),
    size = 3
  ) +

  geom_vline(
    xintercept = 1,
    linetype = "dashed"
  ) +

  geom_vline(
    xintercept = 5,
    linetype = "dashed"
  ) +

  labs(
    title = "Monte Carlo Validation of Variables Sampling Plan",
    subtitle =
      "Points: simulation | Line: theoretical noncentral-t OC curve",
    x = "True Nonconforming Proportion (%)",
    y = "Probability of Accepting Shipment"
  ) +

  theme_minimal(base_size = 13) +

  theme(
    plot.title = element_text(face = "bold")
  )


print(mc_plot)


# ============================================================
# STEP 9: SAVE FIGURE
# ============================================================

ggsave(
  filename = "monte_carlo_validation.png",
  plot = mc_plot,
  width = 10,
  height = 6,
  dpi = 300
)


# ============================================================
# STEP 10: SAVE RESULTS
# ============================================================

write.csv(
  validation_results,
  "monte_carlo_validation_results.csv",
  row.names = FALSE
)


# ============================================================
# FINAL INTERPRETATION
# ============================================================

cat("\nINTERPRETATION:\n")

cat(
  "The Monte Carlo acceptance probabilities should closely",
  " reproduce the theoretical noncentral-t OC curve under",
  " the assumed normal moisture model.\n"
)

cat(
  "This validates the probability calculations computationally,",
  " but does not establish that real milk-powder moisture data",
  " follow a normal distribution.\n"
)
