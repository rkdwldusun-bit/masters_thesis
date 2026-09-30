# Run from repository root. Presentation only; no new estimation or inference.
source('R/00_theme_thesis.R')
h <- 'chapter5_revision_20261001'
o <- file.path(h,'outputs'); out <- file.path(h,'figures_r'); tab <- file.path(h,'tables_r')
dir.create(out,showWarnings=FALSE);dir.create(tab,showWarnings=FALSE)
read <- function(f) read.csv(file.path(o,f),check.names=FALSE)
ys <- c('ln_area','ln_yield','ln_production');labs_y <- c('Area','Yield','Production')
label_y <- function(x) factor(x,levels=ys,labels=labs_y)
variant <- function(x) factor(x,levels=c('original','exclude_spring'),labels=c('Original donors','Exclude two spring series'))
save <- function(p,name,height,data) {
  # Stage files and explicitly close Cairo before publishing. Do not leave a zero-byte final PDF.
  png <- file.path(out,paste0(name,'.png'));pdf <- file.path(out,paste0(name,'.pdf'))
  ggsave(paste0(png,'.tmp.png'),p,width=8,height=height,dpi=300,bg='white')
  grDevices::cairo_pdf(paste0(pdf,'.tmp.pdf'),width=8,height=height,bg='white')
  tryCatch(print(p),finally=grDevices::dev.off())
  stopifnot(file.info(paste0(pdf,'.tmp.pdf'))$size > 100,
            file.info(paste0(png,'.tmp.png'))$size > 100)
  stopifnot(file.copy(paste0(pdf,'.tmp.pdf'),pdf,overwrite=TRUE),
            file.copy(paste0(png,'.tmp.png'),png,overwrite=TRUE))
  unlink(c(paste0(pdf,'.tmp.pdf'),paste0(png,'.tmp.png')))
  write.csv(data,file.path(out,paste0(name,'_plotdata.csv')),row.names=FALSE)
}
common <- theme_thesis()+theme(plot.title=element_blank(),strip.background=element_rect(fill='white'),legend.key.width=grid::unit(1.1,'cm'))
colors <- c('Original donors'=COL[['main']],'Exclude two spring series'=COL[['set2_2']])
d<-read('pretrend_mean_paths.csv');a<-subset(d,variant=='original');b<-subset(d,variant=='exclude_spring')
pd<-rbind(data.frame(outcome=a$outcome,x=a$pilot_event,value=a$treated,series='Treated crops'),
data.frame(outcome=a$outcome,x=a$pilot_event,value=a$donor,series='Original donors'),
data.frame(outcome=b$outcome,x=b$pilot_event,value=b$donor,series='Exclude two spring series'))
pd$outcome<-label_y(pd$outcome);pd$series<-factor(pd$series,levels=c('Treated crops','Original donors','Exclude two spring series'))
p<-ggplot(pd,aes(x,value,color=series,shape=series,linetype=series))+
geom_hline(yintercept=0,color=COL[['ref']],linewidth=.4)+geom_line(linewidth=.9)+geom_point(size=2.5)+
facet_wrap(~outcome,ncol=1,scales='free_y')+scale_x_continuous(breaks=-10:-1)+
scale_color_manual(values=c(COL[['main']],COL[['pre']],COL[['set2_2']]))+
scale_shape_manual(values=c(16,15,17))+scale_linetype_manual(values=c('solid','solid','dashed'))+
labs(x='Year relative to pilot introduction',y='Log change from final pre-pilot year',caption='Source: reconstructed KOSIS panel; frozen chapter outputs. Descriptive paths; no confidence intervals.')+common
save(p,'fig5_1_pretrends',7.4,pd)
d<-read('crop_mean_contrasts.csv');d$outcome<-label_y(d$outcome)
ord<-unique(d$crop_name[order(d$crop_order)]);d$crop_name<-factor(d$crop_name,levels=rev(ord));d$donors<-variant(d$variant)
p<-ggplot(d,aes(contrast,crop_name,color=donors,shape=donors))+
geom_vline(xintercept=0,color=COL[['ref']],linewidth=.4)+geom_point(size=2.5,position=position_dodge(width=.4))+
facet_wrap(~outcome,nrow=1)+scale_color_manual(values=colors)+scale_shape_manual(values=c(16,17))+
labs(x='Mean log contrast, event years 0–9',y=NULL,caption='Source: frozen crop-event comparisons. Point contrasts only; no crop-specific inference.')+common
save(p,'fig5_2_crop_contrasts',4.8,d)
d<-read('post_event_points.csv');d$outcome<-label_y(d$outcome);d$donors<-variant(d$variant)
p<-ggplot(d,aes(event_time,est,color=donors,shape=donors,linetype=donors))+
geom_hline(yintercept=0,color=COL[['ref']],linewidth=.4)+geom_line(linewidth=.9)+geom_point(size=2.5)+
facet_wrap(~outcome,ncol=1,scales='free_y')+scale_x_continuous(breaks=0:9)+
scale_color_manual(values=colors)+scale_shape_manual(values=c(16,17))+scale_linetype_manual(values=c('solid','dashed'))+
labs(x='Year relative to coded national expansion',y='Mean log contrast from pre-pilot reference',caption='Source: frozen crop-event comparisons. Seven treated crops at every point; no confidence intervals.')+common
save(p,'fig5_3_post_contrasts',7.2,d)
d<-subset(read('pretrend_crop_paths.csv'),variant=='original');d$outcome<-label_y(d$outcome)
w<-read('crop_weights.csv');d$crop_name<-factor(w$crop_name[match(d$crop,w$crop_id)],levels=w$crop_name)
pal<-c(COL[['main']],COL[['set2_2']],COL[['set2_3']],COL[['set2_4']],'#A6D854','#E5C494',COL[['pre']])
p<-ggplot(d,aes(pilot_event,gap,color=crop_name,linetype=crop_name))+
geom_hline(yintercept=0,color=COL[['ref']],linewidth=.4)+geom_line(linewidth=.9)+
facet_wrap(~outcome,ncol=1,scales='free_y')+scale_x_continuous(breaks=-10:-1)+scale_color_manual(values=pal)+
scale_linetype_manual(values=c('solid','dashed','dotdash','longdash','solid','dashed','dotted'))+
guides(color=guide_legend(nrow=2,byrow=TRUE),linetype=guide_legend(nrow=2,byrow=TRUE))+
labs(x='Year relative to pilot introduction',y='Crop minus donor normalized log change',caption='Source: frozen pre-pilot comparisons. All endpoints equal zero by construction; no inference.')+common
save(p,'figA5_1_crop_pretrends',7.5,d)
f<-function(x) sprintf('%.3f',x)
whole<-function(x) format(round(x),big.mark=',',scientific=FALSE,trim=TRUE)
D<-subset(read('descriptive_statistics.csv'),variant=='original' & design_outcome=='ln_area')
rows<-list();k<-0
for(j in seq_along(ys)){
 variable<-c('area_ha','yield_kg10a','production_t')[j]
 k<-k+1;rows[[k]]<-c(paste0('Panel ',LETTERS[j],'. ',c('Area (ha)','Yield (kg/10a)','Production (t)')[j]),rep('',6))
 for(g in c('Treated reference','Treated target','Donor reference','Donor target')){
  r<-D[D$variable==variable & D$group==g,];stopifnot(nrow(r)==1)
  k<-k+1;rows[[k]]<-c(g,whole(r$mean),whole(r$sd),whole(r$min),whole(r$max),as.character(r$N),as.character(r$crops))
 }
}
t<-as.data.frame(do.call(rbind,rows));names(t)<-c('Cell group','Mean','S.D.','Min.','Max.','Obs.','Crops')
write.csv(t,file.path(tab,'table5_2.csv'),row.names=FALSE,na='')
D<-read('main_diagnostics_frozen.csv');rows<-list();k<-0
for(v in c('original','exclude_spring')){
 d<-D[D$variant==v,];d<-d[match(ys,d$outcome),];stopifnot(nrow(d)==3)
 k<-k+1;rows[[k]]<-c(if(v=='original')'Panel A. Original donors' else 'Panel B. Exclude two spring series',rep('',3))
 for(r in list(c('Mean contrast',f(d$est)),c('Score SE',paste0('(',f(d$se),')')),
 c('Nominal 95% interval',paste0('[',f(d$ci_lo),', ',f(d$ci_hi),']')),
 c('Diagnostic p-value',f(d$p)),c('Treated crops',as.character(d$treated_crops)),
 c('Contributing donor series',as.character(d$contributing_controls)))){k<-k+1;rows[[k]]<-r}
}
t<-as.data.frame(do.call(rbind,rows));names(t)<-c('Measure','Area','Yield','Production')
write.csv(t,file.path(tab,'table5_3.csv'),row.names=FALSE)
writeLines(c(paste('Resolved font:',FONT),capture.output(sessionInfo())),file.path(out,'R_sessionInfo.txt'))
cat('Rendered four figures and two restructured tables from frozen CSVs. No new estimation.\n')
