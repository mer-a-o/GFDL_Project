;_________________________________________________________________________
; Purpose: 
;      Compare surface observations of CH4 and CO from the 
;      NOAA ESRL GMD Carbon Cycle Cooperative Global Air Sampling Network
;      with model output
;      Creates station plots of observed climatological mean seasonal cycle  
;      against model mean seasonal cycle
;
; Modification History
;      Created on July 16, 2015, V. Naik 
;      Modified on June 2016, MAO
;_________________________________________________________________________

  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./getgmdstationinfo.ncl"


;*****
begin
;*****
; Define constants
mw_air = 28.966  ; g/mole
mw_h2o = 18.01528 ; g/mole
pref = 1013.246  ; mbar  reference pressure
tref = 288.15	 ; K  reference temperature
lapserate = 0.0065   ; K/m  lapse rate
x = 0.190284	 ; R gamma/g  (dry air)

; Specify species for we need plots
species = (/"ch4"/)
species_list = (/"Methane"/)
nspecies = dimsizes(species)

; Specify directories
;datadir = "/net2/van/obs_data/GMD/"
;workdir = "/net/van/obs_data/surface_gmd/"
datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/climatology_1988_2012/"
obsdir_gmd        = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ncdf/"
modeldir_conc     = "/Users/mabdioskouei/GFDL_METHANE/model_output/ch4conc/monthly_10yraverage/"
modeldir_emis     = "/Users/mabdioskouei/GFDL_METHANE/model_output/ch4emis/monthly_5yraverage/"
workdir           = "./"

station_file = workdir+"gmd_station_list.csv"

; run_mode = "conc"
  run_mode = "emis"

; Read stationinfo
station_info = getgmdstationinfo(station_file)
stationcode  = station_info(0,:)
stationlat   = stringtofloat(station_info(1,:))
stationlon   = stringtofloat(station_info(2,:))
stationalt   = stringtofloat(station_info(3,:))
stationname  = station_info(4,:)
country      = station_info(5,:)
nsites       = dimsizes(stationcode)
stationlonforplot = stationlon
stationlon   = where(stationlon.lt.0, stationlon+360., stationlon)
stationstring = stationcode+","+stationname+","+sprintf("%4.1f",stationlat)+","+sprintf("%5.1f",stationlonforplot)+","+sprintf("%5.1f",stationalt)+"m"

; Subset of sites
; Consider the following sites for climatological comparison
ssites = (/"alt","zep","sum","brw","pal","ice",    \  
           "cba","mhd","shm","oxk","hpb","hun",    \  
	   "uum","thd","nwr","uta","azr",     \  
           "tap","sgp","wlg","lmp","bmw","pocn30", \  
	   "wis","izo","mid","key","pocn25","lln",   \
	   "ask","pocn20","mlo","kum","pocn15",   \    
	   "gmi","rpb","pocn10","pocn05","chr","bkt",   \    
	   "sey","pocs05","nat","asc","pocs10",        \   
           "smo","pocs15","pocs20","nmb","pocs25",   \   
           "eic","pocs30","cpt","cgo","bhd","crz",   \   
	   "psa","syo","hba"/)                           
nssites = dimsizes(ssites) 
site_indices = get1Dindex(stationcode,str_upper(ssites))


; Define time variable
imons = ispan(0,11,1)
mons = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
nmons = dimsizes(mons)


do sp = 0, nspecies - 1
  xsp = species(sp)

res   = True
res@gsnDraw = False
res@gsnFrame = False

; X axis
res@trXMinF       = imons(0)
res@trXMaxF       = imons(11)
res@tmXBMode      = "Explicit"
res@tmXBValues    = imons
res@tmXBLabelsOn = True
res@tmXBLabels  = mons
res@tmXBLabelFontHeightF = 0.02
res@tmXBLabelStride  = 2
res@tmXBMajorOutwardLengthF = -0.00
res@tmXBMinorOutwardLengthF = -0.00
res@tiXAxisFontHeightF = 0.02  

; Y axis
res@tiYAxisString  = "Surface "+xsp+" (ppb)" 
res@tiYAxisFontHeightF = 0.02  
res@tmYLLabelFontHeightF = 0.02
res@tmYLMajorOutwardLengthF = -0.00  ; Y axis tickmarks
res@tmYRMajorOutwardLengthF = -0.00
res@tmYLMinorOutwardLengthF = -0.00
res@tmYRMinorOutwardLengthF = -0.00


