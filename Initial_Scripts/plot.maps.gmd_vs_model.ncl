;_________________________________________________________________________
; Purpose: 
;      Compare surface observations of CH4 and CO from the 
;      NOAA ESRL GMD Carbon Cycle Cooperative Global Air Sampling Network
;      with model output
;      Creates panel maps of monthly mean model data overlaid with Obs  
; 
; Modification History
;      Created on July 16, 2015, V. Naik 
;_________________________________________________________________________

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./getgmdstationinfo.ncl"



begin

; Define constants
mw_air = 28.966  ; g/mole
mw_h2o = 18.01528 ; g/mole

; Specify species which we are plotting
species = (/"ch4","co"/)
species_list = (/"Methane","Carbon Monoxide"/)
nspecies = dimsizes(species)

; Specify directories
datadir = "/net2/van/obs_data/GMD/"
workdir = "/net/van/obs_data/surface_gmd/"
station_file = workdir+"gmd_station_list.csv"

; Read stationinfo
station_info = getgmdstationinfo(station_file)
stationcode  = station_info(0,:)
stationlat   = stringtofloat(station_info(1,:))
stationlon   = stringtofloat(station_info(2,:))
stationalt   = stringtofloat(station_info(3,:))
stationname  = station_info(4,:)
country      = station_info(5,:)
nsites = dimsizes(stationcode)

; Number of data points in obs files
yyyymm = yyyymm_time(1983,2014, "integer")
ntime = dimsizes(yyyymm)
obsyears = yyyymm/100

; For plotting
mons = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
nmons = dimsizes(mons)
wkstype = "ps"

fsuff = "_surface-flask_1983_2014.nc"

do sp = 0, nspecies - 1
  xsp = species(sp)

;****************************************************
; Set up Plotting resources


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
  
; Set bin ranges
  if (xsp .eq. "co") then 
    arr = (/0.,20.,40.,60.,80, 100.,120., 140., 160., 180.,200.,250.,300.,350., 400.,450.,600.,800 /)    ; 
  else if (xsp .eq. "ch4") then
    arr = (/1560,1580,1600.,1620.,1640.,1660.,1680.,1700.,1720.,1740.,1760.,1780.,1800.,1820.,1840.,1860.,1880.,1900./)    ;
  end if
  end if
  narr = dimsizes(arr)
  num_distinct_markers = dimsizes(arr)+1        ; number of distinct markers

  lat_new = new((/nmons,num_distinct_markers,nsites/),float,-999)
  lon_new = new((/nmons,num_distinct_markers,nsites/),float,-999)
;****************************************************************************************************

; Define filenames
indir = datadir+xsp+"_flask_surface/ncdf/"
infile = indir+xsp+"_"+str_lower(stationcode)+fsuff


; Model output info
user = "van"
version    = "/awg/ulm_201505/"
experiment   = "c96L48_am4g7_fullchem_rcp85_nudged"
platform   = "/gfdl.ncrc3-intel15-prod-openmp/"

modeldir = "/archive/"+user+version+experiment+platform+"pp/tracer_level/ts/monthly/"


;experiment = "c96L48_am4g5_fullchem"
;experiment = "c96L48_am4g5r1_fullchem_bergOnly"
;modeldir = "/archive/lwh/awg/ulm_201505/"+experiment+"/gfdl.ncrc2-intel-prod-openmp/pp/tracer_level/ts/monthly/"

;if (isfilepresent(modeldir+"1yr")) then
;  moddir = modeldir+"1yr/"
;  print("Will work with 1 year timeseries files")
; else if (isfilepresent(modeldir+"5yr")) then
;  if (isfilepresent(modeldir+"5yr")) then
    moddir = modeldir+"5yr/"
    fils = systemfunc ("ls "+moddir+"tracer_level.*."+str_upper(xsp)+".nc") ; file paths
    fils_sphum = systemfunc ("ls "+moddir+"tracer_level.*.sphum.nc") ; file paths
