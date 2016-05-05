rm(list=ls())
setwd('/Volumes/HDD/Data/BCI/figures/')

library('lme4')
library('LMERConvenienceFunctions')

# Alpha

file = '/Volumes/HDD/data/BCI/work/alldat-2000-trials_alpha.csv'
dat = read.csv(file,)

colnames(dat) = c('subject','gender','age','handedness','group','session','block','hemisphere','trial','ERD')
dat$subject = as.factor(dat$subject)
dat$gender = as.factor(dat$gender)
dat$group = as.factor(dat$group)
dat$block = as.factor(dat$block)
dat$hemisphere = as.factor(dat$hemisphere)

m = lmer(ERD~age*handedness*group*session*block*hemisphere*trial+(1|subject),data=dat)
pamer.fnc(m)
plotLMER.fnc(m,pred='session')

fname = 'Full_bothgroups_alpha.pdf'
pdf(fname,width=10,height=6)
attach(mtcars)
par(mfrow=c(2,5))
for (sno in 1:10) {
  
  plotLMER.fnc(m,pred='block',control=list('session',sno),intr=list('hemisphere',c('L','R'),'beg',list(c(1,2),c('-','.'))),ylimit=c(0,1))
  title(paste('Session ',sno,sep=''))
  
}
dev.off()


# Beta

file = '/Volumes/HDD/data/BCI/work/alldat-2000-trials_beta.csv'
dat = read.csv(file,)

colnames(dat) = c('subject','gender','age','handedness','group','session','block','hemisphere','trial','ERD')
dat$subject = as.factor(dat$subject)
dat$gender = as.factor(dat$gender)
dat$group = as.factor(dat$group)
dat$block = as.factor(dat$block)
dat$hemisphere = as.factor(dat$hemisphere)

# This loop was added to get single-subject data

for (sub in unique(dat$subject)) {
  
  temp = subset(dat,dat$subject==sub)
  
  m = lmer(ERD~session*block*hemisphere*trial+(1|trial),data=temp)
  pamer.fnc(m)
  
  ses.p = pamer.fnc(m)['session','lower.p.val']
  hemisphere.p = pamer.fnc(m)['hemisphere','lower.p.val']
  block.p = pamer.fnc(m)['block','lower.p.val']
  
  fname = paste('EEG_',sub,'_general-beta-ERD.pdf',sep='')
  pdf(fname,width=10,height=6)
  plotLMER.fnc(m,pred='session')
  string = paste('Ses: ',ses.p,'; Hemi: ',hemisphere.p,'; Block: ',block.p,sep='')
  title(string)
  dev.off()
  
  fname = paste('EEG_',sub,'_hemisphere-beta-ERD.pdf',sep='')
  pdf(fname,width=10,height=6)
  attach(mtcars)
  par(mfrow=c(2,5))
  for (sno in 1:10) {
    
    plotLMER.fnc(m,pred='block',control=list('session',sno),intr=list('hemisphere',c('L','R'),'beg',list(c(1,2),c('-','.'))),ylimit=c(0,1))
    title(paste('Session ',sno,sep=''))
    
  }
  dev.off()

}