; For layout
res@vpWidthF    = 0.45
res@vpHeightF   = 0.25

res@xyMarkLineMode   = "MarkLines"               ; choose which have markers
res@xyMarkers         =  (/7,6,16/)                      ; choose type of marker  
res@xyMarkerColors    = (/"red","green","black"/)   ; Marker color
res@xyMarkerSizeF     = 0.013                     ; Marker size (default 0.01)
res@xyMarkerThicknessF = 2.0
res@xyLineColors      = (/"red","green","black"/)            
res@xyDashPattern     = 0.

; Create legend
 lgres                    = True
 lgres@vpWidthF           = 0.15                   ; width of legend (NDC)
 lgres@vpHeightF          = 0.03                   ; height of legend (NDC)
 lgres@lgPerimOn          = False                 ; turn off perimeter
 lgres@lgMarkerIndexes    = (/7,6,16/)              ; dash indexes
 lgres@lgItemType         = "MarkLines"
 lgres@lgMarkerColors     = (/"red","green","black"/)          ; colors for legend lines
 lgres@lgLineColors       = (/"red","green","black"/)
 lgres@lgDashIndexes      = (/0., 0.,0./)
 lgres@lgOrientation      = "Vertical"
 lgres@lgLabelsOn         = "True"
 lgres@lgAutoManage       = True
 lgres@lgLabelFontHeightF = 0.1

 
rpanel = True
rpanel@txFontHeightF = 0.015
rpanel@gsnFrame = False				   ; required for panel plots
rpanel@gsnMaximize = True
rpanel@gsnPanelLabelBar = False
rpanel@gsnPanelBottom = 0.02
rpanel@gsnPanelTop = 0.95
res@gsnStringFontHeightF   = 0.02

; Setting for additional text
amres = True
amres@txFontHeightF = 0.009   
amres@txFontColor = "blue"


; Define filenames and arrays to hold obs data
fsuff = "_surface_climo_1988_2012.nc"
;indir = datadir+xsp+"_flask_surface/climatology_1988_2012/"
;infile = indir+xsp+"_"+str_lower(stationcode)+fsuff

indir = datadir_climo
infile = indir+xsp+"_"+str_lower(stationcode)+fsuff

climoconc = new((/nssites,12/),float)
climoconc!0 = "station"
climoconc!1 = "time"
datacounter = new((/nssites,12/),integer)

do s = 0, nssites - 1 
  site = stationcode(site_indices(s))  
  if (isfilepresent(infile(site_indices(s)))) then 
    obsin = addfile(infile(site_indices(s)),"r")
    climoconc(s,:) = (/obsin->$xsp$/)
    datacounter(s,:) = (/obsin->counter(:)/)
  else
     print("Missing file "+infile(s))
     climoconc(s,:) = -999.99
     datacounter(s,:) = -999
     continue  ; skip this missing file
  end if
end do  
climoconc@_FillValue = -999.99   ; specifies the value of missing data
datacounter@_FillValue = -999

;*********************************************************************
; Model data info - use climatological average files
;***************************************************
;user = "van"
;version	= "/fms/testing_20100920/"
;platform	= "/gfdl.intel-prod/"
;experiment	= "c48L48_am3p9_ox_o3s"

;user = "van"
;version    = "/awg/ulm_201505/"
;experiment   = "c96L48_am4g7_fullchem_rcp85_nudged"
;platform   = "/gfdl.ncrc3-intel15-prod-openmp/"

user = "van"
version    = "/awg/ulm_201505/"
;experiment   = "c96L48_am4g7_fullchem_lnox_rcp85"
platform   = "/gfdl.ncrc3-intel15-prod-openmp/"
experiment  = "test runs"


;user = "lwh"
;version        = "/awg/ulm_201505/"
;platform       = "/gfdl.ncrc2-intel-prod-openmp/"
;experiment     = "c96L48_am4g6_fullchem"

mode_run = "conc"
;mode_run = "emis"

