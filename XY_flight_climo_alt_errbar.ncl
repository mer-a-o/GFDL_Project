
;purpose: 
;   Plot Height(Y-Axis) vs. CH4 conc obsereved by flight and simulations
;   Flight data must be in NetCDF format
;
; Modification History
;      Created on June-2016, MAO
;_________________________________________________________________________


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

;**********************************************************************

begin
; Define constants
    mw_air = 28.966  ; g/mole
    mw_h2o = 18.01528 ; g/mole
    pref = 1013.246  ; mbar  reference pressure
    tref = 288.15    ; K  reference temperature
    lapserate = 0.0065   ; K/m  lapse rate
    x = 0.190284     ; R gamma/g  (dry air)

;    mission_name = "FRAPPE-2014"
;    mission_name = "CALIFORNIA-2013"
;    mission_name = "BALTIMORE-2011"
;    mission_name = "SEAC4RS-2013"
;    mission_name = "HIPPO"
    mission_name = "ARCTAS"
;    ARCTAS_miss = "20080401_R14_thru20080419"
;    ARCTAS_miss = "20080618_R14_thru20080626"
    ARCTAS_miss = "20080629_R14_thru20080713"

    h_year = ARCTAS_miss
;    h_year = "2009"
;    h_year = "all"
;    h_year = ""

    campaign_month = 1
;    data_dir    = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/DISCOVERAQ/"+mission_name+"/"
;    data_dir = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/HIPPO/"
    data_dir    = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/"+mission_name+"/"
 
   
    var_name    = "CH4_MixingRatio"

;;---Read Flight data 
;    fils = systemfunc("ls "+data_dir+"*.convert.nc")
;    fils = systemfunc("ls "+data_dir+"HIPPO_"+h_year+".nc")
    fils = systemfunc("ls "+data_dir+"/ARCTAS-mrg60-dc8_merge_"+ARCTAS_miss+".convert.nc")


    flight_file = addfile(fils, "r")   
    time_unit = flight_file->time
    flight_time  = flight_file->UTC ;; time_unit is the unit
    copy_VarAtts (time_unit,flight_time)
    flight_lat = flight_file->LATITUDE
    flight_lon = flight_file->LONGITUDE
    flight_lon = where (flight_lon.lt.0,flight_lon+360.,flight_lon)
    flight_alt = 1000*(flight_file->ALTP)  ;km to m
    ;flight_press = flight_file->PRESSURE
    flight_var = flight_file->$var_name$
;    flight_var = 1000*(flight_file->$var_name$) ;;SEAC4RS is in ppm
    num_data = dimsizes(flight_lat)     ;;# data points
;print (flight_var)
    if (any(flight_var.lt.0)) then
        flight_var(ind(flight_var.lt.0)) = -9999999 ;;covers different missing values or bugs in datasets
    end if


    flight_time_conv = cd_calendar(flight_time,0)
    flight_time_mo = toint(flight_time_conv(:,1))

printVarSummary (flight_time_mo)
printVarSummary(flight_var)
print(flight_time_mo)
;---------------------------------------------
;; Read and interpolate model
;;---------------------------------------------
;;----model direcotry
    modeldir_conc = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4conc_newinitcond/"
    modeldir_emis = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4emis_newinitcond/"
    modeldir_emis30 = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_30percentch4emis_newinitcond/"
    modeldir_emis40 = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_40percentch4emis_newinitcond/"
;;----Model mode and big loop
    model_mode = (/"conc","emis20","emis30","emis40"/)
    num_model = dimsizes(model_mode)

    modconcatsite = new((/num_model,num_data,1/),float)
    modconcatsite!0 = "mode"
    modconcatsite!1 = "obs"
    modconcatsite!2 = "time"
    modconcatsite@_FillValue = -9999999

    do i_mode =0,num_model-1
        if (i_mode.eq.0)then
          modeldir := modeldir_conc
          print ("MODE = ch4conc")
        else if (i_mode.eq.1)then
          modeldir := modeldir_emis
          print ("MODE = ch4emis")
        else if (i_mode.eq.2) then
          modeldir := modeldir_emis30
          print ("MODE = ch4emis30")
        else if (i_mode.eq.3) then
          modeldir := modeldir_emis40
          print ("MODE = ch4emis40")
        end if
        end if
        end if
        end if
;;---Read Static files         
        staticfile = modeldir_emis40+"tracer_level.static.nc"

        static := addfile(staticfile,"r")
        mod_lat := static->lat
        mod_lon := static->lon
        bk := static->bk
        pk := static->pk
        npedge = dimsizes(static->phalf)
        npfull = npedge - 1 

        fils := systemfunc ("ls "+modeldir+"tracer_level.*.nc")
        fin := addfiles(fils, "r")   ; note the "s" of addfile
        ListSetType(fin, "cat")

        pfull := fin[0]->pfull
        sfclev := dimsizes(pfull)-1
        sfcpfull := pfull(sfclev)

        time := fin[:]->time
        modelconc := fin[:]->CH4
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

        modelconcatsite := linint2_points_Wrap(modlon,modlat,modelconc,True,flight_lon,flight_lat,0) 
        modelaltatsite = linint2_points_Wrap(modlon,modlat,model_alt,True,flight_lon,flight_lat,0)
        modelsphumatsite := linint2_points_Wrap(modlon,modlat,modelsphum,True,flight_lon,flight_lat,0)
        printVarSummary(modelconcatsite)

        modelaltatsite@_FillValue = -9999999
        
        ;printVarSummary(modconcatsite)
