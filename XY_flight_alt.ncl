
;purpose: 
;   Plot Height(Y-Axis) vs. CH4 conc obsereved by flight 
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
;    mission_name = "FRAPPE-2014"
;    mission_name = "CALIFORNIA-2013"
;    mission_name = "BALTIMORE-2011"
    mission_name = "SEAC4RS-2013"
    data_dir    = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/DISCOVERAQ/"+mission_name+"/"
;    var_name    = "CH4_MixingRatio"
;    var_name = "Methane_mixing_ratio"i
    var_name = "CH4_WAS"


;;---Read Flight data 
    fils = systemfunc("ls "+data_dir+"*.convert.nc")
    flight_file = addfile(fils, "r")   
    time_unit = flight_file->time
    flight_time  = flight_file->UTC ;; time_unit is the unit
    copy_VarAtts (time_unit,flight_time)
    flight_lat = flight_file->LATITUDE
    flight_lon = flight_file->LONGITUDE
    flight_alt = 1000*(flight_file->ALTP)  ;km to m
    flight_press = flight_file->PRESSURE
;    flight_var = flight_file->$var_name$
    flight_var = 1000*(flight_file->$var_name$) ;;SEAC4RS is in ppm
    num_data = dimsizes(flight_lat)     ;;# data points
;print (flight_var)
    if (any(flight_var.lt.0)) then
        flight_var(ind(flight_var.lt.0)) = -9999999 ;;covers different missing values or bugs in datasets
    end if

printVarSummary(flight_var)
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
;;-------
    do i_bin = 0,num_bins-1
        counter_data := 0
        do j_data = 0, num_data-1
           
            if ((.not.ismissing(alt_ind(j_data))).and. (.not.ismissing(flight_var(j_data)))) then
                if (alt_ind(j_data).eq.bin_val(i_bin)) then
                    bin_var (counter_data,i_bin) = flight_var(j_data) ;;loose data index
                   ; bin_var (j_data,i_bin) = flight_var(j_data) ;; Keep data index
                    counter_data := counter_data+1
                 end if
             else
                 bin_var(j_data,i_bin) = -9999999
             end if
        end do ;;j_data
        counter_data_arr(i_bin) = counter_data
    end do ;;i_bin 
    print(counter_data_arr)
print (min(bin_var(:,0)))
;;---Calculate stats for each bin
    do ii_bin = 0,num_bins -1
        if (.not.all(ismissing(bin_var(:,ii_bin)))) then
            mean_bin(ii_bin) = avg(bin_var(:,ii_bin))
            std_bin (ii_bin) = stddev(bin_var(:,ii_bin))
            err_bar (ii_bin,0) = mean_bin(ii_bin) - std_bin(ii_bin)/sqrt(counter_data_arr(ii_bin))
            err_bar(ii_bin,1) =  mean_bin(ii_bin) + std_bin(ii_bin)/sqrt(counter_data_arr(ii_bin))
        end if
            
    end do ;;ii_bin
;    print(flight_var(865:880))
;    print (alt_ind(865:880))
    print (mean_bin)
    print (std_bin)
    print (err_bar)
;;---------------------------------------------
;; Plotting
;;---------------------------------------------
    plot_type = "pdf"
    plot_name = "Alt_Ch4_testruns_"+mission_name
    wks = gsn_open_wks(plot_type,plot_name)
    res     = True
    res@gsnMaximize = True
    res@gsnPaperOrientation = "portrait"

    res@gsnCenterString = mission_name
    res@gsnStringFontHeightF = 0.02

    res@gsnFrame               = False                     ; don't draw yet
    res@gsnDraw                = False                     ; don't advance frame

;;---Marker resources
    res@xyMarkLineMode   = "Markers"
    res@xyMarkers        = 1
    res@xyMarkerSizeF    = 0.03

;;---Y Axis
    res@trYMinF = -0.5
    res@trYMaxF = 13
    res@tiYAxisString = "Alt (km)"
    res@tiYAxisFontHeightF = 0.02  
    res@tmYLLabelFontHeightF = 0.02
;;---X Axis
    res@trXMinF = min(err_bar(:,0))-10
    res@trXMaxF = max(err_bar(:,1))+10
    res@tiXAxisString = "CH4 (pbb)"
    res@tiXAxisFontHeightF = 0.02  
    res@tmXBLabelFontHeightF = 0.02

    plot    = gsn_csm_xy (wks,mean_bin,bin_val,res)
;;----Plot Error Bars
    error_bar = new (num_bins,graphic)
    polyres     = True
    polyres@gsLineThicknessF = 4.0            ; line thickness  
    polyres@gsLineColor      = "red" 
    do i_errbar=0,num_bins-1
        if (.not.ismissing(err_bar(i_errbar,0))) then
            error_bar(i_errbar) = gsn_add_polyline(wks,plot,err_bar(i_errbar,:),(/bin_val(i_errbar),bin_val(i_errbar)/),polyres)
        else
            continue
        end if
    end do ;;num_bins
    draw(plot)
    frame(wks)
end ;;begin