plotvar = new((/3,nssites,12/),float)  ;;[conc, emis, obs]
correlation = new((/2,nssites/),float)
correlation@_FillValue = -999.
meanbias = new((/2,nssites/),float)
meanbias@_FillValue = -999.


do i_mode = 0,1  ;;conc and emis mode 
    
if (i_mode.eq.0)then
  modeldir = modeldir_conc
  print ("MODE = ch4conc")
else
  modeldir = modeldir_emis
  print ("MODE = ch4emis")
end if

;staticfile = "/archive/"+user+version+experiment+platform+"pp/tracer_level/tracer_level.static.nc"
staticfile = "/Users/mabdioskouei/GFDL_METHANE/model_output/tracer_level.static.nc"

static = addfile(staticfile,"r")
mod_lat = static->lat
mod_lon = static->lon
bk = static->bk
pk = static->pk
npedge = dimsizes(static->phalf)
npfull = npedge - 1 

;avg_freq = "30yr"
;modeldir = "/archive/"+user+version+experiment+platform+"pp/tracer_level/av/monthly_"+avg_freq+"/"


fils := systemfunc ("ls "+modeldir+"tracer_level.*.nc")
fin := addfiles(fils, "r")   ; note the "s" of addfile
ListSetType(fin, "cat")

pfull := fin[0]->pfull
sfclev := dimsizes(pfull)-1
sfcpfull := pfull(sfclev)

time := fin[:]->time
modelconc := fin[:]->$str_upper(xsp)$
;modelconc = 1.0e9 * modelconc  ; convert to ppb
modlon := fin[0]->lon
modlat := fin[0]->lat
modelps := fin[:]->ps

modelsphum := fin[:]->sphum

delete(fin)

phalf = pres_hybrid_ccm(modelps,1.,pk,bk)
pdel = dpres_hybrid_ccm(modelps,1.,pk,bk) ; kg/(ms2)
pressure = pdel/(log(phalf(:,1:npedge-1,:,:))-log(phalf(:,0:npedge-2,:,:)))  ; equivalent to pfull (Pa)
pressure!0 = "time"
pressure!1 = "pfull"
pressure!2 = "lat"
pressure!3 = "lon"

pressure = pressure/100.   ; convert to hPa
model_alt = (tref/lapserate) * (1.0 - (pressure/pref)^x)  ; calculate model altitude corresponding to the pressure level

printVarSummary(model_alt)
printVarSummary(modelconc)

copy_VarCoords(modelconc,model_alt)

; Bilinear interpolation of model results at station lat and lon; need to interpolate altitude
; as well to derive vertical level at the site particularly if the stationlon is less than min(mod_lon).
; First encountered this problem when comparing against EMEP data.  
modelconcatsite := linint2_points_Wrap(modlon,modlat,modelconc,True,stationlon(site_indices),stationlat(site_indices),0) ;;[time x pfull x stn]
modelaltatsite = linint2_points_Wrap(modlon,modlat,model_alt,True,stationlon(site_indices),stationlat(site_indices),0)
modelsphumatsite := linint2_points_Wrap(modlon,modlat,modelsphum,True,stationlon(site_indices),stationlat(site_indices),0)

;printVarSummary(modelconcatsite)

modconcatsite = new((/nssites,12/),float)


modconcatsite!0 = "station"
modconcatsite!1 = "time"
printVarSummary(modconcatsite)


; Find the pressure level nearest to station altitude - not using annual mean pressure as pressure 
; changes from month-to-month
do m = 0, 11 
  do st = 0, nssites - 2
    if (isfilepresent(infile(site_indices(st)))) then 
      if (stationalt(site_indices(st)) .lt. modelaltatsite(m, npfull-1,st)) then 
        ilev = npfull - 1 
      else 
        ilev = ind_nearest_coord(stationalt(site_indices(st)),modelaltatsite(m,:,st),0)   ; get model altitude nearest to the station altitude
      end if
;      print(" "+stationcode(site_indices(st))+" "+ilev+" ")
      if (st .eq. nsites-1) then
       print(" "+ilev +" "+ssiteid(nsites-1))
      end if
      modconcatsite(st,m) = 1000000000*(/modelconcatsite(m,ilev,st)/(1-(modelsphumatsite(m,ilev,st)/(mw_h2o/mw_air)))/)
    else
      modconcatsite(st,m) = -999.9
    end if 
  end do  ; sites
