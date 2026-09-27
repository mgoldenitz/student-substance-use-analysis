# =====================================================================
# Student Addiction Project: MATH59854 methods in R
# Each section applies one course module to student_addiction_dataset_test.csv
# Base R only (no packages to install). Run section by section with Ctrl+Enter.
# Expected results are in the comments so you can check your output.
# =====================================================================

# ---- Setup -----------------------------------------------------------
setwd("C:/Users/mgold/OneDrive/Desktop/Career/Student_Drugs_Addiction_Testing_ Dataset")
raw <- read.csv("student_addiction_dataset_test.csv", na.strings = c("", "NA"))
factors <- names(raw)[1:10]

df  <- na.omit(raw)                                   # 7,516 complete rows (same as Power BI)
yes <- as.data.frame(lapply(df[factors], function(x) as.integer(x == "Yes")))
df$risk_score <- rowSums(yes)
df$addicted   <- as.integer(df$Addiction_Class == "Yes")
cat("Raw rows:", nrow(raw), "  Complete rows:", nrow(df), "\n")   # 12744 / 7516

# ---- Module 2 · Frequency distributions -------------------------------
freq <- table(df$risk_score)
freq_table <- data.frame(score      = names(freq),
                         count      = as.vector(freq),
                         percent    = round(as.vector(prop.table(freq)) * 100, 1),
                         cumulative = round(cumsum(as.vector(prop.table(freq))) * 100, 1))
print(freq_table)                                     # score 3 is most common: 1,923 (25.6%)
round(sort(colMeans(is.na(raw[factors])) * 100, decreasing = TRUE), 1)   # 4.8% to 5.4% missing

# ---- Module 3 · Measures of centre & spread ---------------------------
s <- df$risk_score
mode_val <- as.numeric(names(which.max(table(s))))
skewness <- mean((s - mean(s))^3) / sd(s)^3
round(c(mean = mean(s), median = median(s), mode = mode_val, variance = var(s),
        sd = sd(s), IQR = IQR(s), skewness = skewness), 3)
# mean 3.073, median 3, mode 3, variance 2.164, sd 1.471, IQR 2, skewness ~0.22 (slight right skew)
aggregate(risk_score ~ Addiction_Class, data = df,
          FUN = function(x) round(c(mean = mean(x), median = median(x), sd = sd(x), n = length(x)), 3))
# No: mean 3.059 (n 5987) | Yes: mean 3.129 (n 1529)

# ---- Module 4 · Visualization ----------------------------------------
par(mfrow = c(1, 2))
barplot(freq, col = "#426871", border = NA, main = "Students by risk score",
        xlab = "Risk score (warning signs)", ylab = "Students")
boxplot(risk_score ~ Addiction_Class, data = df, col = c("#998F85", "#C25A3D"),
        main = "Risk score by addiction status", xlab = "Addiction reported", ylab = "Risk score")
par(mfrow = c(1, 1))

# ---- Module 5 · Correlation & simple linear regression ----------------
cor(df$risk_score, df$addicted)                       # r = 0.019
model <- lm(addicted ~ risk_score, data = df)
summary(model)                                        # slope 0.0052, R-squared 0.0004, p 0.099
cm <- cor(yes); diag(cm) <- NA
max(abs(cm), na.rm = TRUE)                            # 0.03: the 10 factors barely relate to each other

# ---- Module 6 · Probability --------------------------------------------
p_add  <- mean(df$addicted)
p_risk <- mean(df$Risk_Taking_Behavior == "Yes")
p_both <- mean(df$addicted == 1 & df$Risk_Taking_Behavior == "Yes")
round(c(P_addiction = p_add, P_addiction_given_risk = p_both / p_risk,
        P_both_if_independent = p_add * p_risk, P_both_observed = p_both), 4)
# 0.203 / 0.224 / 0.0628 / 0.0692

# ---- Module 8 · Binomial distribution ----------------------------------
# If the 10 answers were independent coin flips, risk_score ~ Binomial(10, p)
p_yes <- mean(as.matrix(yes))                         # 0.307
k <- 0:10
comparison <- data.frame(score = k,
                         observed = as.vector(table(factor(s, levels = k))),
                         binomial_expected = round(dbinom(k, 10, p_yes) * nrow(df)))
print(comparison)                                     # observed and expected are almost identical
c(observed_mean = mean(s), binomial_mean = 10 * p_yes,
  observed_var = var(s), binomial_var = 10 * p_yes * (1 - p_yes))   # 3.07/3.07, 2.16/2.13
barplot(t(as.matrix(comparison[, 2:3])), beside = TRUE, names.arg = k,
        col = c("#426871", "#C25A3D"), legend.text = c("Observed", "Binomial model"),
        main = "Observed vs binomial model", xlab = "Risk score")

# ---- Module 9 · Normal distribution & 68-95-99.7 -----------------------
m <- mean(s); sdv <- sd(s)
sapply(1:3, function(k) mean(s >= m - k * sdv & s <= m + k * sdv))   # 68.9%, 96.1%, 99.8%
z <- (s - m) / sdv
sum(z > 2)                                            # 91 students = your "High" risk level

# ---- Module 10 · Confidence intervals ----------------------------------
prop.test(sum(df$addicted), nrow(df))$conf.int         # addiction rate 95% CI: about 19.4% to 21.3%
t.test(s)$conf.int                                     # mean risk score 95% CI: about 3.04 to 3.11

# ---- Module 11 · A/B-style comparison -----------------------------------
# Group A = addiction reported, group B = not reported
t.test(risk_score ~ Addiction_Class, data = df)        # p about 0.095: not significant at 0.05
a <- s[df$addicted == 1]; b <- s[df$addicted == 0]
(mean(a) - mean(b)) / sqrt((var(a) + var(b)) / 2)      # Cohen's d = 0.048: negligible effect
# Note: this dataset has no dates, so time-series forecasting needs a different dataset.
