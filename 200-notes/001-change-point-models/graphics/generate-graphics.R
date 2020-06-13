
library(boot);
library(ggplot2);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
data(coal);

year        <- floor(coal);
temp.counts <- table(year);

DF.temp <- data.frame(
    year  = as.integer(names(temp.counts)),
    count = as.integer(temp.counts)
    );

str(DF.temp);
print(DF.temp);

### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ###
FILE.output <- paste0('coal-mine-explosion-count-by-year.png');

textsize.title <- 13;
textsize.axis  <- 13;

my.ggplot <- ggplot(data = NULL) + theme_bw();
my.ggplot <- my.ggplot + theme(
    title            = element_text(size = textsize.title, face = "bold"),
    axis.title.x     = element_blank(),
    axis.title.y     = element_blank(),
    axis.text.x      = element_text(size = textsize.axis,  face = "bold"),
    axis.text.y      = element_text(size = textsize.axis,  face = "bold"),
    panel.grid.major = element_line(colour="gray", linetype=2, size=0.25),
    panel.grid.minor = element_line(colour="gray", linetype=2, size=0.25),
    legend.title     = element_text(size = textsize.axis,  face = "bold")
    );

my.ggplot <- my.ggplot + geom_col(
    data    = DF.temp,
    mapping = aes(x = year, y = count),
    size    = 0.1,
    alpha   = 0.4
    );


my.years  <- seq(1840,1980,20);
my.ggplot <- my.ggplot + scale_x_continuous(limits=range(my.years),breaks=my.years);

ggsave(
    file   = FILE.output,
    plot   = my.ggplot,
    dpi    = 300,
    height = 2,
    width  = 8,
    units  = 'in'
    );

