
data {

    int <lower=1> n_jurisdictions;           // number of jurisdictions
    int <lower=1> n_days;                    // number of days
    int admissions[n_days,n_jurisdictions];  // reported admissions
    int discharges[n_days,n_jurisdictions];  // reported discharges -- the rows with i > N contain -1 and should be ignored

    }

parameters {

    real <lower=0> uniform_mu[n_jurisdictions];  // mean parameter of Gamma distribution
    real <lower=0> uniform_cv[n_jurisdictions];  // cv   parameter of Gamma distribution
    real <lower=0> phi;                          // dispersion parameter of Negative Binomial

    }

transformed parameters {

    real mu[n_jurisdictions];
    real cv[n_jurisdictions];

    real alpha[n_jurisdictions];
    real  beta[n_jurisdictions];

    matrix[n_days,n_jurisdictions] E_discharges = rep_matrix(0,n_days,n_jurisdictions);
    matrix[n_days,n_jurisdictions] P_discharge  = rep_matrix(0,n_days,n_jurisdictions);

    for (j in 1:n_jurisdictions) {

        mu[j] = 2.0 + 48.0 * uniform_mu[j];  // mu ~ Uniform(2,  50  )
        cv[j] = 0.1 +  0.8 * uniform_cv[j];  // cv ~ Uniform(0.1, 0.9)

        alpha[j] = 1 / (cv[j] * cv[j]);
         beta[j] = alpha[j] / mu[j];

        P_discharge[1,j] = gamma_cdf(1.5, alpha[j], beta[j]);
        for(t in 2:n_days) {
            P_discharge[t,j] = gamma_cdf(t+0.5, alpha[j], beta[j]) - gamma_cdf(t-0.5, alpha[j], beta[j]);
        }

        E_discharges[1,j] = 1e-9;
        for (t in 2:n_days) {
            E_discharges[t,j] = 1e-9;
            for(s in 1:(t-1)) {
                E_discharges[t,j] += admissions[s,j] * P_discharge[t-s,j];
            }
        }

    }

}

model {

    phi ~ gamma(3.0,0.5);

    for (j in 1:n_jurisdictions) {
        uniform_mu[j] ~ uniform(0,1);
        uniform_cv[j] ~ uniform(0,1);
        for(t in 1:n_days) {
            discharges[t,j] ~ neg_binomial_2( E_discharges[t,j] , phi );
        }
    }

}