; Find the pressure level nearest to station altitude - not using annual mean pressure as pressure 
; changes from month-to-month
;        do m = 8, 8
        printMinMax(flight_time_mo,0)
        mm =0
            do i_data = 0, num_data-1
                if (.not.ismissing(flight_alt(i_data)).and..not.ismissing(modelaltatsite(flight_time_mo(i_data), npfull-1,i_data))) then 
;print (modelaltatsite(flight_time_mo(i_data), npfull-1,i_data))
                    if (flight_alt(i_data) .lt. modelaltatsite(flight_time_mo(i_data), npfull-1,i_data)) then 
                         ilev = npfull - 1 
                    else 
                        ilev = ind_nearest_coord(flight_alt(i_data),modelaltatsite(flight_time_mo(i_data),:,i_data),0)   ; get model altitude nearest to the station altitude
                    end if
                    modconcatsite(i_mode,i_data,mm) = 1000000000*(/modelconcatsite(flight_time_mo(i_data),ilev,i_data)/(1-(modelsphumatsite(flight_time_mo(i_data),ilev,i_data)/(mw_h2o/mw_air)))/)
;                    modconcatsite(i_mode,i_data,mm) = 1000000000*modelconcatsite(flight_time_mo(i_data),ilev,i_data)  ;;ppbv dry air
                  
                    ; print (modconcatsite(i_mode,i_data,mm))
                else
                ;     modconcatsite(i_mode,i_data,mm) = -9999999
                end if 
             end do  ; sites
;        end do  ;;m
        


    end do ;;i_mode 
;    print (modconcatsite(:,1:10,:))
;;-----------------------------------------------
;;BINNING
;;---------------------------------------------
    
;;---Alt  binning
;    alt_wanted = (/1000,2000,3000,4000,5000,6000/)
    alt_ind = round(flight_alt/1000,3)
    num_bins = (max(alt_ind) - min(alt_ind))+1  ;;# of bins
print (min(alt_ind))
print (max(alt_ind))
    bin_val = ispan(min(alt_ind),max(alt_ind),1)
    print("Number of bins = "+num_bins)
    print("Bin Values(km) = "+bin_val)
    mean_bin = new (num_bins,float)
    std_bin = new(num_bins,float)
    bin_var = new ((/num_data,num_bins/),float)
    bin_var@_FillValue = -9999999
    err_bar = new ((/num_bins,2/),float)
    counter_data_arr = new (num_bins,float) ;;How many data in each bin
;;---Vars holding model stats    
    bin_sim = new((/num_model,num_data,num_bins/),float) ;;[mode,data,bins]
    bin_sim@_FillValue = -9999999
    mean_bin_sim = new ((/num_model,num_bins/),float)
    std_bin_sim = new((/num_model,num_bins/),float)
    err_bar_sim = new ((/num_model,num_bins,2/),float)

;;-------
    do i_bin = 0,num_bins-1
        counter_data := 0
        do j_data = 0, num_data-1
           
            if ((.not.ismissing(alt_ind(j_data))).and. (.not.ismissing(flight_var(j_data)))) then
                if (alt_ind(j_data).eq.bin_val(i_bin)) then
                    bin_var (counter_data,i_bin) = flight_var(j_data) ;;loose data index
                   ; bin_var (j_data,i_bin) = flight_var(j_data) ;; Keep data index
                    bin_sim (:,counter_data,i_bin) = modconcatsite (:,j_data,0)  ;;[mode=2,datapoint=loop,time=1]
                    counter_data := counter_data+1
                 end if
             else
                 bin_var(j_data,i_bin) = -9999999
             end if
        end do ;;j_data
        counter_data_arr(i_bin) = counter_data
    end do ;;i_bin 
    print(counter_data_arr)
;print (min(bin_var(:,0)))
;;---Calculate stats for each bin
    do ii_bin = 0,num_bins -1
        if (.not.all(ismissing(bin_var(:,ii_bin)))) then
            mean_bin(ii_bin) = avg(bin_var(:,ii_bin))
            std_bin (ii_bin) = stddev(bin_var(:,ii_bin))
            err_bar (ii_bin,0) = mean_bin(ii_bin) - std_bin(ii_bin)/sqrt(counter_data_arr(ii_bin))
            err_bar(ii_bin,1) =  mean_bin(ii_bin) + std_bin(ii_bin)/sqrt(counter_data_arr(ii_bin))
