;_________________________________________________________________________
; Purpose: 
;      Panel  TS  plots of GMD(all stations) monthly average and 2 model outputs
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

;;************************************************
;;---Read Obs data
;;************************************************

;;---Define filenames
    fsuff = "_surface-flask_1983_2014.nc"
    obsinfile := obsdir_gmd+"ch4_"+str_lower(stationcode)+fsuff  
    years = ispan(1983,2014,1)
    nyears = dimsizes(years)
    plot_nyears = dimsizes(plot_years)
    year_ind = get1Dindex (years,plot_years)
    yearmon_ind = ispan(min(year_ind)*12,(max(year_ind)+1)*12-1,1)
 
    obs_conc = new((/nyears*12,nssites/),float)     
    plot_obs_conc = new ((/plot_nyears*12,nssites/),float)
;printVarSummary(plot_obs_conc)
    avail_stations =0
    do s = 0, nssites-1
      site := str_lower(stationcode(s))
      if (isfilepresent(obsinfile(s))) then
        obsin := addfile(obsinfile(s),"r")
        obs_conc(:,s) = obsin->$xsp$
       ; print(obs_conc(:,s))
       avail_stations = avail_stations+1
      else
        obs_conc(:,s) = -999.9
;        print (stationcode(s)+" ,file  not present")
        continue ;skip this missing file
      end if
    end do ;s
    plot_obs_conc = obs_conc(yearmon_ind,:)
;printVarSummary (plot_obs_conc)
;print("# of avail stations"+avail_stations)
;print(obs_conc(yearmon_ind,2))
;;************************************************
;;---Read Static file
;;************************************************

    staticfile = "/Users/mabdioskouei/GFDL_METHANE/model_output/tracer_level.static.nc"
    static = addfile(staticfile,"r")
    mod_lat = static->lat
    mod_lon = static->lon
    bk = static->bk
    pk = static->pk
    npedge = dimsizes(static->phalf)
    npfull = npedge - 1
;print ("NPFULL ="+npfull) 
;;************************************************
;;---Read Pressure file
;;************************************************

    plot_data = new ((/3,12*plot_nyears,nssites/),float)  ;;(Sim,obs)
    do i_mode=0,1
        if (i_mode.eq.0)then
            modeldir = modeldir_conc
            print ("MODE = ch4conc")
        else
            modeldir = modeldir_emis
            print ("MODE = ch4emis")
        end if
        pressfils := systemfunc("ls "+modeldir+"tracer_level.*.ps.nc")
        pressfin := addfiles(pressfils,"r")
        ListSetType (pressfin,"cat")
        modelps := pressfin[:]->ps 
;;************************************************           
;;-----Read model output
;;************************************************
        simfils := systemfunc("ls "+modeldir+"tracer_level.*."+str_upper(xsp)+".nc")  ;Model output
        simfils_sphum := systemfunc("ls "+modeldir+"tracer_level*.sphum.nc") 
        simfin := addfiles(simfils, "r")   ; note the "s" of addfile
        ListSetType(simfin, "cat")
        simfin_sphum := addfiles(simfils_sphum,"r")
        ListSetType(simfin_sphum, "cat")

        model_conc := simfin[:]->$str_upper(xsp)$
        modelconc := 1.0e9 * model_conc  ; convert to ppb
        model_sphum := simfin_sphum[:]->sphum

        model_lat := simfin[0]->lat
        model_lon := simfin[0]->lon

        time := simfin[:]->time
        utc_date := cd_calendar(time,0)
        myear := tointeger(utc_date(:,0))
        delete(utc_date)
        year_mon_ind_model = get1Dindex(myear,plot_years)
;        year_mon_ind_model = ispan(min(year_ind_model)*12,(max(year_ind_model)+1)*12-1,1)
;print(year_ind_model)

        phalf := pres_hybrid_ccm(modelps,1.,pk,bk)
        pdel := dpres_hybrid_ccm(modelps,1.,pk,bk) ; kg/(ms2)
        pressure := pdel/(log(phalf(:,1:npedge-1,:,:))-log(phalf(:,0:npedge-2,:,:)))  ; equivalent to pfull (Pa)
        pressure!0 = "time"
        pressure!1 = "pfull"
        pressure!2 = "lat"
        pressure!3 = "lon"

        pressure := pressure/100.   ; convert to hPa
        model_alt := (tref/lapserate) * (1.0 - (pressure/pref)^x)  ; calculate model altitude corresponding to the pressure level
        copy_VarCoords(modelconc,model_alt)
        time := simfin[:]->time

        utc_date := cd_calendar(time,0)
        myear := tointeger(utc_date(:,0))
        delete(utc_date)

;  Bilinear interpolation of model results at station lat and lon; need to interpolate altitude
; as well to derive vertical level at the site particularly if the stationlon is less than min(mod_lon).
; First encountered this problem when comparing against EMEP data.  
        model_conc_atsite := linint2_points_Wrap(model_lon,model_lat,modelconc,True,stationlon(site_indices),stationlat(site_indices),0)
        model_sphum_atsite := linint2_points_Wrap(model_lon,model_lat,model_sphum,True,stationlon(site_indices),stationlat(site_indices),0)
        modelaltatsite := linint2_points_Wrap(model_lon,model_lat,model_alt,True,stationlon(site_indices),stationlat(site_indices),0)

;;************************************************
;;----Get model value at correct vertical layer
        model_conc_site_alt = new ((/nssites,dimsizes(myear)/),float)
        model_conc_site_alt!0 = "station"
        model_conc_site_alt!1 = "time"

