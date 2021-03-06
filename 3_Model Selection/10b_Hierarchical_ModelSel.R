#########################
## This script performs model selection using a hierarchical approach
## Outputs R2 of best model at each level of hiearchy
## Output used by Fig1_HistoVenn.R to make histograms
#########################

#########################
## Libraries            #
#########################
library(ggplot2)
library(nlme)
library(glmulti)
#library(MuMIn)
source("Functions/theme_map.R")

#########################
## Data                 #
#########################
PCData<-read.csv("PCData.csv")
PCData$Managed<-1-apply(PCData[,c("Hand_Removal","Herbicide","Mowing","Biocontrol")],1,function(x) sum(x,na.rm=T)<1)
# Exclude missing data
MData<-PCData[complete.cases(PCData[,c("Region","PCFruits","PCTotalDens","PCRosRatio","PCPopSize","Altitude","GDD","Understory","CoverPic_Mean","Pct_Canopy_Cover","Herb","FungDmg","PctRosFung","PctAdultFung")]),]
# Can't have zero spatial distance; Add slight lat/long deviations to replicated sites
MData<-MData[!duplicated(MData[,c("Latitude","Longitude")]),]

## Automated Model selection
# Identify variables with missing data
DataPoints<-apply(PCData,2,function(x) sum(!is.na(x)))
DataPoints[DataPoints<404]
# Fungi data very low (not surprising since it wasn't sampled in first few years)
# Do separate models

####################################
###  SET-UP MODEL SELECTION      ###
####################################
RespFruits<-"log(Fruits+1)"
RespDens<-"log(TotalDens+1)"
RespRos<-"RosRatio"
RespPopSize<-"log(Pop_Size+1)"

# Custom fuction for gls with spatially autocorrelated error term
# SEE: https://vcalcagnoresearch.wordpress.com/package-glmulti/
mygls<-function(y,data,na.action){
  return(gls(model=y,data=data,
             correlation=corExp(form=~Longitude+Latitude|Region),na.action=na.action))
}  
# Function for GLM multi given predictor and response variables
ModSel<-function(RespIn=NA,PredIn=NA,Data=MData,Ex=NA){
  return(glmulti(RespIn,PredIn,data=Data,level=1,fitfunction=mygls,method="h",plotty=T,na.action=na.exclude))
}

## Data frame for recording R2 values
X<-c(1:7)*NA
R<-data.frame(Fruits=X,TotalDens=X,RosRatio=X,Pop_Size=X)
row.names(R)<-c("Range","Abiotic","Biotic","Range*Abio","Range*Bio","Abio*Bio","Range*Abio*Bio")

####################################
###  Model Selection             ###
####################################
#########################
## Range                #
#########################
## Basic Range Model
RegFruits<-gls(log(Fruits+1)~1+Region,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)
RegDens<-gls(log(TotalDens+1)~1+Region,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)
RegRos<-gls(RosRatio~1+Region,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)
RegPopSize<-gls(log(Pop_Size+1)~1+Region,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)

## Calculate R2 for Venn diagram
R["Range","Fruits"]<-cor(RegFruits$fitted,RegFruits$fitted+RegFruits$residuals)^2
R["Range","TotalDens"]<-cor(RegDens$fitted,RegDens$fitted+RegDens$residuals)^2
R["Range","RosRatio"]<-cor(RegRos$fitted,RegRos$fitted+RegRos$residuals)^2
R["Range","Pop_Size"]<-cor(RegPopSize$fitted,RegPopSize$fitted+RegPopSize$residuals)^2

#########################
## Abiotic              #
#########################
## Base climate model with spatially autocorrelated error
AbioFruits<-gls(log(Fruits+1)~1+PCFruits,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)
AbioDens<-gls(log(TotalDens+1)~1+PCTotalDens,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)
AbioRos<-gls(RosRatio~1+PCRosRatio,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)
AbioPopSize<-gls(log(Pop_Size+1)~1+PCPopSize,data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude)

