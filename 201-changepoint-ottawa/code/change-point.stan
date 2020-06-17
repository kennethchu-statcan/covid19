data {

    int  <lower=1> M;                // number of jurisdictions
    int  <lower=1> N0;               // number of days for which to impute infections
    int  <lower=1> N2;               // days of observed data + # of days to forecast
    real <lower=0> log_max_step;     // natural logarithm of absolute value of maximum step size

    int            EpidemicStart[M];
    int  <lower=1> N[M];             // days of observed data for jurisdiction m. each entry must be <= N2
    real <lower=0> x[N2];            // index of days (starting at 1)

    int            cases[ N2,M];     // reported cases
    int            deaths[N2,M];     // reported deaths -- the rows with i > N contain -1 and should be ignored
    matrix[N2,M]   f;                // h * s
    real           SI[N2];           // fixed pre-calculated SI using emprical data from Neil

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
//  real <lower=0,upper=1> Uchg3[M];
//  real <lower=0,upper=1> Uchg4[M];

    real <lower = -log_max_step, upper = log_max_step> step1[M];
    real <lower = -log_max_step, upper = log_max_step> step2[M];
//  real <lower = -log_max_step, upper = log_max_step> step3[M];
//  real <lower = -log_max_step, upper = log_max_step> step4[M];

    real <lower=0> phi;

    }

transformed parameters {

    real convolution;

    real chgpt1[M];
    real chgpt2[M];
//  real chgpt3[M];
//  real chgpt4[M];

    matrix[N2,M] prediction = rep_matrix(0,N2,M);
    matrix[N2,M] E_deaths   = rep_matrix(0,N2,M);
    matrix[N2,M] Rt         = rep_matrix(0,N2,M);

    for (m in 1:M) {

        prediction[1:N0,m] = rep_vector(y[m],N0); // learn the number of cases in the first N0 days

        for(i in 1:EpidemicStart[m]) {
            Rt[i,m] = R0[m];
        }
        for (i in (EpidemicStart[m]+1):N2) {

            // chgpt1[m] ~ uniform(EpidemicStart[m],N2);
            // chgpt2[m] ~ uniform(chgpt1[m],       N2);
            // chgpt3[m] ~ uniform(chgpt2[m],       N2);
            // chgpt4[m] ~ uniform(chgpt3[m],       N2);

            chgpt1[m] = EpidemicStart[m] + (N2 - EpidemicStart[m]) * Uchg1[m];
            chgpt2[m] = chgpt1[m]        + (N2 - chgpt1[m]       ) * Uchg2[m];
            // chgpt3[m] = chgpt2[m]        + (N2 - chgpt2[m]       ) * Uchg3[m];
            // chgpt4[m] = chgpt3[m]        + (N2 - chgpt3[m]       ) * Uchg4[m];

            Rt[i,m] = R0[m] * exp(
                  step1[m] * int_step(i - chgpt1[m]) 
                + step2[m] * int_step(i - chgpt2[m])
            //  + step3[m] * int_step(i - chgpt3[m])
            //  + step4[m] * int_step(i - chgpt4[m])
                );
        }

        for (i in (N0+1):N2) {
            convolution = 0;
            for(j in 1:(i-1)) {
                convolution += prediction[j,m] * SI[i-j]; // Correctd 22nd March
            }
            prediction[i,m] = Rt[i,m] * convolution;
        }

        E_deaths[1,m] = 1e-9;
        for (i in 2:N2) {
            E_deaths[i,m] = 0;
            for(j in 1:(i-1)) {
                E_deaths[i,m] += prediction[j,m] * f[i-j,m];
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
        // Uchg3[m] ~ uniform(0,1);
        // Uchg4[m] ~ uniform(0,1);
        step1[m] ~ uniform( -log_max_step , log_max_step );
        step2[m] ~ uniform( -log_max_step , log_max_step );
        // step3[m] ~ uniform( -log_max_step , log_max_step );
        // step4[m] ~ uniform( -log_max_step , log_max_step );
    }

    phi ~ normal(0,5);
    for (m in 1:M) {
        for(i in EpidemicStart[m]:N[m]) {
            deaths[i,m] ~ neg_binomial_2( E_deaths[i,m] , phi ); 
        }
    }

}

generated quantities {

    matrix[N2,M] lp0 = rep_matrix(1000,N2,M); // log-probability for LOO for the counterfactual model
    matrix[N2,M] lp1 = rep_matrix(1000,N2,M); // log-probability for LOO for the main model

    real convolution0;

    matrix[N2,M] prediction0 = rep_matrix(0,N2,M);
    matrix[N2,M] E_deaths0   = rep_matrix(0,N2,M);

    for (m in 1:M) {

        prediction0[1:N0,m] = rep_vector(y[m],N0); // learn the number of cases in the first N0 days
        for (i in (N0+1):N2) {
            convolution0 = 0;
            for(j in 1:(i-1)) {
                convolution0 += prediction0[j,m] * SI[i-j]; // Correctd 22nd March
            }
            prediction0[i,m] = R0[m] * convolution0;
        }
      
        E_deaths0[1,m]= 1e-9;
        for (i in 2:N2) {
            E_deaths0[i,m] = 0;
            for (j in 1:(i-1)) {
                E_deaths0[i,m] += prediction0[j,m] * f[i-j,m];
            }
        }

        for(i in 1:N[m]) {
            lp0[i,m] = neg_binomial_2_lpmf( deaths[i,m] | E_deaths[ i,m], phi ); 
            lp1[i,m] = neg_binomial_2_lpmf( deaths[i,m] | E_deaths0[i,m], phi ); 
        }
    }

}

