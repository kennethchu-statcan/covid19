
getData.provincial <- function(
    DF.input = NULL
    ) {

    thisFunctionName <- "getData.provincial";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    require(lubridate);
    require(readr);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.temp <- getData.provincial_preprocess(
        DF.input = DF.input
        );

    cat("\nstr(DF.temp) -- preprocessed\n");
    print( str(DF.temp) );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output.1 <- getData.provincial_by.discretization(
        DF.input = DF.temp,
        bin.size = 1
        );

    cat("\nstr(DF.output.1)\n");
    print( str(DF.output.1)   );

    DF.output.5 <- getData.provincial_by.discretization(
        DF.input = DF.temp,
        bin.size = 5
        );

    cat("\nstr(DF.output.5)\n");
    print( str(DF.output.5)   );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    list.output <- list(
        bin.size.1 = DF.output.1,
        bin.size.5 = DF.output.5
        );

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( list.output );

    }

##################################################
getData.provincial_by.discretization <- function(
    DF.input = NULL,
    bin.size = NULL
    ) {
    
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    age.groups.to.exclude <- c(
        "0 to 14 years","15 to 64 years","65 years and over",
        "85 years and over","Average age","Total - Age"
        );

    temp.levels <- unique(DF.input[,'age.group']);
    temp.levels <- setdiff(temp.levels,age.groups.to.exclude);

    groups.of.five <- grep(
        x       = temp.levels,
        pattern = " to ",
        value   = TRUE
        );
    groups.of.five <- c(groups.of.five,"100 years and over");

    groups.of.one <- setdiff(temp.levels,groups.of.five);
    groups.of.one <- c(groups.of.one,"100 years and over");

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    if ( bin.size == 1 ) {
        retained.age.groups <- groups.of.one;
    } else if ( bin.size == 5 )  {
        retained.age.groups <- groups.of.five;
        }

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    DF.output <- DF.input[DF.input[,"age.group"] %in% retained.age.groups,];

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    return( DF.output );

    }

getData.provincial_preprocess <- function(
    DF.input = NULL
    ) {

    DF.output <- DF.input;

    colnames(DF.output) <- tolower(colnames(DF.output));

    retained.colnames <- c(
#       'census_year',
#       'geo_code..por.',
        'geo_level',
        'geo_name',
#       'gnr',
#       'data_quality_flag',
#       'alt_geo_code',
        'dim..census.year..2.',
        'dim..age..in.single.years..and.average.age..127.',
        'dim..sex..3...member.id...1...total...sex',
        'dim..sex..3...member.id...2...male',
        'dim..sex..3...member.id...3...female'
        );

    DF.output <- DF.output[,retained.colnames];
    DF.output <- DF.output[DF.output[,'geo_level'           ] ==    1,];
    DF.output <- DF.output[DF.output[,'dim..census.year..2.'] == 2016,];

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "geo_name",
        replacement = "jurisdiction"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "dim..census.year..2.",
        replacement = "census.year"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "dim..age..in.single.years..and.average.age..127.",
        replacement = "age.group"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "dim..sex..3...member.id...1...total...sex",
        replacement = "total"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "dim..sex..3...member.id...2...male",
        replacement = "male"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "dim..sex..3...member.id...3...female",
        replacement = "female"
        );

    colnames(DF.output) <- gsub(
        x           = colnames(DF.output),
        pattern     = "_",
        replacement = "."
        );

    ordered.colnames <- c(
        'census.year',
        'jurisdiction',
        'age.group',
        'total',
        'male',
        'female'
        );

    DF.output <- DF.output[,ordered.colnames];

    return( DF.output );

    }

