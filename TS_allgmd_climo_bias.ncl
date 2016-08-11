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
;datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/climatology_1988_2012/"
datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ch4_flask_surface/climatology_199601-200512/"


obsdir_gmd        = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ncdf/"
modeldir_conc = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4conc_newinitcond/"
modeldir_emis = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4emis_newinitcond/"
modeldir_emis30 = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_30percentch4emis_newinitcond/"
modeldir_emis40 = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_40percentch4emis_newinitcond/"
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


;do sp = 0, nspecies - 1
  sp = 0
  xsp = species(sp)


; Define filenames and arrays to hold obs data
;fsuff = "_surface_climo_1988_2012.nc"
fsuff = "_surface_climo_199601-200512.nc"
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
experiment  = "c96L48_am4g10_fullchem_2000climo"


;user = "lwh"
;version        = "/awg/ulm_201505/"
;platform       = "/gfdl.ncrc2-intel-prod-openmp/"
;experiment     = "c96L48_am4g6_fullchem"

mode_run = (/"conc","emis20","emis30","emis40"/)
num_mode = dimsizes(mode_run)
;mode_run = "emis"

plotvar_bias = new((/num_mode,nssites/),float)  ;;[conc, emis, obs]
plotvar_corr = new((/num_mode,nssites/),float)

correlation = new((/num_mode,nssites/),float)
correlation@_FillValue = -999.
meanbias = new((/num_mode,nssites/),float)
meanbias@_FillValue = -999.


do i_mode = 0,num_mode-1  ;;conc and emis mode 
    
if (i_mode.eq.0)then
  modeldir = modeldir_conc
  print ("MODE = ch4conc")
else if (i_mode.eq.1) then
  modeldir = modeldir_emis
  print ("MODE = ch4emis20")
else if (i_mode.eq.2) then
  modeldir = modeldir_emis30
  print ("MODE = ch4emis30")
else if (i_mode.eq.3) then
  modeldir = modeldir_emis40
    print ("MODE = ch4emis40")
end if
end if
end if
end if
;staticfile = "/archive/"+user+version+experiment+platform+"pp/tracer_level/tracer_level.static.nc"
staticfile = modeldir_emis40+"tracer_level.static.nc"

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

end do ;;i_mode 
plotvar_bias = meanbias
plotvar_corr = correlation


; Plot Obs-Model comparisons  
;****************************
plot_type = "pdf"
plot_name = "plot_TS_gmd_climo_bias_"+xsp
wks = gsn_open_wks(plot_type,plot_name)

    res                       = True

    res@gsnMaximize           = True   ; maximize size of plot in window
;    res@gsnDraw               = False  ; turn off draw
    res@gsnFrame              = False  ; turn off page advance
    res@vpWidthF    = 0.44
    res@vpHeightF   = 0.25
    res@gsnPaperOrientation = "landscape"
    res@tiMainString = "Bias  Surface CH4(GMD) , climo 1996-2005"

;;---Y Axis
;    res@trYMinF = -1000
;    res@trYMaxF = 1000
    res@tiYAxisString = "Bias-Surface CH4(ppb)"
;    res@tiYAxisString = "Correlation Coefficient"
    res@tiYAxisFontHeightF = 0.01
    res@tmYLLabelFontHeightF = 0.01

;;--- X Axis 
    res@tiXAxisString = "Lat"
    res@tiXAxisFontHeightF = 0.01
    res@tmXBLabelFontHeightF = 0.01
;;---Markers formant
    res@xyMarkLineMode   = "Markers"               ; choose which have markers
    res@xyMarkers         =  (/7,6,15,9/)                      ; choose type of marker  
    res@xyMarkerColors    = (/"red","chartreuse4","orange2","blue"/)   ; Marker color
    res@xyMarkerSizeF     = (/0.008,0.008,0.008,0.008/)                     ; Marker size (default 0.01)
    res@xyMarkerThicknessF = (/3,3,3,3/)
    ;res@xyLineColors      = (/"red","green","black"/)
    ;res@xyDashPattern     = 0.
    ;res@xyLineThicknessF  = (/3,3,3/)

    plot = gsn_csm_xy(wks,stationlat(site_indices),plotvar_bias,res)

;;---Create legend
    lgres                    = True
    lgres@vpWidthF           = 0.2                   ; width of legend (NDC)
    lgres@vpHeightF          = 0.08                   ; height of legend (NDC)
    lgres@lgPerimOn          = False                 ; turn off perimeter
    lgres@lgMarkerIndexes    = (/7,6,9,16/)              ; dash indexes
    lgres@lgItemType         = "Markers"
    lgres@lgMarkerColors     = (/"red","chartreuse4","orange2","blue"/)          ; colors for legend lines
    lgres@lgLineColors       = (/"red","chartreuse4","blue","black"/)
    lgres@lgDashIndexes      = (/0., 0.,0./)
    lgres@lgOrientation      = "Vertical"
    lgres@lgLabelsOn         = "True"
    lgres@lgAutoManage       = True
    lgres@lgLabelFontHeightF = 0.01

    gsn_legend_ndc(wks,4,(/"conc","emis20%","emis30%","emis40%"/),0.5,0.18,lgres)
    frame(wks)

;***
end
;***