;;------Sim stats
            do ii_mode =0,num_model-1
                mean_bin_sim(ii_mode,ii_bin) = avg(bin_sim(ii_mode,:,ii_bin))
                std_bin_sim(ii_mode,ii_bin)  = stddev(bin_sim(ii_mode,:,ii_bin))
                err_bar_sim(ii_mode,ii_bin,0) = mean_bin_sim(ii_mode,ii_bin) - std_bin_sim(ii_mode,ii_bin)/sqrt(counter_data_arr(ii_bin))
                err_bar_sim(ii_mode,ii_bin,1) = mean_bin_sim(ii_mode,ii_bin) + std_bin_sim(ii_mode,ii_bin)/sqrt(counter_data_arr(ii_bin))
            end do ;;i_mode
        end if
    end do ;;ii_bin   
    print ("MEAN OBS = "+mean_bin)
;;---------------------------------------------
;; Plotting
;;---------------------------------------------
    plot_type = "pdf"
    plot_name = "plot_XY_flight_climo_alt_"+mission_name+"_"+h_year


    wks = gsn_open_wks(plot_type,plot_name)
    res     = True
    res@gsnMaximize = True
    res@gsnPaperOrientation = "portrait"

    res@gsnCenterString = mission_name+"_"+h_year
    res@gsnStringFontHeightF = 0.015

    res@gsnFrame               = False                     ; don't draw yet
    res@gsnDraw                = False                     ; don't advance frame

;;---Y Axis
    res@trYMinF = -0.5
    res@trYMaxF = 15
    res@tiYAxisString = "Alt (km)"
    res@tiYAxisFontHeightF = 0.015  
    res@tmYLLabelFontHeightF = 0.018
;;---X Axis
    res@trXMinF = 1500
    res@trXMaxF = 2000
    res@tiXAxisString = "CH4 (pbb)"
    res@tiXAxisFontHeightF = 0.015  
    res@tmXBLabelFontHeightF = 0.018

    ressim = res

;;---Marker resources
    res@xyMarkLineMode   = "Markers"
    res@xyMarkers        = 1
    res@xyMarkerSizeF    = 0.05

    ressim@xyMarkLineMode = "Markers"
    ressim@xyMarkers      = (/7,6,15,9/)
    ressim@xyMarkerSizeF  = 0.013
    ressim@xyMarkerColors   = (/"red","chartreuse4","orange2","blue"/)
    ressim@xyMarkerThicknessF = 3.5



    plot_obs    = gsn_csm_xy (wks,mean_bin,bin_val,res)
    plot_sim    = gsn_csm_xy (wks,mean_bin_sim,bin_val,ressim)
    overlay(plot_obs,plot_sim)
;;----Plot Error Bars
    error_bar = new (num_bins,graphic)
    error_bar_sim_conc = new (num_bins,graphic)
    error_bar_sim_emis = new (num_bins,graphic)
    error_bar_sim_emis30 =  new (num_bins,graphic)
    error_bar_sim_emis40 =  new (num_bins,graphic)

    polyres     = True
    polyres@gsLineThicknessF = 4.0            ; line thickness  
    polyres@gsLineColor      = "deeppink" 
    do i_errbar=0,num_bins-1
        if (.not.ismissing(err_bar(i_errbar,0))) then
            error_bar(i_errbar) = gsn_add_polyline(wks,plot_obs,err_bar(i_errbar,:),(/bin_val(i_errbar),bin_val(i_errbar)/),polyres)
            error_bar_sim_conc(i_errbar) = gsn_add_polyline(wks,plot_obs,err_bar_sim(0,i_errbar,:),(/bin_val(i_errbar),bin_val(i_errbar)/),polyres)
            error_bar_sim_emis(i_errbar) = gsn_add_polyline(wks,plot_obs,err_bar_sim(1,i_errbar,:),(/bin_val(i_errbar),bin_val(i_errbar)/),polyres)
            error_bar_sim_emis30(i_errbar) = gsn_add_polyline(wks,plot_obs,err_bar_sim(2,i_errbar,:),(/bin_val(i_errbar),bin_val(i_errbar)/),polyres)
            error_bar_sim_emis40(i_errbar) = gsn_add_polyline(wks,plot_obs,err_bar_sim(3,i_errbar,:),(/bin_val(i_errbar),bin_val(i_errbar)/),polyres)
        else
            continue
        end if
    end do ;;num_bins
;;---Legend
    lgres = True
    lgres@lgMarkerIndexes = (/7,6,15,9,16/)
    lgres@lgItemType      = "Markers"
    lgres@lgMarkerColors  = (/"red","chartreuse4","orange2","blue","black"/)
    lgres@vpWidthF        = 0.13
    lgres@vpHeightF       = 0.12
    lgres@lgLabelsOn      = True
    lgres@lgLabelFontHeightF = 0.1

    gsn_legend_ndc(wks,5,(/"conc","emis20","emis30","emis40","obs"/),0.18,0.92,lgres)

    draw(plot_obs)
    frame(wks)
end ;;begin
