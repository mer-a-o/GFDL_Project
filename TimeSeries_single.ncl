;_________________________________________________________________________
; Purpose: 
;      Individual TS  plots of GMD monthly average and 2 model outputs
;
; Modification History
;      Created on June-2016, MAO
;_________________________________________________________________________


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "./getgmdstationinfo.ncl"

;_________________________________________________________________________

begin

;;---Define Constants
  mw_air = 28.966  ; g/mole
  mw_h2o = 18.01528 ; g/mole
  pref = 1013.246  ; mbar  reference pressure
  tref = 288.15    ; K  reference temperature
  lapserate = 0.0065   ; K/m  lapse rate
  x = 0.190284     ; R gamma/g  (dry air)

;;---Species to plot
  species = (/"ch4"/)
  species_list = (/"Methane"/)
  nspecies = dimsizes(species)

;;---Directories
;  datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/climatology_1988_2012/"
  obsdir_gmd        = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ncdf/"
  modeldir_conc     = "/Users/mabdioskouei/GFDL_METHANE/model_output/ch4conc/"
  modeldir_emis     = "/Users/mabdioskouei/GFDL_METHANE/model_output/ch4emis/"
  workdir           = "./"
  station_file      = workdir+"gmd_station_list.csv"
;  run_mode = "conc"
  run_mode = "emis"

  plot_years = ispan(2001,2005,1)

  if (run_mode.eq."conc")then
      modeldir = modeldir_conc
      print ("MODE = ch4conc")
  else
      modeldir = modeldir_emis
      print ("MODE = ch4emis")
  end if
 
;;---Read Station Info
  station_info = getgmdstationinfo(station_file)
  stationcode  = station_info(0,:)
  stationlat   = stringtofloat(station_info(1,:))
  stationlon   = stringtofloat(station_info(2,:))
  stationlonforplot = stationlon
  stationlon   = where(stationlon.lt.0, stationlon+360., stationlon)
  stationalt   = stringtofloat(station_info(3,:))
  stationname  = station_info(4,:)
  country      = station_info(5,:)
  nsites       = dimsizes(stationcode)
  stationstring = stationcode+","+stationname+","+sprintf("%4.1f",stationlat)+","+sprintf("%5.1f",stationlonforplot)+","+sprintf("%5.1f",stationalt)+"m"

;print (stationlat+","+stationlon)
;;---Subset of sites
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
   print("Number of stations to plot = "+nssites)
   site_indices = get1Dindex(stationcode,str_upper(ssites))


  do sp=0, nspecies-1
    xsp = species(sp)

;;---Read Static file
    staticfile = "/Users/mabdioskouei/GFDL_METHANE/model_output/tracer_level.static.nc"
    static = addfile(staticfile,"r")
    mod_lat = static->lat
    mod_lon = static->lon
    bk = static->bk
    pk = static->pk
    npedge = dimsizes(static->phalf)
    npfull = npedge - 1
print ("NPFULL ="+npfull) 
;;---Read Pressure file
    pressfils = systemfunc("ls "+modeldir+"tracer_level.*.ps.nc")
    pressfin = addfiles(pressfils,"r")
    ListSetType (pressfin,"cat")
    modelps = pressfin[:]->ps 
        
