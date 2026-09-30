# ============================================================
# PROJECT:
# Risk-Constrained Acceptance Sampling for Food Import
# Quality Assurance: A Milk-Powder Case Study
#
# SCRIPT:
# Robustness Analysis
#
# Purpose:
# Test how the variables sampling plan behaves when the
# normality assumption is violated.
#
# Variables plan:
# n = 70
# k = 1.99
# Upper specification limit U = 5%
# ============================================================

library(ggplot2)


# ============================================================
# STEP 1: PARAMETERS
# ============================================================

U <- 5
n <- 70
k <- 1.99

R <- 10000

p_values <- c(
  0.01,
  0.02,
  0.03,
  0.04,
  0.05
)

# Baseline standard deviation
sigma <- 0.30

set.seed(123)


# ============================================================
# STEP 2: DECISION FUNCTION
#
# Accept if:
#
# Q = (U - Xbar) / S >= k
# ============================================================

accept_sample <- function(x) {

  Q <- (U - mean(x)) / sd(x)

  Q >= k
}


# ============================================================
# STEP 3: NORMAL DISTRIBUTION
#
# Baseline model used to design the variables plan.
# ============================================================

simulate_normal <- function(p) {

  z <- qnorm(1 - p)

  mu <- U - sigma * z

  accepted <- logical(R)

  for (r in 1:R) {

    x <- rnorm(
      n,
      mean = mu,
      sd = sigma
    )

    accepted[r] <- accept_sample(x)
  }

  mean(accepted)
}


# ============================================================
# STEP 4: SHIFTED LOGNORMAL DISTRIBUTION
#
# Creates a right-skewed distribution.
#
# The distribution is shifted so that:
#
# P(X > U) = p
#
# Therefore all distributions are compared at the same
# true nonconforming proportion.
# ============================================================

simulate_lognormal <- function(p) {

  log_mean <- 0
  log_sd <- 0.25

  q <- qlnorm(
    1 - p,
    meanlog = log_mean,
    sdlog = log_sd
  )

  shift <- U - q

  accepted <- logical(R)

  for (r in 1:R) {

    x <- shift + rlnorm(
      n,
      meanlog = log_mean,
      sdlog = log_sd
    )

    accepted[r] <- accept_sample(x)
  }

  mean(accepted)
}


# ============================================================
# STEP 5: HEAVY-TAILED STUDENT-t DISTRIBUTION
#
# df = 5
#
# Scale is chosen so the distribution has approximately
# the same standard deviation as the normal baseline.
# ============================================================

simulate_t <- function(p) {

  df <- 5

  # SD of standard t(df) is sqrt(df/(df-2))
  scale_t <- sigma / sqrt(df / (df - 2))

  # Choose location so P(X > U) = p
  location <- U -
    scale_t * qt(1 - p, df = df)

  accepted <- logical(R)

  for (r in 1:R) {

    x <- location +
      scale_t * rt(
        n,
        df = df
      )

    accepted[r] <- accept_sample(x)
  }

  mean(accepted)
}


# ============================================================
# STEP 6: CONTAMINATED NORMAL DISTRIBUTION
#
# 95% of observations:
# N(mu, 0.30^2)
#
# 5% of observations:
# N(mu, 0.90^2)
#
# mu is calibrated numerically so that:
#
# P(X > U) = p
# ============================================================

simulate_contaminated <- function(p) {

  contamination <- 0.05

  sd_main <- 0.30
  sd_contaminated <- 0.90

  # Tail-probability function
  tail_probability <- function(mu) {

    (1 - contamination) *
      (1 - pnorm(
        U,
        mean = mu,
        sd = sd_main
      )) +

      contamination *
      (1 - pnorm(
        U,
        mean = mu,
        sd = sd_contaminated
      )) -

      p
  }

  # Solve for mu
  mu <- uniroot(
    tail_probability,
    interval = c(0, U)
  )$root

  accepted <- logical(R)

  for (r in 1:R) {

    contaminated <- runif(n) < contamination

    x <- numeric(n)

    x[!contaminated] <- rnorm(
      sum(!contaminated),
      mean = mu,
      sd = sd_main
    )

    x[contaminated] <- rnorm(
      sum(contaminated),
      mean = mu,
      sd = sd_contaminated
    )

    accepted[r] <- accept_sample(x)
  }

  mean(accepted)
}


