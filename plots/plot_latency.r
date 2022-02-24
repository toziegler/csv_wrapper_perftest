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

theme =c("#00A08A", "#F98400", "#5BBCD6")

df_srd_ud = read.csv("../csv/EFA_lat_UD_SRD_benchmark.csv", header=TRUE, sep=",", row.names=NULL)


ggplot(df_srd_ud,aes(x=bytes, y=avg, color=protocol)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size") +
    ylab(expression(paste("Latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22))
          
          ## legend.margin=margin(0,1,0,0),
          ## legend.box.margin=margin(-8,-10,-10,-10))

ggsave("latency_srd_ud.pdf",width=8, height=4, device=cairo_pdf)


df_ib = read.csv("../csv/IB_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_ib$fabric="IB"

df_efa = read.csv("../csv/EFA_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_efa$fabric="EFA"

df_tcp = read.csv("../csv/TCP_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_tcp$fabric="TCP"

df = rbind(df_efa, df_ib)

df = rbind(df, df_tcp)
# add tcp/ip numbers here

# standard latency 
ggplot(sqldf("SELECT * from df where experiment not like '%inline%' AND bytes >= 16 AND bytes <= 8192"),aes(x=bytes, y=avg, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size [KB]") +
    ylab(expression(paste("Latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))
ggsave("latency_tcp_srd_ib.pdf",width=8, height=4, device=cairo_pdf)

# 99 percentile 
ggplot(sqldf("SELECT * from df where experiment not like '%inline%' AND bytes >= 16 AND bytes <= 8192"),aes(x=bytes, y=X99percentile, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size [KB]") +
    ylab(expression(paste("Latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))



                                        #inline optimization - how to show normalize 

inline = sqldf("SELECT * from df WHERE bytes < 512 AND (fabric like '%EFA%' OR fabric like '%IB%')")

ggplot(inline
      ,aes(x=bytes, y=avg, color=interaction(experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid(. ~ fabric) + 
    scale_colour_manual(values = theme) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size") +
    ylab(expression(paste("Latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))

ggsave("inline_optimization.pdf",width=8, height=4, device=cairo_pdf)


inline_normalized = read.csv("inline.csv")
inline_normalized = sqldf("SELECT * FROM inline_normalized WHERE experiment not like '%inline%'") 

inline_normalized[inline_normalized$protocol=="SRD","fabric"] <- "EFA"
inline_normalized[inline_normalized$protocol=="RC","fabric"] <- "IB"


ggplot(inline_normalized
      ,aes(x=bytes, y=Normalized._Inline, color=interaction(experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid(fabric ~ .) + 
    scale_colour_manual(values = c("darkgreen")) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size") +
    ylab(expression(paste("Normalized Inline Latency"))) +
    theme(legend.position="none",
          legend.title=element_blank(),
          text=element_text(size=18),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-8,-10,-10,-10))

ggsave("inline_optimization_normalized.pdf",width=8, height=4, device=cairo_pdf)