;;---Read model output
    simfils = systemfunc("ls "+modeldir+"tracer_level.*."+str_upper(xsp)+".nc")  ;Model output
    simfils_sphum = systemfunc("ls "+modeldir+"tracer_level*.sphum.nc") 
    simfin = addfiles(simfils, "r")   ; note the "s" of addfile
    ListSetType(simfin, "cat")
    simfin_sphum = addfiles(simfils_sphum,"r")
    ListSetType(simfin_sphum, "cat")

    model_conc := simfin[:]->$str_upper(xsp)$
    modelconc := 1.0e9 * model_conc  ; convert to ppb
    model_sphum := simfin_sphum[:]->sphum

    model_lat := simfin[0]->lat
    model_lon := simfin[0]->lon

    time = simfin[:]->time
    utc_date = cd_calendar(time,0)
    myear = tointeger(utc_date(:,0))
    delete(utc_date)

    time = simfin[:]->time
    utc_date = cd_calendar(time,0)
    myear = tointeger(utc_date(:,0))
    delete(utc_date)

    phalf = pres_hybrid_ccm(modelps,1.,pk,bk)
    pdel = dpres_hybrid_ccm(modelps,1.,pk,bk) ; kg/(ms2)
    pressure = pdel/(log(phalf(:,1:npedge-1,:,:))-log(phalf(:,0:npedge-2,:,:)))  ; equivalent to pfull (Pa)
    pressure!0 = "time"
    pressure!1 = "pfull"
    pressure!2 = "lat"
    pressure!3 = "lon"

    pressure = pressure/100.   ; convert to hPa
    model_alt = (tref/lapserate) * (1.0 - (pressure/pref)^x)  ; calculate model altitude corresponding to the pressure level
    copy_VarCoords(modelconc,model_alt)
    time = simfin[:]->time
    utc_date = cd_calendar(time,0)
    myear = tointeger(utc_date(:,0))
    delete(utc_date)


;  Bilinear interpolation of model results at station lat and lon; need to interpolate altitude
; as well to derive vertical level at the site particularly if the stationlon is less than min(mod_lon).
; First encountered this problem when comparing against EMEP data.  
    model_conc_atsite = linint2_points_Wrap(model_lon,model_lat,modelconc,True,stationlon(site_indices),stationlat(site_indices),0)
    model_sphum_atsite = linint2_points_Wrap(model_lon,model_lat,model_sphum,True,stationlon(site_indices),stationlat(site_indices),0)
    modelaltatsite = linint2_points_Wrap(model_lon,model_lat,model_alt,True,stationlon(site_indices),stationlat(site_indices),0)
printVarSummary(modelaltatsite)
;    delete(model_conc)
;    delete(model_sphum)
;    delete(time)
printVarSummary(model_conc_atsite)



;;************************************************
;;---Read Obs data

;;---Define filenames
    fsuff = "_surface-flask_1983_2014.nc"
    obsinfile := obsdir_gmd+"ch4_"+str_lower(stationcode)+fsuff  
    years = ispan(1983,2014,1)
    nyears = dimsizes(years)
    plot_nyears = dimsizes(plot_years)

    obs_conc = new((/nyears*12,nssites/),float)     
    plot_obs_conc = new ((/plot_nyears*12,nssites/),float)
printVarSummary(plot_obs_conc)
    do s = 0, nssites-1
      site := str_lower(stationcode(s))
      if (isfilepresent(obsinfile(s))) then
        obsin := addfile(obsinfile(s),"r")
        obs_conc(:,s) = obsin->$xsp$
      else
        obs_conc(:,s) = -999.9
        continue ;skip this missing file
      end if
    end do ;s
    year_ind = get1Dindex (years,plot_years)
    yearmon_ind = ispan(min(year_ind)*12,(max(year_ind)+1)*12-1,1)
    plot_obs_conc = obs_conc(yearmon_ind,:)
;printVarSummary (plot_obs_conc)

;;************************************************
;;----Get model value at correct vertical layer
    model_conc_site_alt = new ((/nssites,dimsizes(myear)/),float)
    model_conc_site_alt!0 = "station"
    model_conc_site_alt!1 = "time"

; Find the pressure level nearest to station altitude - not using annual mean pressure as pressure 
; changes from month-to-month
print("NUM YEARS IN MODEL ="+dimsizes(myear))
    do i_time=0,dimsizes(myear)-1
        do i_st=0, nssites-1
            if(isfilepresent(obsinfile(site_indices(i_st)))) then
