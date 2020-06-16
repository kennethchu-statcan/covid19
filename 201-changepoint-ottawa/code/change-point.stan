data {

    int  <lower=1> M;                // number of jurisdictions
    int  <lower=1> N0;               // number of days for which to impute infections
    int  <lower=1> N2;               // days of observed data + # of days to forecast

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

    real <lower=0,upper=N2+1> chgpt1[M];
    real <lower=0,upper=N2+3> chgpt2[M];
//  real <lower=0,upper=N2+5> chgpt3[M];
//  real <lower=0,upper=N2+7> chgpt4[M];

    real alpha1[M];
    real alpha2[M];
//  real alpha3[M];
//  real alpha4[M];

    real <lower=0> phi;

    }

transformed parameters {

    real         convolution;
    matrix[N2,M] prediction = rep_matrix(0,N2,M);
    matrix[N2,M] E_deaths   = rep_matrix(0,N2,M);
    matrix[N2,M] Rt         = rep_matrix(0,N2,M);

    for (m in 1:M) {

        prediction[1:N0,m] = rep_vector(y[m],N0); // learn the number of cases in the first N0 days

        for(i in 1:EpidemicStart[m]) {
            Rt[i,m] = R0[m];
        }
        for (i in (EpidemicStart[m]+1):N2) {
            Rt[i,m] = R0[m] * exp(
                  alpha1[m] * int_step(i - chgpt1[m])
                + alpha2[m] * int_step(i - chgpt2[m])
            //  + alpha3[m] * int_step(i - chgpt3[m])
            //  + alpha4[m] * int_step(i - chgpt4[m])
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
        y[m] ~ exponential(1.0/tau);

        chgpt1[m] ~ uniform(EpidemicStart[m],N2+1);
        chgpt2[m] ~ uniform(chgpt1[m]+1,     N2+3);
        // chgpt3[m] ~ uniform(chgpt2[m]+1,     N2+5);
        // chgpt4[m] ~ uniform(chgpt3[m]+1,     N2+7);

        alpha1[m] ~ normal(0,0.1);
        alpha2[m] ~ normal(0,0.1);
        // alpha3[m] ~ normal(0,0.1);
        // alpha4[m] ~ normal(0,0.1);

        // alpha1[m] ~ uniform(-1.386294,0       );
        // alpha2[m] ~ uniform(-1.386294,1.386294);
        // alpha3[m] ~ uniform(-1.386294,0       );
        // alpha4[m] ~ uniform(-1.386294,1.386294);
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