end do
modconcatsite@_FillValue = -999.9

; Calculate comparison statistics
;**********************************
; Mean bias
;print(dim_avg(modconcatsite(station|:,time|:)) - dim_avg(climoconc(station|:,time|:)))
;print( escorc(modconcatsite(station|:,time|:),climoconc(station|:,time|:)))

meanbias(i_mode,:) = dim_avg(modconcatsite(station|:,time|:)) - dim_avg(climoconc(station|:,time|:))
;print(" "+meanbias)

correlation(i_mode,:) = escorc(modconcatsite(station|:,time|:),climoconc(station|:,time|:))
;print(" "+correlation)
;printVarSummary( plotvar(i_mode,:,:))
;printVarSummary (modconcatsite)

plotvar(i_mode,:,:) = modconcatsite
end do ;;i_mode 

; Plot Obs-Model comparisons  - Seasonal cycle at individual sites (ssites)
;****************************
plot_type = "pdf"
plot_name = xsp+"_climo_gmd_"+run_mode
wks = gsn_open_wks(plot_type,plot_name)
plotvar(i_mode,:,:) = climoconc

;print(plotvar)
;print(modconcatsite)
plot = new(nssites,"graphic")
imons = ispan(0,11,1)
mons = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
nmons = dimsizes(mons)

; Settings for counter
txres               = True                     ; text mods desired
txres@txFontHeightF = 0.017                     ; font smaller. default big
txres@txJust = "CenterLeft"
txres@txFontColor = "blue"

do st = 0, nssites - 2   
  if (xsp .eq. "co") then
    res@trYMinF = 0.0
    posn = 35
    yposn = (/10,10,10,10,10,10,10,10,10,10,10,10/)
  else if (run_mode.eq."conc") 
    posn = 1650
    res@trYMinF = 1300.
    yposn_conc = (/1310,1310,1310,1310,1310,1310,1310,1310,1310,1310,1310,1310/)
  else 
    posn = 1350
    res@trYMinF = 1300.
    yposn = new (12,integer)
    yposn(:) = 1310
    yposn_conc = new (12,integer)
    yposn_conc = 1360
    yposn_emis = new (12,integer)
    yposn_emis = 1410
    
  end if 
  end if
;  res@trYMaxF = max(plotvar(:,st,:))+20.0
  res@trYMaxF = 2000 
  txres@txFontColor = "blue"
  res@gsnCenterString = stationstring(site_indices(st))
  plot(st) = gsn_csm_xy(wks,imons,plotvar(:,st,:), res)

  cttext = gsn_add_text(wks,plot(st),sprinti("%2.0i",datacounter(st,:)),imons,yposn,txres)

  txres@txFontColor = "red"
  stats_conc = "Mean bias (conc)="+sprintf("%4.1f",meanbias(0,st))+"ppb, r="+sprintf("%4.2f",correlation(0,st))
  stattext = gsn_add_text(wks,plot(st),stats_conc,0.5,yposn_conc,txres)

  txres@txFontColor = "chartreuse3"
  stats_emis = "Mean bias(emis)="+sprintf("%4.1f",meanbias(1,st))+"ppb, r="+sprintf("%4.2f",correlation(1,st))
  stattext = gsn_add_text(wks,plot(st),stats_emis,0.5,yposn_emis,txres)



end do

rpanel@txString = "1988-2012 Climo GMD vs. "+experiment

; Plot all pages
begx = 0
do f = 0, nssites/18 - 1
 endx = begx+17
 gsn_panel(wks,plot(begx:endx),(/6,3/),rpanel) 
 gsn_legend_ndc(wks,3,(/"conc","emis","GMD"/),0.2,0.03,lgres)
 gsn_text_ndc(wks,"# of years in climatology",0.5,0.01,amres) 
 frame(wks)
 begx = endx+1
end do 
gsn_panel(wks,plot(endx+1:nssites-1),(/6,3/),rpanel)
gsn_legend_ndc(wks,3,(/"conc","emis","GMD"/),0.2,0.03,lgres)
gsn_text_ndc(wks,"number of years in obs climatology",0.5,0.01,amres) 
frame(wks)

end do

;***
end
;***

