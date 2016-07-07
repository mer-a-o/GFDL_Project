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
;datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ch4_flask_surface/climatology_199601-200512/"

obsdir_gmd        = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ncdf/"
modeldir_conc     = "/Users/mabdioskouei/GFDL_METHANE/model_output/ch4conc/monthly_10yraverage/"
modeldir_emis     = "/Users/mabdioskouei/GFDL_METHANE/model_output/ch4emis/monthly_5yraverage/"
workdir           = "./"

station_file = workdir+"gmd_station_list.csv"

 run_mode = "conc"
;  run_mode = "emis"

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
;stationlon   = where(stationlon.lt.0, stationlon+360., stationlon)
stationstring = stationcode+","+stationname+","+sprintf("%4.1f",stationlat)+","+sprintf("%5.1f",stationlonforplot)+","+sprintf("%5.1f",stationalt)+"m"
; Subset of sites
; Consider the following sites for climatological comparison
;ssites = (/"alt","zep","sum","brw","pal","ice",    \  
;           "cba","mhd","shm","oxk","hpb","hun",    \  
;	   "uum","thd","nwr","uta","azr",     \  
;           "tap","sgp","wlg","lmp","bmw","pocn30", \  
;	   "wis","izo","mid","key","pocn25","lln",   \
;	   "ask","pocn20","mlo","kum","pocn15",   \    
;	   "gmi","rpb","pocn10","pocn05","chr","bkt",   \    
;	   "sey","pocs05","nat","asc","pocs10",        \   
;           "smo","pocs15","pocs20","nmb","pocs25",   \   
;           "eic","pocs30","cpt","cgo","bhd","crz",   \   
;	   "psa","syo","hba"/)                           

ssites = stationcode
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
res@gsnMaximize = True
res@gsnPaperOrientation = "landscape"

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
rpanel@gsnPaperOrientation = "landscape"
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
;fsuff = "_surface_climo_199601-2001512.nc"
;indir = datadir+xsp+"_flask_surface/climatology_1988_2012/"
;infile = indir+xsp+"_"+str_lower(stationcode)+fsuff

indir = datadir_climo
infile = indir+xsp+"_"+str_lower(stationcode)+fsuff

obsconc = new((/nssites,12/),float)
obsconc!0 = "station"
obsconc!1 = "time"
datacounter = new((/nssites,12/),integer)

do s = 0, nssites - 1 
  site = stationcode(site_indices(s))  
  if (isfilepresent(infile(site_indices(s)))) then 
    obsin = addfile(infile(site_indices(s)),"r")
    obsconc(s,:) = (/obsin->$xsp$/)
    datacounter(s,:) = (/obsin->counter(:)/)
  else
     print("Missing file "+infile(s))
     obsconc(s,:) = -999.99
     datacounter(s,:) = -999
     continue  ; skip this missing file
  end if
end do  
obsconc@_FillValue = -999.99   ; specifies the value of missing data
datacounter@_FillValue = -999

; Count the number of sites with data for each month for this year
ct = new(12,integer)
do i = 0, 11
  ct(i) = num(.not.ismissing(obsconc(:,i)))
end do

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
;experiment  = "test runs"

do i_mode = 0,0  ;;conc and emis mode 
    
if (i_mode.eq.0)then
  modeldir = modeldir_conc
  experiment = "test_conc"
  print ("MODE = ch4conc")
else
  modeldir = modeldir_emis
  experiment = "test_emis"
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
model_conc := fin[:]->$str_upper(xsp)$(:,sfclev,:,:)
;modelconc = 1.0e9 * modelconc  ; convert to ppb
modlon := fin[0]->lon
modlat := fin[0]->lat
modelps := fin[:]->ps

model_sphum := fin[:]->sphum(:,sfclev,:,:)

dry_model_conc = 1000000000*model_conc/(1-(model_sphum/(mw_h2o/mw_air)))  ; mw_h2o/mw_air = 0.622 this converts model X to per mole of dry air
dry_model_conc!0 = "time"
dry_model_conc!1 = "lat"
dry_model_conc!2 = "lon"
dry_model_conc&time = time
dry_model_conc&lat = model_conc&lat
dry_model_conc&lon = model_conc&lon


; Calculate comparison statistics
;**********************************
; Mean bias
;print(dim_avg(modconcatsite(station|:,time|:)) - dim_avg(climoconc(station|:,time|:)))
;print( escorc(modconcatsite(station|:,time|:),climoconc(station|:,time|:)))

;meanbias(i_mode,:) = dim_avg(modconcatsite(station|:,time|:)) - dim_avg(climoconc(station|:,time|:))
;print(" "+meanbias)

;correlation(i_mode,:) = escorc(modconcatsite(station|:,time|:),climoconc(station|:,time|:))
;print(" "+correlation)
;printVarSummary( plotvar(i_mode,:,:))
;printVarSummary (modconcatsite)

;;*******************************************
;; Plotting
;;*******************************************

plot_type = "pdf"
plot_name = xsp+"_climo_map_"+experiment
wks = gsn_open_wks (plot_type, plot_name)
gsn_define_colormap(wks,"StepSeq25")

