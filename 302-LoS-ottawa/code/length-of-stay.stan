
data {

    int <lower=1> n_jurisdictions;           // number of jurisdictions
    int <lower=1> n_days;                    // number of days
    int admissions[n_days,n_jurisdictions];  // reported admissions
    int discharges[n_days,n_jurisdictions];  // reported discharges -- the rows with i > N contain -1 and should be ignored

    }

parameters {

    real <lower=0> uniform_alpha[n_jurisdictions];  // shape parameter of Weibull distribution
    real <lower=0> uniform_sigma[n_jurisdictions];  // scale parameter of Weibull distribution
    real <lower=0> phi;                             // dispersion parameter of Negative Binomial

    }

transformed parameters {

    real alpha[n_jurisdictions];
    real sigma[n_jurisdictions];

    matrix[n_days,n_jurisdictions] E_discharges = rep_matrix(0,n_days,n_jurisdictions);
    matrix[n_days,n_jurisdictions] P_discharge  = rep_matrix(0,n_days,n_jurisdictions);

    for (j in 1:n_jurisdictions) {

        alpha[j] = 1 + 4 * uniform_alpha[j];
        sigma[j] = 1 + 4 * uniform_sigma[j];

        P_discharge[1,j] = weibull_cdf(1.5, alpha[j], sigma[j]);
        for(t in 2:n_days) {
            P_discharge[t,j] = weibull_cdf(t+0.5, alpha[j], sigma[j]) - weibull_cdf(t-0.5, alpha[j], sigma[j]);
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
        uniform_alpha[j] ~ uniform(0,1);
        uniform_sigma[j] ~ uniform(0,1);
        for(t in 1:n_days) {
            discharges[t,j] ~ neg_binomial_2( E_discharges[t,j] , phi );
        }
    }

}
