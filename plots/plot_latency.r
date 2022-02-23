library(ggplot2)
library(sqldf)
library(directlabels)
library(forcats)
library(ggrepel)
library("wesanderson")
library(ggthemes)
library(readr)
library(dplyr)
options(scipen=999)

df_ib = read.csv("../csv/IB_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
colnames(df_ib) <- c(colnames(df_ib)[-1],"x")
df_ib$x <- NULL
df_ib$fabric="IB"

df_efa = read.csv("../csv/EFA_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
colnames(df_efa) <- c(colnames(df_efa)[-1],"x")
df_efa$x <- NULL
df_efa$fabric="EFA"


df = rbind(df_efa, df_ib)

ggplot(df,aes(x=bytes, y=avg, color=interaction(fabric,experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size [KB]") +
    ylab(expression(paste("Latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))


ggplot(sqldf("SELECT * from df WHERE fabric like '%IB%'"),aes(x=bytes, y=avg, color=interaction(fabric,experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size [KB]") +
    ylab(expression(paste("Latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))
