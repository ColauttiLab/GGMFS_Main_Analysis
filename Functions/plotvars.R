plotvars<-function(x,y,g="Year",Pop="Pop_Code",LogX=F,LogY=F){
  # Function to extract repeated measures and grouping variable for plotting
  # Input data must be formatted like RawDataAll.csv - each row is a population with separate columns with measurements P<PLOT#><MEASURE><POS#> e.g. P4Adult20
  xCol<-c(t(CorData[,grep(paste0("P[0-9]{1,2}",x,"[0-9]*0"),names(CorData))]))
  yCol<-c(t(CorData[,grep(paste0("P[0-9]{1,2}",y,"[0-9]*0"),names(CorData))]))
  gCol<-factor(rep(CorData[,g],each=50))
  Pop<-factor(rep(CorData[,Pop],each=50))
  
  PlotDat<-data.frame(x=xCol,y=yCol,g=gCol,Pop=Pop)
  if(LogX==T){
    PlotDat$x<-log(PlotDat$x+1)
  }
  if(LogY==T){
    PlotDat$y<-log(PlotDat$y+1)
  }
  names(PlotDat)<-c(x,y,g,"Pop_Code")
  return(PlotDat[complete.cases(PlotDat),])
}