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

df = read.csv("../csv/IB_bw_benchmark.csv", header=TRUE, sep=",", row.names=NULL)



df_bw_sync = sqldf("SELECT * FROM df WHERE experiment like '%bw_sync%'")
ggplot(df_bw_sync,aes(x=bytes, y=bwavg, color=experiment)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size") +
    ylab("bandwidth [MB/s]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))


df_bw_tx_depth = sqldf("SELECT * FROM df WHERE experiment like '%bw_tx_depth%'")
ggplot(df_bw_tx_depth,aes(x=txdepth, y=bwavg, color=experiment)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid(.~ bytes) +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("tx depth") +
    ylab("bandwidth [MB/s]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))






df_bw_cq_mod = sqldf("SELECT * FROM df WHERE experiment like '%bw_cq_mod%'")

ggplot(df_bw_cq_mod,aes(x=cqmoderation, y=bwavg, color=experiment)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid(.~ bytes) +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("cq moderation") +
    ylab("bandwidth [MB/s]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))