;    system("dmget "+fils)
;    system("dmget "+fils_sphum)
    
    fin = addfiles(fils, "r")   ; note the "s" of addfile
    ListSetType(fin, "cat")
    fin_sphum = addfiles(fils_sphum,"r")
    ListSetType(fin_sphum, "cat")
    
    pfull = fin[0]->pfull
    sfclev = dimsizes(pfull) - 1
    sfcpfull = pfull(sfclev)
    delete(pfull) 
    time = fin[:]->time
    utc_date = cd_calendar(time,0)
    myear = tointeger(utc_date(:,0))
    delete(utc_date)
    model_conc = fin[:]->$str_upper(xsp)$(:,sfclev,:,:)
    model_sphum = fin_sphum[:]->sphum(:,sfclev,:,:)
    dry_model_conc = model_conc/(1-(model_sphum/(mw_h2o/mw_air)))  ; mw_h2o/mw_air = 0.622 this converts model X to per mole of dry air
    dry_model_conc!0 = "time"
    dry_model_conc!1 = "lat"
    dry_model_conc!2 = "lon"
    dry_model_conc&time = time
    dry_model_conc&lat = model_conc&lat
    dry_model_conc&lon = model_conc&lon
    delete(model_conc)
    delete(model_sphum)
    delete(time)
;else 
;  print("Need monthly timeseries files, cannot plot as pp file(s) do not exist")
;end if
;end if

; Decide the year of data needed - can change to reading all years data 
years = ispan(1981,2014,1)
nyears = dimsizes(years)

do y = 0, nyears - 1 
   year = years(y)
   print("plotting "+year)
   obsconc = new((/nsites,12/),float)
   obsconc@_FillValue = -999.9
   
do s = 0, nsites - 1
  site = str_lower(stationcode(s)) 
  if (isfilepresent(infile(s))) then
     obsin = addfile(infile(s),"r") 
     indices = ind(year.eq.obsyears)
     if (any(ismissing(indices))) then
         obsconc(s,:) = -999.9
 ;        print("No Obs data for "+site+" for "+year)
	 delete(indices) 
         continue
     else
        obsconc(s,:) = obsin->$xsp$(indices)
	delete(indices) 
     end if  
  else 
     obsconc(s,:) = -999.9
     continue  ; skip this missing file
  end if
end do  ; sites

; Count the number of sites with data for each month for this year
ct = new(12,integer)
do i = 0, 11
  ct(i) = num(.not.ismissing(obsconc(:,i)))
end do


; Model output info - use timeseries files
  mod_indices = ind(myear.eq.year)
  if (any(ismissing(mod_indices))) then
    print("No model data for "+year)
    mon_conc = -999.9
    delete(mod_indices)
    continue
  else
    mon_conc = dry_model_conc(mod_indices,:,:)
    delete(mod_indices)
  end if


mon_conc = 1.0e9 * mon_conc  ; convert to ppb
mon_conc@units = "ppb"
mon_conc@long_name = str_upper(xsp)+"@"+sprintf("%7.2f",sfcpfull)+"mb"

; plot Maps for each year 

wks = gsn_open_wks(wkstype,"./ps/gmd_vs_"+experiment+"_monmean"+xsp+"."+year)
gsn_define_colormap(wks,"StepSeq25")
  
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
  map(m) = gsn_csm_contour_map(wks,mon_conc(m,:,:),mpres)
  
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

rpanel@txString = "Monthly mean "+str_upper(xsp)+" "+year+": GMD vs. "+experiment
gsn_panel(wks,map,(/4,3/),rpanel)
frame(wks)

delete(map)
delete(obsconc)
end do  ; end year loop

system("psmerge -o./gmd_vs_"+experiment+"_monmean"+xsp+".ps ./gmd_vs_"+experiment+"_monmean"+xsp+".*.ps")
system("rm -f ./gmd_vs_"+experiment+"_monmean"+xsp+".*.ps")
delete(myear)
delete(infile)
delete(dry_model_conc)
delete(mon_conc)

end do  ; species

end