;print (i_time+","+i_st)
                if (stationalt(site_indices(i_st)) .lt. modelaltatsite(i_time, npfull-1,i_st)) then 
                    ilev = npfull-1
                else
                    ilev = ind_nearest_coord(stationalt(site_indices(i_st)),modelaltatsite(i_time,:,i_st),0)   ; get model altitude
                end if
                model_conc_site_alt(i_st,i_time) = (/model_conc_atsite(i_time,ilev,i_st)/(1-(model_sphum_atsite(i_time,ilev,i_st)/(mw_h2o/mw_air)))/)
            else
                model_conc_site_alt(i_st,i_time) = -999.9

            end if 
        end do ;;i_st
    end do ;;i_time
    model_conc_site_alt@_FillValue = -999.9

;---Plotting

    plot_type = "x11"
;    plot_name = xsp+"_TS_gmd_TestModel"
    plot_data = new ((/2,dimsizes(myear)/),float)  ;;(Sim,obs)
    plot_time = time
    copy_VarAtts(time,plot_time)
printVarSummary(plot_data)

    plot_name = "plots/"+run_mode+"/"+xsp+"_TS_gmd_"+stationcode(site_indices)+"_model_"+run_mode

    do ind_stn = 0, nssites-1 
      plot_data (0,:) = model_conc_site_alt (ind_stn,:)
      plot_data (1,:) = plot_obs_conc (:,ind_stn)
;print (plot_obs_conc(:,ind_stn)) 
      plot = new(nssites, graphic)
;;------Map resourses
      wks  = gsn_open_wks (plot_type,plot_name(ind_stn))
      res  = True
      res@gsnMaximize = True
      res@gsnPaperOrientation = "portrait" 
      res@gsnCenterString = stationstring(site_indices(ind_stn))
      res@gsnStringFontHeightF = 0.01

;print (stationstring(site_indices(ind_stn)))
;;-----Y Axis
      res@trYMinF  =  1350
      res@trYMaxF  =  2000
      res@tiYAxisString  = "Surface "+xsp+" (ppb)" 
      res@tiYAxisFontHeightF = 0.01  
      res@tmYLLabelFontHeightF = 0.01
      res@tmYLMajorOutwardLengthF = -0.00  ; Y axis tickmarks
      res@tmYRMajorOutwardLengthF = -0.00
      res@tmYLMinorOutwardLengthF = -0.00
      res@tmYRMinorOutwardLengthF = -0.00

;;-----For layout
      res@vpWidthF    = 0.45
      res@vpHeightF   = 0.25

;      res@xyMarkLineMode   = "MarkLines"               ; choose which have markers
      res@xyMarkLineMode   = "Lines"               ; choose which have markers

      res@xyMarkers         =  (/16,7/)                      ; choose type of marker  
      res@xyMarkerColors    = (/"black","red"/)   ; Marker color
      res@xyMarkerSizeF     = 0.005                     ; Marker size (default 0.01)
      res@xyMarkerThicknessF = 1.5
      res@xyLineThicknesses  = (/4,4/)
      res@xyLineColors      = (/"black","red"/)            
      res@xyDashPattern     = 0.
;;-----Legends
      res@pmLegendDisplayMode    = "Always"              ; turn on legend
      res@pmLegendSide           = "Bottom"                 ; Change location of  

      res@pmLegendWidthF         = 0.06                  ; Change width and
      res@pmLegendHeightF        = 0.045                  ; height of legend.
      res@lgLabelFontHeightF     = .008                   ; change font height
      res@lgPerimOn              = False                 ; no box around     restick = True
      res@xyExplicitLegendLabels = (/"ch4"+run_mode, "Obs GMD"/) 


;;-----X Axis Time Format
      restick  = True
      restick@ttmFormat = "%Y" 
;      restick@ttmNumTicks = 5
      restick@ttmMajorStride = 12  ;Number of timesteps desired between major tickmarks
      time_axis_labels (plot_time,res,restick)
      res@tmXBLabelFontHeightF  = 0.008

;      plot_single = gsn_csm_xy (wks, plot_time,plot_data,res)
      plot = gsn_csm_xy (wks, plot_time,plot_data,res)
   end do ;;ind_stn

  frame(wks)
 
  end do ;;sp
end ;;begin
