# ============================================================
# PROJECT:
# Risk-Constrained Acceptance Sampling for Food Import
# Quality Assurance: A Milk-Powder Case Study
#
# SCRIPT:
# OC Curve Comparison
#
# Compares:
# 1. Attributes plan: n = 181, c = 4
# 2. Variables plan (unknown sigma): n = 70, k = 1.99
# ============================================================

library(ggplot2)


# ============================================================
# STEP 1: DESIGN PARAMETERS
# ============================================================

AQL  <- 0.01
LTPD <- 0.05

n_attr <- 181
c_attr <- 4

n_var <- 70
k_var <- 1.99


# ============================================================
# STEP 2: ATTRIBUTES ACCEPTANCE PROBABILITY
# ============================================================

P_accept_attr <- function(p) {
  
  pbinom(
    c_attr,
    size = n_attr,
    prob = p
  )
}


# ============================================================
# STEP 3: VARIABLES ACCEPTANCE PROBABILITY
# Unknown sigma - noncentral t
# ============================================================

P_accept_var <- function(p) {
  
  z_p <- qnorm(1 - p)
  
  ncp <- -z_p * sqrt(n_var)
  
  pt(
    -k_var * sqrt(n_var),
    df = n_var - 1,
    ncp = ncp
  )
}


# ============================================================
# STEP 4: GENERATE OC CURVES
# ============================================================

# Start slightly above zero because qnorm(1) is infinite
p_values <- seq(
  0.0001,
  0.10,
  by = 0.0005
)

Pa_attr <- sapply(
  p_values,
  P_accept_attr
)

Pa_var <- sapply(
  p_values,
  P_accept_var
)


# ============================================================
# STEP 5: COMBINE DATA
# ============================================================

oc_comparison <- rbind(
  
  data.frame(
    defect_rate = p_values,
    acceptance_probability = Pa_attr,
    Plan = "Attributes (n=181, c=4)"
  ),
  
  data.frame(
    defect_rate = p_values,
    acceptance_probability = Pa_var,
    Plan = "Variables (n=70, k=1.99)"
  )
)


# ============================================================
# STEP 6: CHECK DESIGN POINTS
# ============================================================

cat("\n==============================\n")
cat("OC CURVE DESIGN POINTS\n")
cat("==============================\n")

cat("\nATTRIBUTES PLAN\n")

cat(
  "P(accept at AQL) =",
  round(P_accept_attr(AQL), 4),
  "\n"
)

cat(
  "P(accept at LTPD) =",
  round(P_accept_attr(LTPD), 4),
  "\n"
)


cat("\nVARIABLES PLAN\n")

cat(
  "P(accept at AQL) =",
  round(P_accept_var(AQL), 4),
  "\n"
)

cat(
  "P(accept at LTPD) =",
  round(P_accept_var(LTPD), 4),
  "\n"
)


# ============================================================
# STEP 7: PLOT COMPARISON
# ============================================================

oc_plot <- ggplot(
  oc_comparison,
  aes(
    x = defect_rate * 100,
    y = acceptance_probability,
    linetype = Plan
  )
) +
  
  geom_line(linewidth = 1.1) +
  
  geom_vline(
    xintercept = AQL * 100,
    linetype = "dotted"
  ) +
  
  geom_vline(
    xintercept = LTPD * 100,
    linetype = "dotted"
  ) +
  
  annotate(
    "text",
    x = AQL * 100,
    y = 0.55,
    label = "AQL = 1%",
    angle = 90,
    vjust = -0.5
  ) +
  
  annotate(
    "text",
    x = LTPD * 100,
    y = 0.55,
    label = "LTPD = 5%",
    angle = 90,
    vjust = -0.5
  ) +
  
  labs(
    title = "Operating Characteristic Curve Comparison",
    subtitle =
      "Attributes vs Variables Acceptance Sampling",
    x = "True Nonconforming Proportion (%)",
    y = "Probability of Accepting Shipment",
    linetype = "Sampling Plan"
  ) +
  
  theme_minimal(base_size = 13) +
  
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )


# Display plot
print(oc_plot)


# ============================================================
# STEP 8: SAVE HIGH-RESOLUTION FIGURE
# ============================================================

ggsave(
  filename = "oc_curve_comparison.png",
  plot = oc_plot,
  width = 10,
  height = 6,
  dpi = 300
)


# ============================================================
# STEP 9: SAMPLE-SIZE COMPARISON
# ============================================================

reduction <- (
  (n_attr - n_var) /
    n_attr
) * 100

cat("\n==============================\n")
cat("SAMPLE-SIZE COMPARISON\n")
cat("==============================\n")

cat(
  "Attributes plan: n =",
  n_attr,
  "\n"
)

cat(
  "Variables plan: n =",
  n_var,
  "\n"
)

cat(
  "Reduction =",
  round(reduction, 2),
  "%\n"
)