## Abiotic predictors
Pred<-c("Altitude","GDD","Understory","CoverPic_Mean","Pct_Canopy_Cover")

## Model selection
AbioFruitsSel<-ModSel(RespIn=RespFruits,PredIn=c("PCFruits",Pred),Data=MData)
AbioDensSel<-ModSel(RespIn=RespDens,PredIn=c("PCTotalDens",Pred),Data=MData)
AbioRosSel<-ModSel(RespIn=RespRos,PredIn=c("PCRosRatio",Pred),Data=MData)
AbioPopSizeSel<-ModSel(RespIn=RespPopSize,PredIn=c("PCPopSize",Pred),Data=MData)

## Find 'best' gls model
AbioFruits<-gls(formula(summary(AbioFruitsSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
AbioDens<-gls(formula(summary(AbioDensSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
AbioRos<-gls(formula(summary(AbioRosSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
AbioPopSize<-gls(formula(summary(AbioPopSizeSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")

## Calculate R2 for Venn diagram
R["Abiotic","Fruits"]<-cor(AbioFruits$fitted,AbioFruits$fitted+AbioFruits$residuals)^2
R["Abiotic","TotalDens"]<-cor(AbioDens$fitted,AbioDens$fitted+AbioDens$residuals)^2
R["Abiotic","RosRatio"]<-cor(AbioRos$fitted,AbioRos$fitted+AbioRos$residuals)^2
R["Abiotic","Pop_Size"]<-cor(AbioPopSize$fitted,AbioPopSize$fitted+AbioPopSize$residuals)^2


#########################
## Biotic Effects       #
#########################
## Biotic predictors
Pred<-c("Herb","FungDmg","PctRosFung","PctAdultFung")

## Model selection
BioFruitsSel<-ModSel(RespIn=RespFruits,PredIn=c(Pred),Data=MData)
BioDensSel<-ModSel(RespIn=RespDens,PredIn=c(Pred),Data=MData)
BioRosSel<-ModSel(RespIn=RespRos,PredIn=c(Pred),Data=MData)
BioPopSizeSel<-ModSel(RespIn=RespPopSize,PredIn=c(Pred),Data=MData)

## Find 'best' gls model
BioFruits<-gls(formula(summary(BioFruitsSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
BioDens<-gls(formula(summary(BioDensSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
BioRos<-gls(formula(summary(BioRosSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
BioPopSize<-gls(formula(summary(BioPopSizeSel)$bestmodel),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")

## Calculate R2 for Venn diagram
R["Biotic","Fruits"]<-cor(BioFruits$fitted,BioFruits$fitted+BioFruits$residuals)^2
R["Biotic","TotalDens"]<-cor(BioDens$fitted,BioDens$fitted+BioDens$residuals)^2
R["Biotic","RosRatio"]<-cor(BioRos$fitted,BioRos$fitted+BioRos$residuals)^2
R["Biotic","Pop_Size"]<-cor(BioPopSize$fitted,BioPopSize$fitted+BioPopSize$residuals)^2


#########################
## Range+Abiotic        #
#########################
RegAbioFruits<-gls(formula(paste(summary(AbioFruitsSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
RegAbioDens<-gls(formula(paste(summary(AbioDensSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
RegAbioRos<-gls(formula(paste(summary(AbioRosSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
RegAbioPopSize<-gls(formula(paste(summary(AbioPopSizeSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")

## Calculate R2 for Venn diagram
R["Range*Abio","Fruits"]<-cor(RegAbioFruits$fitted,RegAbioFruits$fitted+RegAbioFruits$residuals)^2
R["Range*Abio","TotalDens"]<-cor(RegAbioDens$fitted,RegAbioDens$fitted+RegAbioDens$residuals)^2
R["Range*Abio","RosRatio"]<-cor(RegAbioRos$fitted,RegAbioRos$fitted+RegAbioRos$residuals)^2
R["Range*Abio","Pop_Size"]<-cor(RegAbioPopSize$fitted,RegAbioPopSize$fitted+RegAbioPopSize$residuals)^2


#########################
## Range+Biotic         #
#########################
RegBioFruits<-gls(formula(paste(summary(BioFruitsSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
RegBioDens<-gls(formula(paste(summary(BioDensSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
RegBioRos<-gls(formula(paste(summary(BioRosSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
RegBioPopSize<-gls(formula(paste(summary(BioPopSizeSel)$bestmodel,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")

## Calculate R2 for Venn diagram
R["Range*Bio","Fruits"]<-cor(RegBioFruits$fitted,RegBioFruits$fitted+RegBioFruits$residuals)^2
R["Range*Bio","TotalDens"]<-cor(RegBioDens$fitted,RegBioDens$fitted+RegBioDens$residuals)^2
R["Range*Bio","RosRatio"]<-cor(RegBioRos$fitted,RegBioRos$fitted+RegBioRos$residuals)^2
R["Range*Bio","Pop_Size"]<-cor(RegBioPopSize$fitted,RegBioPopSize$fitted+RegBioPopSize$residuals)^2


#########################
## Biotic+Abiotic       #
#########################
FruitsMod<-paste(summary(AbioFruitsSel)$bestmodel,gsub("log\\(Fruits \\+ 1\\) ~ 1 ","",summary(BioFruitsSel)$bestmodel))
DensMod<-paste(summary(AbioDensSel)$bestmodel,gsub("log\\(TotalDens \\+ 1\\) ~ 1 ","",summary(BioDensSel)$bestmodel))
RosMod<-paste(summary(AbioRosSel)$bestmodel,gsub("RosRatio ~ 1 ","",summary(BioRosSel)$bestmodel))
PopSizeMod<-paste(summary(AbioPopSizeSel)$bestmodel,gsub("log\\(Pop_Size \\+ 1\\) ~ 1 ","",summary(BioPopSizeSel)$bestmodel))

AbioBioFruits<-gls(formula(FruitsMod),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
AbioBioDens<-gls(formula(DensMod),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
AbioBioRos<-gls(formula(RosMod),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
AbioBioPopSize<-gls(formula(PopSizeMod),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")

## Calculate R2 for Venn diagram
R["Abio*Bio","Fruits"]<-cor(AbioBioFruits$fitted,AbioBioFruits$fitted+AbioBioFruits$residuals)^2
R["Abio*Bio","TotalDens"]<-cor(AbioBioDens$fitted,AbioBioDens$fitted+AbioBioDens$residuals)^2
R["Abio*Bio","RosRatio"]<-cor(AbioBioRos$fitted,AbioBioRos$fitted+AbioBioRos$residuals)^2
R["Abio*Bio","Pop_Size"]<-cor(AbioBioPopSize$fitted,AbioBioPopSize$fitted+AbioBioPopSize$residuals)^2


#########################
## Biotic+Abiotic+Region#
#########################
FullFruits<-gls(formula(paste(FruitsMod,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
FullDens<-gls(formula(paste(DensMod,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
FullRos<-gls(formula(paste(RosMod,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")
FullPopSize<-gls(formula(paste(PopSizeMod,"+ Region")),data=MData,correlation=corExp(form=~Longitude+Latitude|Region,nugget=T),na.action=na.exclude,method="ML")

## Calculate R2 for Venn diagram
R["Range*Abio*Bio","Fruits"]<-cor(FullFruits$fitted,FullFruits$fitted+FullFruits$residuals)^2
R["Range*Abio*Bio","TotalDens"]<-cor(FullDens$fitted,FullDens$fitted+FullDens$residuals)^2
R["Range*Abio*Bio","RosRatio"]<-cor(FullRos$fitted,FullRos$fitted+FullRos$residuals)^2
R["Range*Abio*Bio","Pop_Size"]<-cor(FullPopSize$fitted,FullPopSize$fitted+FullPopSize$residuals)^2


######################################

## Output R2 values
write.csv(R,"Model_Performance.csv")



