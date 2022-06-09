library(ggplot2)
library(sqldf)
library(directlabels)
library(forcats)
library(ggrepel)
library("wesanderson")
library(ggthemes)
library(readr)
library(dplyr)
library(gridExtra)
library(knitr)
library(unikn)  # load package
options(scipen=999)


library(RColorBrewer)
display.brewer.all(colorblindFriendly = TRUE)
                                        # theme


theme =c("#7FA0C1", "#A2BE8A", "#B48CAD")
## theme =c("#00A08A", "#F98400", "#5BBCD6")


df_ib = read.csv("../csv/IB_bw_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_ib$fabric = "IB"

df_efa = read.csv("../csv/EFA_bw_benchmark.csv", header=TRUE, sep=",", row.names=NULL)
df_efa$fabric = "EFA"

#combine them into df
df = rbind(df_efa,df_ib)

df = sqldf("
SELECT AVG (bwavg) as bwavg, AVG(msgrate) as msgrate, experiment, measurement, device, protocol, txdepth, rxdepth, cqmoderation, postlist, numberqps, inline, server, client, bytes, fabric
FROM df
GROUP BY experiment, measurement, device, protocol, txdepth, rxdepth, cqmoderation,
postlist, numberqps, inline, server, client, bytes, fabric")

df_bw_sync = sqldf("SELECT * FROM df WHERE experiment like '%bw_sync%'")

df_bw_sync[df_bw_sync$fabric=="EFA","desc"] <- "SRD (EFA)"
df_bw_sync[df_bw_sync$fabric=="IB","desc"] <- "RC RDMA (IB)"
df_bw_sync$desc = factor(df_bw_sync$desc, levels= c("SRD (EFA)", "RC RDMA (IB)"))

ggplot(sqldf("SELECT * from df_bw_sync WHERE bytes <= 8192"),aes(x=bytes, y=bwavg/1e3, color=desc)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(aes(shape=desc),size=4, alpha=0.8) +
    ## geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    scale_colour_manual(values = theme) +
    expand_limits(y=0) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    xlab("message size") +
    ylab("bandwidth [GB/s]") +
    theme(legend.position = c(0.2, 0.8),
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))


ggsave("sync_bw.pdf",width=8, height=3, device=cairo_pdf)


df_bw_tx_depth = sqldf(
"SELECT *
FROM df
WHERE experiment like '%bw_tx_cq_grid%'
AND txdepth <= 4096
AND (bytes=16
or bytes=512
or bytes=4096
or bytes=8192)
")

df_bw_tx_depth[df_bw_tx_depth$fabric=="EFA","desc"] <- "SRD (EFA)"
df_bw_tx_depth[df_bw_tx_depth$fabric=="IB","desc"] <- "RC RDMA (IB)"
df_bw_tx_depth$desc = factor(df_bw_tx_depth$desc, levels= c("SRD (EFA)", "RC RDMA (IB)"))

                                        # New facet label names for supp variable
# New facet label names for dose variable
df_bw_tx_depth.labs <- c("16 B", "512 B", "4 KB", "8 KB")
names(df_bw_tx_depth.labs) <- c("16", "512", "4096","8192")

# number of batches 
p_bw = ggplot(sqldf("SELECT * FROM df_bw_tx_depth WHERE cqmoderation=1 and bytes <=8192"),aes(x=txdepth, y=bwavg/1e3, color=desc)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(aes(shape=desc),size=4, alpha=0.8) +
    ## geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ bytes,
               labeller = labeller (bytes=df_bw_tx_depth.labs)
               ) +
    scale_colour_manual(values = theme) +
    ## scale_x_continuous(trans="log2") +
    scale_x_continuous(trans="log2",breaks=c(8,128,2048), labels = c("8","128","2k")) +
    expand_limits(y=0) +
    ## xlab("tx depth [log]") +
    ylab("bandwidth [GB/s]") +
    theme(legend.position = c(0.15, 0.8),
          legend.title=element_blank(),
          text=element_text(size=20),
          ## legend.margin=margin(0,1,0,0),
          axis.title.x=element_blank(),
          axis.text.x = element_text(size = 16))
          ## legend.box.margin=margin(-5,-5,-5,-5))

p_bw

ggsave("tx_depth_bw.pdf",width=8, height=3, device=cairo_pdf)

                                        # number of batches 
p_msgr = ggplot(sqldf("SELECT * FROM df_bw_tx_depth WHERE cqmoderation=1 and bytes <=8192"),aes(x=txdepth, y=msgrate*1e6, color=desc)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(aes(shape=desc),size=4, alpha=0.8) +
    ## geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ bytes,
               labeller = labeller (bytes=df_bw_tx_depth.labs)
               ) +
    scale_colour_manual(values = theme) +
    ## scale_x_continuous(trans="log2") +
    scale_x_continuous(trans="log2",breaks=c(8,128,2048), labels = c("8","128","2k")) +
    scale_y_continuous(labels = scales::label_number_si()) +
    expand_limits(y=0) +
    xlab("outstanding requests [log]") +
    ylab("msg. rate [msg/s]") +
    theme(legend.position="none",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          axis.text.x = element_text(size = 16),
          legend.box.margin=margin(-5,-5,-5,-5))

p_msgr

ggsave("tx_depth_msgrate.pdf",width=8, height=3, device=cairo_pdf)


library(gtable)
library(grid) # for unit.pmax()
library(gridExtra)

g2 <- ggplotGrob(p_bw)
g3 <- ggplotGrob(p_msgr)
g <- rbind(g2, g3, size = "first")
g$widths <- unit.pmax(g2$widths, g3$widths)
grid.newpage()
grid.draw(g)

ggsave("tx_depth_grid.pdf",g,width=8, height=6, device=cairo_pdf)

# cq moderation msg rate 
ggplot(sqldf("SELECT * FROM df_bw_tx_depth WHERE txdepth=32 AND bytes=512" ),aes(x=cqmoderation, y=msgrate, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( txdepth ~ bytes) +
    scale_colour_manual(values = theme) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("cq moderation") +
    ylab("msgrate [M]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))
ggsave("cq_moderation_msgrate.pdf",width=8, height=3, device=cairo_pdf)

# cq moderation bw
ggplot(df_bw_tx_depth,aes(x=cqmoderation, y=bwavg, color=fabric)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( txdepth ~ bytes) +
    scale_colour_manual(values = theme) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("cq moderation") +
    ylab("bandwidth [MB/s]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))


df_qps = sqldf("SELECT * FROM df where experiment like '%bw_qps%'")


df_qps[df_qps$fabric=="EFA","desc"] <- "SRD (EFA)"
df_qps[df_qps$fabric=="IB","desc"] <- "RC RDMA (IB)"
df_qps$desc = factor(df_qps$desc, levels= c("SRD (EFA)", "RC RDMA (IB)"))

ggplot(df_qps,aes(x=numberqps, y=bwavg, color=interaction(fabric,experiment))) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ bytes,
               labeller = labeller (bytes=df_bw_tx_depth.labs)
               ) +
    scale_colour_manual(values = theme) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("number qps") +
    ylab("bandwidth [MB/s]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

df_qps = sqldf(
"SELECT *
FROM df
WHERE experiment like '%bw_qps'
AND txdepth =256
AND (bytes=16
or bytes=512
or bytes=4096
or bytes=8192)
")


df_qps[df_qps$fabric=="EFA","desc"] <- "SRD (EFA)"
df_qps[df_qps$fabric=="IB","desc"] <- "RC RDMA (IB)"
df_qps$desc = factor(df_qps$desc, levels= c("SRD (EFA)", "RC RDMA (IB)"))

df_qps.labs <- c("16 B", "512 B", "4 KB", "8 KB")
names(df_qps.labs) <- c("16", "512", "4096","8192")

ggplot(df_qps,aes(x=numberqps, y=msgrate*1e6, color=desc)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    ## geom_point(size=4) +
    geom_point(aes(shape=desc),size=4, alpha=0.8) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ bytes,
               labeller = labeller (bytes=df_bw_tx_depth.labs)
               ) +
    scale_colour_manual(values = theme) +
    scale_x_continuous(trans="log2") +
    scale_y_continuous(labels = scales::label_number_si()) +
    expand_limits(y=0) +
    xlab("number connections (send queues)") +
    ylab("msg. rate [msg/s]") +
    theme(legend.position=c(0.8,0.8),
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))
ggsave("number_qps_msgrate.pdf",width=8, height=3, device=cairo_pdf)

#as table 

df_post = sqldf("SELECT * FROM df where experiment like '%bw_post_list%'")

ggplot(df_post,aes(x=postlist, y=msgrate, color=interaction(fabric,experiment))) +
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
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

kable(df_post, "latex", booktabs = TRUE)



     
df_mt_all = read.csv("../csv/EFA_mt_benchmark.csv")

df_mt = sqldf("
SELECT avg(tx_bw_mbps) as bw, AVG(tx_pkts_psec) as msgrate, provider, endpoint, batch_size, thread_count, message_size
FROM df_mt_all
WHERE batch_size = 100
AND (message_size = 64 OR message_size=4096)
GROUP by provider, endpoint, batch_size, thread_count, message_size
")
df_mt$fabric="EFA"


df_mt_ib = read.csv("../csv/IB_mt_benchmark.csv")

df_mt_ib = sqldf("
SELECT avg(tx_bw_mbps) as bw, AVG(tx_pkts_psec) as msgrate, provider, endpoint, batch_size, thread_count, message_size
FROM df_mt_ib
WHERE batch_size = 64
AND experiment_name like '%batch_sel_comp%'
AND (message_size = 64 OR message_size=4000)
GROUP by provider, endpoint, batch_size, thread_count, message_size
")

df_mt_ib[df_mt_ib$message_size == "4000","message_size"] <- 4096

df_mt_ib$fabric = "IB"


df_mt =rbind(df_mt,df_mt_ib)

df_mt[df_mt$fabric=="EFA","desc"] <- "SRD (EFA)"
df_mt[df_mt$fabric=="IB","desc"] <- "RC RDMA (IB)"
df_mt$desc = factor(df_mt$desc, levels= c("SRD (EFA)", "RC RDMA (IB)"))

df_mt.labs <- c("64 B", "4 KB")
names(df_mt.labs) <- c("64", "4096")

p_mt_msgr = ggplot(df_mt,aes(x=thread_count, y=msgrate, color=desc)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    ## geom_point(size=4) +
    geom_point(aes(shape=desc),size=4, alpha=0.8) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ message_size,
               labeller = labeller (message_size=df_mt.labs)
               ) +    
    scale_colour_manual(values = theme) +
    scale_y_continuous(labels = scales::label_number_si()) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("number threads") +
    ylab("msg. rate [msg/s]") +
    theme(legend.position="none",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

p_mt_msgr

ggsave("msgr_multithreaded.pdf",width=8, height=3, device=cairo_pdf)


p_mt_bw=ggplot(df_mt,aes(x=thread_count, y=bw/1e3, color=desc)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    ## geom_point(size=4) +
    geom_point(aes(shape=desc),size=4, alpha=0.8) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    facet_grid( . ~ message_size,
               labeller = labeller (message_size=df_mt.labs)
               ) +    
    scale_colour_manual(values = theme) +
    scale_x_continuous(trans="log2") +
    expand_limits(y=0) +
    xlab("number threads") +
    ylab("bandwidth [GB/s]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          axis.title.x=element_blank())
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

p_mt_bw

ggsave("bw_multithreaded.pdf",width=8, height=3, device=cairo_pdf)



library(gtable)

gmt2 <- ggplotGrob(p_mt_bw)
gmt3 <- ggplotGrob(p_mt_msgr)
gmt <- rbind(gmt2, gmt3, size = "first")
gmt$widths <- unit.pmax(gmt2$widths, gmt3$widths)
grid.newpage()
grid.draw(gmt)
ggsave("bw_multithreaded_grid.pdf",gmt,width=8, height=6, device=cairo_pdf)

                                        # libfabric



## lib_theme =c("#AE2012", "#176582", "#8e8e8e")
lib_theme =c("#D56257", "#176582", "#8e8e8e")

df_libfabric = read.csv("../csv/Libfabric_B64_overhead.csv")

df_libfabric = sqldf("
SELECT message_size as Size, avg(tx_bw_mbps) as MB, AVG(tx_pkts_psec) as MessageRate, batch_size as BatchSize
FROM df_libfabric
WHERE timestamp > 5
GROUP by provider, endpoint, batch_size, thread_count, message_size
")

df_libfabric$library="Libfabric"

                                        # ibverbs

df_ibverbs = sqldf(
"SELECT *
FROM df
WHERE experiment like '%bw_tx_cq_grid%'")

df_ibverbs = sqldf("SELECT bytes as Size, bwavg as MB, (msgrate*1e6) as MessageRate, txdepth as BatchSize FROM df_ibverbs WHERE cqmoderation=1 and bytes <=8192 and txdepth >= 64 and txdepth<=1024 and fabric like '%EFA%'")
df_ibverbs$library="perftest (ibverbs)"

df_mpi = read.csv("../csv/MPI_BW_test.csv")
df_mpi$library = "OSU MPI (Libfabric)"

df_compare  = rbind (df_libfabric, df_ibverbs)
df_compare  = rbind (df_compare, df_mpi)

df_compare = sqldf("SELECT * FROM df_compare WHERE Size > 1")

df_compare = sqldf("SELECT * FROM df_compare WHERE BatchSize=256 ")

lib_bw = ggplot(df_compare,aes(x=Size, y=MB/1e3, color=library)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    ## facet_grid(.~BatchSize) +
    scale_colour_manual(values = lib_theme) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    expand_limits(y=0) +
    xlab("message size") +
    ylab("bandwidth [GB/s]") +
    theme(legend.position="top",
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          axis.title.x=element_blank(),
          legend.box.margin=margin(-5,-5,-5,-5))

ggsave("bw_overhead_libfabric.pdf",width=8, height=3, device=cairo_pdf)


lib_mr = ggplot(df_compare,aes(x=Size, y=MessageRate/1e6, color=library)) +
    ## geom_point(aes(shape=factor(q)),size=4) +
    geom_point(size=4) +
    geom_line(size=2, alpha=0.8) +
    theme_bw() +
    ## facet_grid(.~BatchSize) +
    scale_colour_manual(values = lib_theme) +
    scale_x_continuous(labels = scales::label_bytes(), trans="log2") +
    scale_y_continuous(labels = scales::label_number_si("M",accuracy=0.1)) +
    expand_limits(y=0) +
    xlab("message size") +
    ylab("msg. rate [msg/s]") +
    theme(legend.position=c(0.2,0.3),
          legend.title=element_blank(),
          text=element_text(size=22),
          legend.margin=margin(0,1,0,0),
          legend.box.margin=margin(-5,-5,-5,-5))

ggsave("mr_overhead_libfabric.pdf",width=8, height=3, device=cairo_pdf)


glib2 <- ggplotGrob(lib_bw)
glib3 <- ggplotGrob(lib_mr)
glib <- rbind(glib2, glib3, size = "first")
glib$widths <- unit.pmax(glib2$widths, glib3$widths)
grid.newpage()
grid.draw(glib)

ggsave("lib_grid.pdf",glib,width=8, height=6, device=cairo_pdf)