; Find the pressure level nearest to station altitude - not using annual mean pressure as pressure 
; changes from month-to-month
    print("NUM DATAPOINTS IN MODEL ="+dimsizes(myear))
        do i_time=0,dimsizes(myear)-1
            do i_st=0, nssites-1
                if(isfilepresent(obsinfile(site_indices(i_st)))) then
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
print(year_mon_ind_model)
print("MODE ="+ i_mode+ "msx"+max(year_mon_ind_model))
        plot_data(i_mode,:,:) = transpose (model_conc_site_alt(:,min(year_mon_ind_model):max(year_mon_ind_model)+11))  ;;(stn,yr)
        delete (model_conc_site_alt)
    end do ;;i_mode
        plot_data (i_mode,:,:) =(/plot_obs_conc/)
;    asciiwrite ("data_name_test.txt",plot_data)

;;******************************************************************
;---Plotting
;;******************************************************************
    plot_type = "x11"
;    plot_name = xsp+"_TS_gmd_TestModel"
    plot_time = time(min(year_mon_ind_model):max(year_mon_ind_model)+11)

    copy_VarAtts(time,plot_time)
printVarSummary(plot_data)
    pplot = new(nssites,"graphic")
    plot_name = xsp+"_TS_all_gmd_all_model"

;-----Create legend
      lgres                    = True
      lgres@vpWidthF           = 0.15                   ; width of legend (NDC)
      lgres@vpHeightF          = 0.05                   ; height of legend (NDC)
      lgres@vpXF               = 0.01
      lgres@vpYF               = 0.05
      lgres@lgPerimOn          = False                 ; turn off perimeter
      lgres@lgMarkerIndexes    = (/7,6,16/)              ; dash indexes
      lgres@lgItemType         = "MarkLines"
      lgres@lgMarkerColors     = (/"red","green","black"/)          ; colors for legend lines
      lgres@lgLineColors       = (/"red","green","black"/)
      lgres@lgDashIndexes      = (/0., 0.,0./)
      lgres@lgOrientation      = "Vertical"
      lgres@lgLabelsOn         = "True"
      lgres@lgAutoManage       = True
      lgres@lgLabelFontHeightF = 0.01
;;-----Create legend
      rpanel = True
      rpanel@txFontHeightF = 1
      rpanel@gsnFrame = False                  ; required for panel plots
      rpanel@gsnMaximize = True
      rpanel@gsnPanelLabelBar = False
      rpanel@gsnPanelBottom = 0.02
      rpanel@gsnPanelTop = 0.95
;      res@gsnStringFontHeightF   = 0.02
      wks  = gsn_open_wks (plot_type,plot_name)      
      do ind_stn = 0, nssites-1
;         if (.not.all(ismissing(plot_data(2,:,ind_stn)))) then ;;all obs is available
;;------Map resourses
          res  = True
;          res@gsnMaximize = True
;          res@gsnPaperOrientation = "portrait" 
          res@gsnCenterString = stationstring(site_indices(ind_stn))
          res@gsnStringFontHeightF = 0.015

          res@gsnFrame  = False
          res@gsnDraw   = False
;;-----For layout
          res@vpWidthF    = 0.75
          res@vpHeightF   = 0.25
          ;res@vpXF        = 0.03
          ;res@vpYF        = 

          res@xyMarkLineMode   = "MarkLines"               ; choose which have markers
;          res@xyMarkLineMode   = "Lines"               ; choose which have markers

          res@xyMarkers         =  (/7,6,16/)                      ; choose type of marker  
          res@xyMarkerColors    = (/"red","green","black"/)   ; Marker color
          res@xyMarkerSizeF     = 0.005                     ; Marker size (default 0.01)
          res@xyMarkerThicknessF = 1.5

          res@xyDashPattern     = (/0,0,0/)
          res@xyLineThicknesses  = (/4,4,4/)
          res@xyLineColors      = (/"red","green","black"/)            
;;-----Legends
;          res@pmLegendDisplayMode    = "Always"              ; turn on legend
;          res@pmLegendSide           = "Bottom"                 ; Change location of  

;          res@pmLegendWidthF         = 0.06                  ; Change width and
;          res@pmLegendHeightF        = 0.045                  ; height of legend.
;          res@lgLabelFontHeightF     = .008                   ; change font height
;          res@lgPerimOn              = False                 ; no box around     restick = True
;          res@xyExplicitLegendLabels = (/"ch4conc","ch4emis", "Obs GMD"/) 


;;-----X Axis Time Format
          restick  = True
          restick@ttmFormat = "%Y" 
;      restick@ttmNumTicks = 5
          restick@ttmMajorStride = 12  ;Number of timesteps desired between major tickmarks
          time_axis_labels (plot_time,res,restick)
          res@tmXBLabelFontHeightF  = 0.015
;      plot_single = gsn_csm_xy (wks, plot_time,plot_data(:,:,ind_stn),res)
          pplot(ind_stn) = gsn_csm_xy (wks, plot_time,plot_data(:,:,ind_stn),res)
;        else 
;          continue
;        end if

    end do ;;ind_st

    begx = 0
    do i_p=0,nssites/3-1
        endx = begx+2
        gsn_panel(wks,pplot(begx:endx),(/3,1/),rpanel)
        gsn_legend_ndc(wks,3,(/"conc","emis","GMD"/),0.5,0.03,lgres)
        frame(wks)
        begx = endx+1
    end do ;;i_p
    gsn_panel(wks,pplot(endx+1:nssites-1),(/3,1/),rpanel)
    gsn_legend_ndc(wks,3,(/"conc","emis","GMD"/),0.5,0.03,lgres)
    frame(wks)
 
  end do ;;sp
end ;;begin
