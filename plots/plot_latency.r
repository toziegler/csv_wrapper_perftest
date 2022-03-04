library(ggplot2)
library(sqldf)
library(directlabels)
library(forcats)
library(ggrepel)
library("wesanderson")
library(ggthemes)
library(readr)
library(dplyr)
library(ggrepel)
options(scipen=999)


## theme =c("#00A08A", "#F98400", "#5BBCD6")


theme =c("#7FA0C1", "#A2BE8A", "#B48CAD")

## ud_theme =c("#CBDAFC", "#F1B670")
ud_theme =c("#7FA0C1", "#176582")

df_srd_ud = read.csv("../csv/EFA_lat_UD_SRD_benchmark.csv", header=TRUE, sep=",", row.names=NULL)

df_srd_ud[df_srd_ud$protocol=="UD","desc"] <- "UD (EFA)"
df_srd_ud[df_srd_ud$protocol=="SRD","desc"] <- "SRD (EFA)"


ggplot(df_srd_ud,aes(x=bytes, y=avg, color=desc)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = ud_theme) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size (log)") +
    ylab(expression(paste("latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))
          
          ## legend.margin=margin(0,1,0,0),
          ## legend.box.margin=margin(-8,-10,-10,-10))

ggsave("latency_srd_ud.pdf",width=8, height=3, device=cairo_pdf)


df_ib = read.csv("../csv/IB_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_ib$fabric="IB"

df_efa = read.csv("../csv/EFA_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_efa$fabric="EFA"

df_tcp = read.csv("../csv/TCP_lat_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_tcp$fabric="TCP"

df = rbind(df_efa, df_ib)

df = rbind(df, df_tcp)
# add tcp/ip numbers here

df_lat_avg = sqldf("
SELECT AVG(avg) as avg, device, protocol, bytes, fabric
from df
where
experiment not like '%inline%' AND bytes >= 16 AND bytes <= 8192
GROUP BY device, protocol, bytes, fabric
")

#only repel every second row otherwise too full
df_lat_avg$label=round(df_lat_avg$avg,2)
df_lat_avg[seq(1, nrow(df_lat_avg), 2), ]$label = ""


df_lat_avg[df_lat_avg$fabric=="EFA","desc"] <- "SRD (EFA)"
df_lat_avg[df_lat_avg$fabric=="IB","desc"] <- "RC RDMA (IB)"
df_lat_avg[df_lat_avg$fabric=="TCP","desc"] <- "Sockets (TCP/IP)"

df_lat_avg$system = factor(df_lat_avg$desc, levels= c("SRD (EFA)", "RC RDMA (IB)",  "Sockets (TCP/IP)"))

# standard latency 
ggplot(df_lat_avg ,aes(x=bytes, y=avg, color=system)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(aes(shape=system),size=4, alpha=0.8) +
    geom_line(size=2) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=c(0,52)) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    geom_text_repel(aes(label = label), segment.color = 'grey50', show.legend = FALSE, size=5.5, nudge_y=1 ,segment.linetype=0) +  
    ## geom_label_repel(aes(label = paste(round(a/1e6,2) ,"M Ops","/", round(aggread/1e6,2),4"M IOs")),box.padding = 0.35, point.padding = 0.5, segment.color = 'grey50') +  
    xlab("message size") +
    ylab(expression(paste("latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

ggsave("latency_tcp_srd_ib.pdf",width=8, height=3, device=cairo_pdf)

# 99 percentile 
 ggplot(sqldf("SELECT * from df where experiment not like '%inline%' AND bytes >= 16 AND bytes <= 8192"),aes(x=bytes, y=X99percentile, color=fabric)) +
     ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size [KB]") +
    ylab(expression(paste("Latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
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
          legend.title=,
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

ggsave("inline_optimization.pdf",width=8, height=3, device=cairo_pdf)


inline_normalized = read.csv("inline.csv")
inline_normalized = sqldf("SELECT * FROM inline_normalized WHERE experiment not like '%inline%'") 

inline_normalized[inline_normalized$protocol=="SRD","fabric"] <- "SRD (EFA)"
inline_normalized[inline_normalized$protocol=="RC","fabric"] <- "RC RDMA (IB)"

inline_normalized$fabric = factor(inline_normalized$fabric, levels= c("SRD (EFA)", "RC RDMA (IB)"))

ggplot(inline_normalized
      ,aes(x=bytes, y=Normalized._Inline, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(aes(shape=fabric),size=4, alpha=0.8) +
    ## geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=0.75) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size") +
    ylab(expression(paste("norm. inline latency"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=20),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))


ggsave("inline_optimization_normalized.pdf",width=8, height=3, device=cairo_pdf)


df_hockey = read.csv("../csv/EFA_hockey_stick.csv")


df_hockey[df_hockey$fabric=="EFA","desc"] <- "SRD (EFA)"
df_hockey[df_hockey$fabric=="IB","desc"] <- "RC RDMA (IB)"

df_hockey$desc = factor(df_hockey$desc, levels= c("SRD (EFA)", "RC RDMA (IB)"))


ggplot(df_hockey
      ,aes(x=Bandwidth/1000, y=Latency, color=desc , group=interaction(desc,quantile))) +
    geom_point(aes(shape=factor(quantile)),size=4) +
    ## geom_line(size=2, alpha=0.8) +
    geom_path(size=2, alpha=0.8) +
    theme_bw() +
    ## facet_grid(desc ~ .) + 
    scale_colour_manual(values = theme) +
    expand_limits(y=0) +
    ## scale_x_continuous(labels = scales::label_bytes()) +
    xlab("generated bandwidth [GB/s]") +
    ylab(expression(paste("latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

ggsave("latency_hockey_stick.pdf",width=8, height=3, device=cairo_pdf)



df_segmentation = read.csv("../csv/EFA_segmentation_latency.csv")

df_seg = sqldf("
SELECT AVG(latency_usec) latency ,experiment_name, provider, endpoint, node_type, message_size
FROM df_segmentation
GROUP BY experiment_name, provider, endpoint, node_type, message_size
")


df_seg$library = "Libfabric EFA RDM (SRD)"

# standard latency 
ggplot(df_seg,aes(x=message_size, y=latency, color=library)) +
    ## geom_point(aes(shape=factor(q)),si>ze=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=30,x=c(12e3)) +
    geom_vline(xintercept = 8890,linetype="dashed",color="red") +
    annotate("text", x = 9500, y = 33, label = "MTU",colour="darkgrey", size=14) +
    scale_x_continuous(labels = scales::label_bytes()) +
    xlab("message size") +
    ylab(expression(paste("latency [",mu,"s]"))) +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22))
          ## legend.margin=margin(0,1,0,0))
          ## legend.box.margin=margin(-5,-5,-5,-5))

ggsave("libfabric_segmentation.pdf",width=8, height=3, device=cairo_pdf)
