
;_________________________________________________________________________
;purpose: 
;   Height (Y-Axis) vs. Latitude (X-Axis). plot flight tracjectory,
;   illustrates latitude of measurement
;   Contour plot, obs avg over alt bins (1km) and lat bins (.5 deg)
;   , colored by obs CH4 concentration
;   Flight data must be in NetCDF format
;
; Modification History
;      Created on July-2016, MAO
;_________________________________________________________________________


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

;**********************************************************************

begin
;    mission_name = "FRAPPE-2014"
;    mission_name = "CALIFORNIA-2013"
;    mission_name = "BALTIMORE-2011"
;    mission_name = "SEAC4RS-2013"
;    mission_name = "HIPPO"
    mission_name = "ARCTAS"
    ARCTAS_miss = "20080401_R14_thru20080419"
;    ARCTAS_miss = "20080618_R14_thru20080626"
;    ARCTAS_miss = "20080629_R14_thru20080713"



    h_year = ""
;    data_dir    = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/DISCOVERAQ/"+mission_name+"/"
    data_dir    = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/"+mission_name+"/"
    var_name    = "CH4_MixingRatio"
;    var_name = "Methane_mixing_ratio"i
;    var_name = "CH4_WAS"


;;---Read Flight data 
;    fils = systemfunc("ls "+data_dir+"*.nc")
    fils = systemfunc("ls "+data_dir+"/ARCTAS-mrg60-dc8_merge_"+ARCTAS_miss+".convert.nc")

    flight_file = addfile(fils, "r")   
    time_unit = flight_file->time
    flight_time  = flight_file->UTC ;; time_unit is the unit
    copy_VarAtts (time_unit,flight_time)
    flight_lat = flight_file->LATITUDE
    flight_lat_int_p = toint (flight_lat)
    flight_lon = flight_file->LONGITUDE
    flight_alt = 1000*(flight_file->ALTP)  ;km to m
;    flight_press = flight_file->PRESSURE
    flight_var = flight_file->$var_name$
;    flight_var = 1000*(flight_file->$var_name$) ;;SEAC4RS is in ppm
    num_data = dimsizes(flight_lat)     ;;# data points
;print (flight_var)
    if (any(flight_var.lt.0)) then
        flight_var(ind(flight_var.lt.0)) = -9999999 ;;covers different missing values or bugs in datasets
    end if

    flight_lat_int = new(num_data,float)
    do i_data=0,num_data-1
        print (flight_lat(i_data)-flight_lat_int_p(i_data))

        if ((flight_lat(i_data)-flight_lat_int_p(i_data)).gt.0.5.or.(flight_lat(i_data)-flight_lat_int_p(i_data)).lt.-0.5) then
            flight_lat_int (i_data) = flight_lat_int_p(i_data)+0.5
        else 
            flight_lat_int (i_data) = flight_lat_int_p(i_data)
        end if
    end do ;;i_data

print(flight_lat_int)
printVarSummary(flight_var)
;;---Alt  binning
;    alt_wanted = (/1000,2000,3000,4000,5000,6000/)
    alt_ind = round(flight_alt/1000,3)
;    alt_ind = toint(flight_alt)

    num_bins = (max(alt_ind) - min(alt_ind))+1  ;;# of bins
    bin_val = ispan(min(alt_ind),max(alt_ind),1)
    bin_val@Units = "km"
    print("Number of bins = "+num_bins)
    print("Bin Values(km) = "+bin_val)
;    print("Bin Values(m) = "+bin_val)

    ;lat_bin = ispan (-90,90,1)
    lat_bin = fspan (-90,90,361)
    num_lat_bins = dimsizes(lat_bin)

;    mean_bin = new (num_bins,float)
;    std_bin = new(num_bins,float)

    ;bin_var = new ((/num_data,num_bins,num_lat_bins/),float)

    bin_var = new ((/num_bins,num_lat_bins/),float)
    bin_var@_FillValue = -9999999
 ;;-------

;print (flight_lat_int(get1Dindex(lat_bin,flight_lat_int)))
;print (lat_bin)
    do  i_lat_bin=0,num_lat_bins-1
        do i_bin = 0,num_bins-1
            indind := ind(flight_lat_int.eq.lat_bin(i_lat_bin).and.alt_ind.eq.bin_val(i_bin))
    ;        print ("LAT,ALT ="+lat_bin(i_lat_bin)+","+i_bin+" ind ="+ indind)
            if (all(ismissing(indind)))then 
                bin_var(i_bin,i_lat_bin) = -9999999
            else
                bin_var(i_bin,i_lat_bin) = avg (flight_var(indind))
            end if
        end do ;;i_bin 
    end do ;i_lat_bin
    bin_var!0 = "Height"
    bin_var&Height = bin_val
    bin_var!1 = "latitude"
    bin_var&latitude = lat_bin
    bin_var@Units = "CH4 ppbv"

;print(bin_var)
;;---------------------------------------------
;; Plotting
;;---------------------------------------------
    plot_type = "pdf"
;    plot_name = "Flight_track_zonal"+mission_name+"-"+h_year+"_cross_contour"
    plot_name  = "Flight_track_zonal"+mission_name+"_"+ARCTAS_miss

    wks = gsn_open_wks(plot_type,plot_name)
    colormap = "MPL_jet"
    gsn_define_colormap (wks,colormap)

    Levels = fspan (1700,1900,21) 
;----------------------------------------------------------------------
; Create a map plot for which to add color-coded markers.
;----------------------------------------------------------------------
    res                       = True
    res@gsnMaximize = True
    res@lbOrientation = "Vertical"

    res@gsnDraw = False
    res@gsnFrame = False

    res@cnFillOn = True
    res@cnLinesOn = False
;    res@tiMainString = mission_name+"_"+h_year
    
    res@tiMainString = mission_name+"_"+ARCTAS_miss
 
    res@tiMainFontHeightF = 0.02

;;---Contour settings
    res@cnLevelSelectionMode = "ExplicitLevels"
    res@cnLevels             = Levels

    res@cnLineLabelsOn = False
    res@cnInfoLabelOn  = False
;;---Outline 
    res@vpWidthF            = 0.7           ; change aspect ratio of plot
    res@vpHeightF           = 0.5
;;---Axis Setting
    res@tiYAxisString = "Alt(km)"
    res@tiYAxisFontHeightF = 0.02  
    res@tmYLLabelFontHeightF = 0.02
    res@trYMinF = 0
    res@trYMaxF = 15

    res@trXMinF = -90
    res@trXMaxF = 90

    res@tiXAxisString = "Lat"
    res@tiXAxisFontHeightF = 0.02  
    res@tmXBLabelFontHeightF = 0.02
    plot = gsn_csm_contour (wks,bin_var,res)
    
;----------------------------------------------------------------------
; Create flight track to overlay
;----------------------------------------------------------------------
;    xyres                       = True


;    res@gsnMaximize           = True   ; maximize size of plot in window
;    xyres@gsnDraw               = False  ; turn off draw
;    xyres@gsnFrame              = False  ; turn off page advance
    
;    xyres@xyMarkLineMode  = "Markers"
;    xyres@xyMarker = 1
;    xyres@xyMarkerSizeF = .01
;    res@trYMinF     = 0

;    res@tiMainFontHeightF = 0.02
;    res@gsnStringFontHeightF = 0.02
;    res@tiMainString         = mission_name+" 2009"
;    xyres@xyMarkerColors  = "black"

;    plot_xy = gsn_csm_xy(wks,flight_lat,flight_alt,xyres)

;    overlay(plot,plot_xy)
    draw(plot)
    frame(wks)

    
end ;;begin
