;_________________________________________________________________________
; Purpose: 
;      Plot a Time Series of data availability for all gmd stations from  1983 to 2014
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
  obsdir_gmd        = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ncdf/"
  workdir           = "./"
  station_file      = workdir+"gmd_station_list_lat.csv"

;;---Read Station Info
  station_info = getgmdstationinfo(station_file)
  stationcode  = station_info(0,:)
  stationlat   = stringtofloat(station_info(1,:))
  stationlon   = stringtofloat(station_info(2,:))
  stationlonforplot = stationlon
  stationlon   = where(stationlon.lt.0, stationlon+360., stationlon)
  stationalt   = stringtofloat(station_info(3,:))
  stationname  = station_info(4,:)  ;;in UPPERCASE
  country      = station_info(5,:)
  nsites       = dimsizes(stationcode)
  stationstring = stationcode+","+stationname+","+sprintf("%4.1f",stationlat)+","+sprintf("%5.1f",stationlonforplot)+","+sprintf("%5.1f",stationalt)+"m"
;print (stationstring)
;;---Subset of sites
  ssites = stationname ;;plotting all sites.
  nssites = dimsizes(ssites)
  print("Number of stations to plot = "+nssites)
  site_indices = get1Dindex(stationcode,str_upper(ssites))
;;***********************************
  do i_sp=0, nspecies-1
    xsp = species(i_sp) 
;-----Read Obs Data

;;---Define filenames
    fsuff = "_surface-flask_1983_2014.nc"
    obsinfile := obsdir_gmd+"ch4_"+str_lower(stationcode)+fsuff
    years = ispan(1983,2014,1)
    nyears = dimsizes(years)
    obs_conc = new((/nyears*12,nssites/),float)

    do i_st=0, nssites-1
      site := str_lower(stationcode(i_st))
      if (isfilepresent(obsinfile(i_st))) then
        obsin := addfile(obsinfile(i_st),"r")
        var :=  obsin->$xsp$
;printVarSummary (var)
        obs_conc(:,i_st) = var
        obs_time := obsin->time  ;;All are from 198301 to 201412
;        print (min(obs_time)+" to "+max(obs_time))
      else
        obs_conc(:,i_st) = -999.9
;        print(site+" data not available")
        continue ;skip this missing file
      end if
    end do ;;i_st
    obs_conc!0 = "time"
    obs_conc!1 = "station"
    site_avail_index = ind(isfilepresent(obsinfile))
    num_site_avail = dimsizes(site_avail_index)
    print("data available for "+num_site_avail+ " stations")
    plot_data = new ((/nyears*12,nssites/),integer)

printVarSummary(plot_data)
    do ii_st = 0, nssites-1
        do jj_yr = 0,nyears*12-1
            if (.not.ismissing(obs_conc(jj_yr,ii_st))) then
                plot_data (jj_yr,ii_st) = ii_st
            end if
        end do ;;jj_year
    end do ;;ii_site
;    asciiwrite("./data_availability_timeline.txt",transpose(plot_data))
;;*******************************************************
;;---Plotting
    plot_type ="x11"
    plot_name = "GMD_station_timeline"

;    plot_time = obs_time
;    plot_time@units = "YYYYMM"
;print (plot_time) 

    plot_time = ispan(1,dimsizes(obs_time),1)
    plot_time@units = "months since 1983-01-01 00:00:00"

;;---Plot Resources
    wks  =  gsn_open_wks (plot_type,plot_name)
    gsn_define_colormap(wks,"default")


    wks  =  gsn_open_wks (plot_type,plot_name)
    gsn_define_colormap(wks,"default")
    res  =  True
    res@gsnMaximize  =  True
    res@gsnPaperOrientation  =  "landscape"
    ;res@gsnDraw     = False
    ;res@gsnFrame    = False
;;---Y Axis
    res@tiYAxisFontHeightF = 0.015  
    res@tmYLLabelFontHeightF = 0.015

    res@tmYROn               = False    ; Turn on right tickmarks
    res@tmXTOn               = False   ; Turn off top tickmarks
    res@tmYRMinorOn          = False   ; Turn off minor ticks on Y axis
    res@trYMinF = -1
    res@trYMaxF = 140
;;---X Axis
    restick  =  True
    time_axis_labels (plot_time, res, restick)
    res@tmXBLabelFontHeightF  = 0.015

    ;;-----For layout
    res@vpWidthF    = 0.75
    res@vpHeightF   = 0.4

    res@xyMarkLineMode = "Lines"
    res@xyDashPatterns = 0
    Line_color = new (140,"string")
    Line_color(:) = "blue"
    res@xyLineColors  = Line_color     
    Line_thickness = new (140,integer)
    Line_thickness = 3
    
    res@xyLineThicknesses  =  Line_thickness   

    plot = gsn_csm_xy (wks, plot_time,transpose(plot_data),res)

  end do ;;i_sp
  
end  ;;begin
