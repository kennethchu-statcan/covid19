
data {

    int  <lower=1> M;   // number of jurisdictions
    int  <lower=1> N0;  // number of days for which to impute infections
    int  <lower=1> N2;  // days of observed data + # of days to forecast

    real <lower=0> log_max_step_large;
    real <lower=0> log_max_step_small;
    real <lower=0> log_max_step_four;

    int minChgPt1[M];
    int maxChgPt1[M];
    int minChgPt2[M];
    int maxChgPt2[M];
    int minChgPt3[M];
    int maxChgPt3[M];
    int minChgPt4[M];
    int maxChgPt4[M];

    int            EpidemicStart[M];
    int  <lower=1> N[M];    // days of observed data for jurisdiction m. each entry must be <= N2
    real <lower=0> x[N2];   // index of days (starting at 1)

    int cases[     N2,M];   // reported cases (<= true number of infections)
    int admissions[N2,M];   // reported admissions -- the rows with i > N contain -1 and should be ignored

    matrix[N2,M]   f;       // h * s
    real           SI[N2];  // fixed pre-calculated SI using emprical data from Neil

}

transformed data {
    real delta = 1e-5;
    }

parameters {

    real <lower=0> kappa;
    real <lower=0> R0[M];  // intercept for Rt

    real <lower=0> tau;
    real <lower=0> y[M];

    real <lower=0,upper=1> Uchg1[M];
    real <lower=0,upper=1> Uchg2[M];
    real <lower=0,upper=1> Uchg3[M];
    real <lower=0,upper=1> Uchg4[M];

    real < lower = -log_max_step_large , upper = 0                  > step1[M];
    real < lower =  0                  , upper = log_max_step_small > step2[M];
    real < lower = -log_max_step_small , upper = 0                  > step3[M];
    real < lower = -log_max_step_four  , upper = log_max_step_four  > step4[M];

    real <lower=0> phi;

    }

transformed parameters {

    real convolution;

    real chgpt1[M];
    real chgpt2[M];
    real chgpt3[M];
    real chgpt4[M];

    matrix[N2,M] prediction   = rep_matrix(0,N2,M);
    matrix[N2,M] E_admissions = rep_matrix(0,N2,M);
    matrix[N2,M] Rt           = rep_matrix(0,N2,M);

    for (m in 1:M) {

        prediction[1:N0,m] = rep_vector(y[m],N0); // learn the number of cases in the first N0 days

        for(i in 1:EpidemicStart[m]) {
            Rt[i,m] = R0[m];
        }
        for (i in (EpidemicStart[m]+1):N2) {

            chgpt1[m] = minChgPt1[M] + (maxChgPt1[M] - minChgPt1[M]) * Uchg1[m];
            chgpt2[m] = minChgPt2[M] + (maxChgPt2[M] - minChgPt2[M]) * Uchg2[m];
            chgpt3[m] = minChgPt3[M] + (maxChgPt3[M] - minChgPt3[M]) * Uchg3[m];

         // chgpt4[m] = minChgPt4[M] + (N[m]         - minChgPt4[M]) * Uchg4[m];
            chgpt4[m] = minChgPt4[M] + (maxChgPt4[M] - minChgPt4[M]) * Uchg4[m];

            Rt[i,m] = R0[m] * exp(
                  step1[m] * int_step(i - chgpt1[m]) // * int_step(chgpt2[m] - i)
                + step2[m] * int_step(i - chgpt2[m]) // * int_step(chgpt3[m] - i)
                + step3[m] * int_step(i - chgpt3[m]) // * int_step(chgpt4[m] - i)
                + step4[m] * int_step(i - chgpt4[m])
                );
        }

        for (i in (N0+1):N2) {
            convolution = 0;
            for(j in 1:(i-1)) {
                convolution += prediction[j,m] * SI[i-j]; // Correctd 22nd March
            }
            prediction[i,m] = Rt[i,m] * convolution;
        }

        E_admissions[1,m] = 1e-9;
        for (i in 2:N2) {
            E_admissions[i,m] = 0;
            for(j in 1:(i-1)) {
                E_admissions[i,m] += prediction[j,m] * f[i-j,m];
            }
        }

    }

}

model {

    kappa ~ normal(0,0.5);
    R0    ~ normal(2.4,kappa); // citation needed

    tau ~ exponential(0.03);
    for (m in 1:M) {

        y[m]     ~ exponential(1.0/tau);

        Uchg1[m] ~ uniform(0,1);
        Uchg2[m] ~ uniform(0,1);
        Uchg3[m] ~ uniform(0,1);
        Uchg4[m] ~ uniform(0,1);

        step1[m] ~ uniform( -log_max_step_large , 0                  );
        step2[m] ~ uniform(  0                  , log_max_step_small );
        step3[m] ~ uniform( -log_max_step_small , 0                  );
        step4[m] ~ uniform( -log_max_step_four  , log_max_step_four  );

    }

    phi ~ normal(0,5);
    for (m in 1:M) {
        for(i in EpidemicStart[m]:N[m]) {
            admissions[i,m] ~ neg_binomial_2( E_admissions[i,m] , phi );
        }
    }

}

generated quantities {

    matrix[N2,M] lp0 = rep_matrix(1000,N2,M); // log-probability for LOO for the counterfactual model
    matrix[N2,M] lp1 = rep_matrix(1000,N2,M); // log-probability for LOO for the main model

    real convolution0;

    matrix[N2,M] prediction0   = rep_matrix(0,N2,M);
    matrix[N2,M] E_admissions0 = rep_matrix(0,N2,M);

    for (m in 1:M) {

        prediction0[1:N0,m] = rep_vector(y[m],N0); // learn the number of cases in the first N0 days
        for (i in (N0+1):N2) {
            convolution0 = 0;
            for(j in 1:(i-1)) {
                convolution0 += prediction0[j,m] * SI[i-j]; // Correctd 22nd March
            }
            prediction0[i,m] = R0[m] * convolution0;
        }

        E_admissions0[1,m]= 1e-9;
        for (i in 2:N2) {
            E_admissions0[i,m] = 0;
            for (j in 1:(i-1)) {
                E_admissions0[i,m] += prediction0[j,m] * f[i-j,m];
            }
        }

        for(i in 1:N[m]) {
            lp0[i,m] = neg_binomial_2_lpmf( admissions[i,m] | E_admissions[ i,m], phi );
            lp1[i,m] = neg_binomial_2_lpmf( admissions[i,m] | E_admissions0[i,m], phi );
        }
    }

}