# ============================================================
# STEP 7: RUN ROBUSTNESS SIMULATIONS
# ============================================================

normal_results <- sapply(
  p_values,
  simulate_normal
)

lognormal_results <- sapply(
  p_values,
  simulate_lognormal
)

t_results <- sapply(
  p_values,
  simulate_t
)

contaminated_results <- sapply(
  p_values,
  simulate_contaminated
)


# ============================================================
# STEP 8: RESULTS TABLE
# ============================================================

robust_results <- data.frame(

  p = p_values,

  Normal = normal_results,

  Shifted_Lognormal = lognormal_results,

  Heavy_Tailed = t_results,

  Contaminated_Normal = contaminated_results
)

print(robust_results)


# ============================================================
# STEP 9: PRODUCER RISK AT AQL = 1%
# ============================================================

producer_risk <- data.frame(

  Distribution = c(
    "Normal",
    "Shifted Lognormal",
    "Heavy-Tailed",
    "Contaminated Normal"
  ),

  Producer_Risk = c(
    1 - normal_results[1],
    1 - lognormal_results[1],
    1 - t_results[1],
    1 - contaminated_results[1]
  )
)

cat("\n==============================\n")
cat("PRODUCER RISK AT AQL = 1%\n")
cat("==============================\n")

print(producer_risk)


# ============================================================
# STEP 10: CONSUMER RISK AT LTPD = 5%
# ============================================================

consumer_risk <- data.frame(

  Distribution = c(
    "Normal",
    "Shifted Lognormal",
    "Heavy-Tailed",
    "Contaminated Normal"
  ),

  Consumer_Risk = c(
    normal_results[5],
    lognormal_results[5],
    t_results[5],
    contaminated_results[5]
  )
)

cat("\n==============================\n")
cat("CONSUMER RISK AT LTPD = 5%\n")
cat("==============================\n")

print(consumer_risk)


# ============================================================
# STEP 11: PREPARE DATA FOR PLOTTING
# ============================================================

plot_data <- rbind(

  data.frame(
    p = p_values,
    Pa = normal_results,
    Distribution = "Normal"
  ),

  data.frame(
    p = p_values,
    Pa = lognormal_results,
    Distribution = "Shifted Lognormal"
  ),

  data.frame(
    p = p_values,
    Pa = t_results,
    Distribution = "Heavy-Tailed"
  ),

  data.frame(
    p = p_values,
    Pa = contaminated_results,
    Distribution = "Contaminated Normal"
  )
)


# ============================================================
# STEP 12: ROBUSTNESS PLOT
# ============================================================

robust_plot <- ggplot(
  plot_data,
  aes(
    x = p * 100,
    y = Pa,
    linetype = Distribution,
    shape = Distribution
  )
) +

  geom_line(linewidth = 1) +

  geom_point(size = 2.5) +

  geom_vline(
    xintercept = 1,
    linetype = "dotted"
  ) +

  geom_vline(
    xintercept = 5,
    linetype = "dotted"
  ) +

  labs(
    title = "Robustness of Variables Acceptance Sampling",
    subtitle =
      "Effect of distributional misspecification on acceptance probability",
    x = "True Nonconforming Proportion (%)",
    y = "Probability of Accepting Shipment",
    linetype = "Distribution",
    shape = "Distribution"
  ) +

  theme_minimal(base_size = 13) +

  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )


print(robust_plot)


# ============================================================
# STEP 13: SAVE FIGURE
# ============================================================

ggsave(
  filename = "robustness_analysis.png",
  plot = robust_plot,
  width = 10,
  height = 6,
  dpi = 300
)


# ============================================================
# STEP 14: SAVE RESULTS
# ============================================================

write.csv(
  robust_results,
  "robustness_results.csv",
  row.names = FALSE
)


# ============================================================
# FINAL INTERPRETATION
# ============================================================

cat("\n==============================\n")
cat("INTERPRETATION\n")
cat("==============================\n")

cat(
  "The variables sampling plan is highly efficient under",
  " the normal model, but its nominal risk guarantees are",
  " not distribution-free.\n"
)

cat(
  "Differences between the simulated distributions show",
  " how distributional misspecification can alter producer",
  " and consumer risks.\n"
)
