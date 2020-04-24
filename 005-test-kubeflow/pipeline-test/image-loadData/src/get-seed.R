
get.seed <- function(
    input.json = 'in.json'
    ) {

    thisFunctionName <- "getSeed";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###

    # output.seed <- jsonlite::read_json(input.json)[["seed"]];

    my.command  <- paste0('egrep "seed" ',input.json);
    temp.string <- system(command = my.command, intern = TRUE);
    temp.string <- gsub(x = temp.string, pattern = '(\"|[A-Za-z]|:)', replacement = '');
    output.seed <- as.integer(temp.string);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( output.seed );

    }