;---Set up some map resources.
  mpres              = True
  mpres@gsnMaximize  = True             ; Maximize plot in frame.
  mpres@gsnFrame     = False            ; Don't advance the frame
  mpres@gsnDraw      = False            ; Don't advance the frame
  
  mpres@tmYLLabelFontHeightF = 0.015
  mpres@tmYLMajorOutwardLengthF = -0.00
  mpres@tmYRMajorOutwardLengthF = -0.00
  mpres@tmYLMinorOutwardLengthF = -0.00
  mpres@tmYRMinorOutwardLengthF = -0.00
  
  mpres@tmXBMajorOutwardLengthF = -0.00
  mpres@tmXBMinorOutwardLengthF = -0.00
  
  mpres@cnLinesOn = False
  mpres@cnFillOn = True
  mpres@lbLabelBarOn   = False
  mpres@cnLevelSelectionMode = "ExplicitLevels"     ; set explicit contours
  mpres@cnLineLabelsOn = False
  mpres@cnInfoLabelOn  = False
  
  mpres@mpProjection         = "Robinson"
  mpres@mpPerimOn            = True
  mpres@gsnStringFontHeightF = 0.02

  gsres               = True
  gsres@gsMarkerIndex = 16  ; Use filled dots for markers.
  mkres = True              ; for hollow markers so that each of the colored markers can have an outline
  mkres@gsMarkerIndex = 4   ; hollow dots
  mkres@gsMarkerColor    = "black"

  colors = (/0,26,24,22,21,20,19,17,16,14,12,11,9,7,6,5,4,3,2/)

  rpanel = True               ; needed for panel plots
  rpanel@gsnFrame=False       ; required for panel plots
  rpanel@gsnMaximize = True
 
  rpanel@gsnPanelLabelBar = True
  rpanel@lbLabelStride      = 2
  rpanel@pmLabelBarWidthF = 0.7
  rpanel@pmLabelBarHeightF = 0.05
  rpanel@lbLabelFontHeightF = 0.015
  rpanel@lbTitleFontHeightF = 0.015
  rpanel@lbTitleString = "ppb"
  rpanel@lbTitlePosition  = "Right"
  rpanel@lbTitleDirection = "Across"

  rpanel@lbTitleOffsetF = 0
;;----Set bin ranges
  if (xsp .eq. "co") then 
    arr = (/0.,20.,40.,60.,80, 100.,120., 140., 160., 180.,200.,250.,300.,350., 400.,450.,600.,800 /)    ; 
  else if (xsp .eq. "ch4") then
;    arr = (/1560,1580,1600.,1620.,1640.,1660.,1680.,1700.,1720.,1740.,1760.,1780.,1800.,1820.,1840.,1860.,1880.,1900./)    ;
    arr = (/1300, 1340,1380,1420,1460,1500,1540,1580,1620.,1660.,1700.,1740.,1760.,1800.,1820.,1840.,1860.,1900./)
   
    ;   arr = (/1560,1580,1600.,1620.,1640.,1660.,1680.,1700.,1720.,1740.,1760.,1780.,1800./)
  end if
  end if
  narr = dimsizes(arr)
  num_distinct_markers = dimsizes(arr)+1        ; number of distinct markers


  lat_new = new((/nmons,num_distinct_markers,nsites/),float,-999)
  lon_new = new((/nmons,num_distinct_markers,nsites/),float,-999)


  map = new(nmons, "graphic")
  mpres@cnLevels = arr
  mpres@cnFillColors = colors

;---Group the points according to which range they fall in.
do m = 0, nmons-1    ; for each month
 
 do i = 0, num_distinct_markers-1
    if (i.eq.0) then
      indexes = ind(obsconc(:,m).lt.arr(0))
    end if
    if (i.eq.num_distinct_markers-1) then
      indexes = ind(obsconc(:,m).ge.max(arr))
    end if
    if (i.gt.0.and.i.lt.num_distinct_markers-1) then       
      indexes = ind(obsconc(:,m) .ge.arr(i-1).and.obsconc(:,m).lt.arr(i))
    end if
;
; Now that we have the set of indexes whose values fall within 
; the given range, take the corresponding lat/lon values and store
; them, so later we can color this set of markers with the appropriate
; color.
;
    if (.not.any(ismissing(indexes))) then 
      npts_range = dimsizes(indexes)   ; # of points in this range.
      lat_new(m,i,0:npts_range-1) = stationlat(indexes)
      lon_new(m,i,0:npts_range-1) = stationlon(indexes)
    end if
    delete(indexes)            ; Necessary b/c "indexes" may be a different
                               ; size next time.
  end do
  mpres@gsnCenterString = mons(m)
  mpres@gsnRightString = "# sites="+ct(m)
  map(m) = gsn_csm_contour_map(wks,dry_model_conc(m,:,:),mpres)
  
;---Loop through each "bin" and attach the markers to the map.
  do i = 0, num_distinct_markers-1
    if (.not.ismissing(lat_new(m,i,0)))
      gsres@gsMarkerColor      = colors(i)
      dumstr = unique_string("marker")
      map@$dumstr$ = gsn_add_polymarker(wks,map(m),lon_new(m,i,:),lat_new(m,i,:),gsres)
      holstr = unique_string("marker")  ; for marker (black) outline
      map@$holstr$ = gsn_add_polymarker(wks,map(m),lon_new(m,i,:),lat_new(m,i,:),mkres)
    end if
  end do

end do ; month
  rpanel@txString = "Monthly mean "+str_upper(xsp)+" Climo : GMD vs. "+experiment
  gsn_panel(wks,map,(/4,3/),rpanel)
  frame(wks)

  delete(map)
  delete(obsconc)




end do ;;i_mode 
end do  ;sp

;***
end
;***

