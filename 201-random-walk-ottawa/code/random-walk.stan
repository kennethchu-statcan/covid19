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
    real <lower=0> mu[M];       // intercept for Rt
    real           alpha[N2,M];
    real <lower=0> y[M];
    real <lower=0> kappa;
    real <lower=0> phi;
    real <lower=0> tau;
    }

transformed parameters {

    real         convolution;
    matrix[N2,M] prediction = rep_matrix(0,N2,M);
    matrix[N2,M] E_deaths   = rep_matrix(0,N2,M);
    matrix[N2,M] Rt         = rep_matrix(0,N2,M);

    for (m in 1:M) {

        prediction[1:N0,m] = rep_vector(y[m],N0); // learn the number of cases in the first N0 days

        Rt[1,m] = mu[m];
        for(i in 1:EpidemicStart[m]) {
            Rt[i,m] = mu[m];
        }
        for (i in (EpidemicStart[m]+1):N2) {
            Rt[i,m] = Rt[i-1,m] * exp(alpha[i,m]);
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

    tau ~ exponential(0.03);
    for (m in 1:M) {
        y[m] ~ exponential(1.0/tau);
    }

    kappa ~ normal(0,0.5);
    mu    ~ normal(2.4,kappa); // citation needed 

    for (m in 1:M) {
        for(i in 1:EpidemicStart[m]) {
            alpha[i,m] ~ uniform(-1e-9,1e-9);
        }
        for(i in (EpidemicStart[m]+1):N[m]) {
            alpha[i,m] ~ uniform(-0.01,0.01);
        }
        for(i in (N[m]+1):N2) {
            alpha[i,m] ~ uniform(-1e-9,1e-9);
        }
    }

    phi ~ normal(0,5);
    for (m in 1:M) {
        for(i in EpidemicStart[m]:N[m]) {
            deaths[i,m] ~ neg_binomial_2(E_deaths[i,m],phi); 
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
            prediction0[i,m] = mu[m] * convolution0;
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

