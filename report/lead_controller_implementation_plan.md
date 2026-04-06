# Lead Controller Implementation Guide (Simplified Analytic LGR)

## 1. Scope and Design Decisions

This guide defines a simplified analytic implementation for the lead branch.

Key decisions:
- Single design mode only (no strict/relaxed dual run).
- No penalty-based objective function.
- No grid search over controller parameters.
- Accept controller outcome even if final placement is lag-like.

Controller form kept in implementation:

$$
G_c(z)=K_c\frac{z-z_c}{z-p_c}
$$

Classification (for reporting only):
- lead-like if $z_c > p_c$
- lag-like if $z_c < p_c$

Both are acceptable if closed-loop behavior is valid and stable.

## 2. Analytic Formula Sheet

### 2.1 Time-domain target to desired pole

From design targets $Mp(\%)$ and $t_p$ (or $t_s$):

$$
M_p=\frac{\text{Mp(\%)}}{100}
$$

$$
\zeta=\frac{-\ln(M_p)}{\sqrt{\pi^2+\ln^2(M_p)}}
$$

If using peak-time target:

$$
\omega_n=\frac{\pi}{t_p\sqrt{1-\zeta^2}}
$$

If using settling-time target (2% approximation):

$$
\omega_n\approx\frac{4}{\zeta t_s}
$$

$$
s_d=-\zeta\omega_n + j\omega_n\sqrt{1-\zeta^2},\quad z_d=e^{s_dT}
$$

### 2.2 Angle condition (analytic solve for one parameter)

Let $z_d=a+jb$ and choose one controller location (usually $z_c$) directly.

For root locus:

$$
\angle\left(G_z(z_d)\right)+\angle(z_d-z_c)-\angle(z_d-p_c)=(2k+1)\pi
$$

Define:

$$
\Delta=\pi-\angle\left(G_z(z_d)\right)
$$

Then:

$$
	heta_p=\angle(z_d-z_c)-\Delta
$$

For real $p_c$, use:

$$
p_c=a-\frac{b}{\tan(\theta_p)}
$$

This replaces grid search.

### 2.3 Magnitude condition (analytic gain)

$$
K_c=\frac{1}{\left|G_z(z_d)\frac{z_d-z_c}{z_d-p_c}\right|}
$$

### 2.4 Difference-equation coefficients

$$
b_0=K_c,\quad b_1=-K_cz_c,\quad a_1=p_c
$$

Difference equation:

$$
u[k]=a_1u[k-1]+b_0e[k]+b_1e[k-1]
$$

## 3. Simplified Workflow (No Penalties, No Grid)

### 3.1 Inputs

Required:
- discrete plant $G_z$
- sample time $T$
- requirements object: Mp and either $t_p$ or $t_s$

### 3.2 Build target pole

1. Compute $\zeta$, $\omega_n$, $s_d$, $z_d$.
2. Store $z_d$ for LGR overlay and report.

### 3.3 Choose one controller location directly

Pick one practical value (simple manual choice):
- e.g. $z_c$ near 1 for mild compensation

No sweep.

### 3.4 Solve the other location analytically

Use the angle equation from Section 2.2 to compute $p_c$.

Then enforce basic constraints:
- finite values
- $|z_c|<1$, $|p_c|<1$

### 3.5 Compute gain analytically

Use Section 2.3 and build $G_c(z)$.

### 3.6 Validate by simulation (hard checks only)

Evaluate:
- Mp
- tp (N/A if monotonic)
- ts (if required)
- $u_{max}$ and saturation indicators

No weighted score. No penalty tuning.

If hard checks fail:
- adjust chosen $z_c$ manually
- recompute $p_c$ and $K_c$ analytically

## 4. Interpretation Rules

- If response is monotonic: set $Mp=0$ and $tp=\text{N/A}$.
- Do not report end-of-window time as peak time.
- If computed pair is lag-like, keep it if performance is acceptable.

## 5. Reporting Requirements

For each run, record:
- $K_{plant},\tau,T$
- $z_d$
- $z_c,p_c,K_c$
- structure tag: lead-like or lag-like
- Mp, tp (or N/A), ts
- effort/saturation metrics
- root-locus overlay verdict at $z_d$

## 6. Practical Notes

- This approach is intentionally simple and analytic.
- It avoids numerical search behavior that previously caused empty solution sets.
- It is easier to explain, debug, and reproduce by hand.

## 7. Quick Checklist

1. Compute $z_d$ from specs.
2. Choose $z_c$ manually.
3. Solve $p_c$ by angle condition.
4. Compute $K_c$ by magnitude condition.
5. Simulate and apply hard checks.
6. If needed, retune $z_c$ and repeat analytically.
7. Report structure and metrics transparently.
