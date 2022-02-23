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

df_ib = read.csv("../csv/IB_bw_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_ib$fabric = "IB"

df_efa = read.csv("../csv/EFA_bw_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_efa$fabric = "EFA"

#combine them into df
df = rbind(df_efa,df_ib)

df_bw_sync = sqldf("SELECT * FROM df WHERE experiment like '%bw_sync%'")
ggplot(df_bw_sync,aes(x=bytes, y=bwavg, color=fabric)) +
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


df_bw_tx_depth = sqldf("SELECT * FROM df WHERE experiment like '%bw_tx_cq_grid%'")


# number of batches 
ggplot(sqldf("SELECT * FROM df_bw_tx_depth WHERE cqmoderation=1"),aes(x=txdepth, y=bwavg, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ bytes) +
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

# number of batches 
ggplot(sqldf("SELECT * FROM df_bw_tx_depth WHERE cqmoderation=1"),aes(x=txdepth, y=msgrate, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ bytes) +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("tx depth") +
    ylab("msgrate [M]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))




# cq moderation msg rate 
ggplot(df_bw_tx_depth,aes(x=cqmoderation, y=msgrate, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( txdepth ~ bytes) +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("cq moderation") +
    ylab("msgrate [M]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))


# cq moderation bw
ggplot(df_bw_tx_depth,aes(x=cqmoderation, y=bwavg, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( txdepth ~ bytes) +
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


df_qps = sqldf("SELECT * FROM df where experiment like '%bw_qps%'")
ggplot(df_qps,aes(x=numberqps, y=bwavg, color=interaction(fabric,experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid(. ~ bytes) +
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


df_qps = sqldf("SELECT * FROM df where experiment like '%bw_qps%'")
ggplot(df_qps,aes(x=numberqps, y=msgrate, color=interaction(fabric,experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid(. ~ bytes) +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("number qps") +
    ylab("msgrate [M]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))



df_qps = sqldf("SELECT * FROM df where experiment like '%bw_post_list%'")
ggplot(df_qps,aes(x=postlist, y=msgrate, color=interaction(fabric,experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid(. ~ bytes) +
    scale_colour_manual(values = wes_palette("Darjeeling1")) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("post list length") +
    ylab("msgrate [M]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))
