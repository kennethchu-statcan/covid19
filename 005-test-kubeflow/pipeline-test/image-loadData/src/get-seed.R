
get.seed <- function(
    input.json = 'in.json'
    ) {

    thisFunctionName <- "getSeed";
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###");
    cat(paste0("\n",thisFunctionName,"() starts.\n\n"));

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    my.system.command <- paste0('egrep "seed" ',input.json);
    temp              <- system(command = my.system.command);
    temp              <- gsub(x = temp, pattern = '(\"|A-Za-z|:)', replacement = '');
    output.seed       <- as.integer(temp);

    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
    cat(paste0("\n",thisFunctionName,"() quits."));
    cat("\n### ~~~~~~~~~~~~~~~~~~~~ ###\n");
    return( output.seed );

    }

