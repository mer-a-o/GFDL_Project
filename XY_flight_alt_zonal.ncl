
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
;    mission_name = "SEAC4RS-2013"
    mission_name = "HIPPO"
    h_year = "2010"
    data_dir    = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/"+mission_name+"/"
    var_name    = "CH4_MixingRatio"
;    var_name = "Methane_mixing_ratio"i
;    var_name = "CH4_WAS"


;;---Read Flight data 
    fils = systemfunc("ls "+data_dir+"*2010.nc")
    flight_file = addfile(fils, "r")   
    time_unit = flight_file->time
    flight_time  = flight_file->UTC ;; time_unit is the unit
    copy_VarAtts (time_unit,flight_time)
    flight_lat = flight_file->LATITUDE
    flight_lat_int = toint (flight_lat)
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

printVarSummary(flight_var)
;;---Alt  binning
;    alt_wanted = (/1000,2000,3000,4000,5000,6000/)
    alt_ind = round(flight_alt/1000,3)
    num_bins = (max(alt_ind) - min(alt_ind))+1  ;;# of bins
    bin_val = ispan(min(alt_ind),max(alt_ind),1)
    print("Number of bins = "+num_bins)
    print("Bin Values(km) = "+bin_val)

    lat_bin = ispan (-90,90,1)

    num_lat_bins = dimsizes(lat_bin)

;    mean_bin = new (num_bins,float)
;    std_bin = new(num_bins,float)

    ;bin_var = new ((/num_data,num_bins,num_lat_bins/),float)

    bin_var = new ((/num_bins,num_lat_bins/),float)

    bin_var@_FillValue = -9999999

;    err_bar = new ((/num_bins,2/),float)
;    counter_data_arr = new (num_bins,float) ;;How many data in each bin

    bin_lat = new ((/num_data,num_bins,num_lat_bins/),float)
    bin_lat@_FillValue = -9999999    
    bin_lon = new ((/num_data,num_bins,num_lat_bins/),float)
    bin_lon@_FillValue =  -9999999
    bin_alt = new ((/num_data,num_bins,num_lat_bins/),float)
    bin_alt@_FillValue =  -9999999

 ;;-------

;print (flight_lat_int(get1Dindex(lat_bin,flight_lat_int)))
;print (lat_bin)
do  i_lat_bin=0,num_lat_bins-1
    do i_bin = 0,num_bins-1
        indind := ind(flight_lat_int.eq.lat_bin(i_lat_bin).and.alt_ind.eq.bin_val(i_bin))
        print ("LAT,ALT ="+lat_bin(i_lat_bin)+","+i_bin+" ind ="+ indind)
        if (all(ismissing(indind)))then 
            bin_var(i_bin,i_lat_bin) = -9999999
        else
            bin_var(i_bin,i_lat_bin) = avg (flight_var(indind))
        end if
    end do ;;i_bin 
end do ;i_lat_bin

print(bin_var)
;;---------------------------------------------
;; Plotting
;;---------------------------------------------
    plot_type = "pdf"
    plot_name = "Flight_track_zonal"+mission_name+"-"+h_year+"_cross"
    wks = gsn_open_wks(plot_type,plot_name)
    colormap = "MPL_jet"
    gsn_define_colormap (wks,colormap)
    cmap = gsn_retrieve_colormap(wks)

    levels = fspan (1700,1900,20)
    nlevels = dimsizes(levels)
; Get a nice span of colors through the current color map, but
; skip the first three colors (0-2).
;
    colors = span_color_indexes(cmap(3:,:),dimsizes(levels)+1) + 3

;----------------------------------------------------------------------
; Create a map plot for which to add color-coded markers.
;----------------------------------------------------------------------
    res                       = True
    res@gsnMaximize           = True   ; maximize size of plot in window
    res@gsnDraw               = False  ; turn off draw
    res@gsnFrame              = False  ; turn off page advance

    res@vpWidthF   = 0.8
    res@vpHeightF  = 0.4

    res@tiMainFontHeightF = 0.02
    res@gsnStringFontHeightF = 0.02
    res@tiMainString         = mission_name+" 2010"
    res@xyMarkLineMode  = "Lines"
    res@xyLineThicknesses = 0.1

    res@xyMarkerColors  = "grey100"
    res@trYMinF   = -1000
    res@trYMaxF  = 16000

    plot = gsn_csm_xy(wks,flight_lat,flight_alt,res)

;----------------------------------------------------------------------
; Group the wind speed values according to which range they fall
; in, and attach them to the map as a colored marker.
;----------------------------------------------------------------------
    mkres               = True
    mkres@gsMarkerIndex = 16        ; filled dot
    mkres@gsMarkerSizeF = 0.01
    Var = new ((/num_lat_bins/),float)
    markerid = new((/nlevels+1,num_bins/),graphic)
    do ip_bin = 0,num_bins-1
;        Var = flight_var
        Var = bin_var(ip_bin,:)
        do i=0,nlevels
            if(i.eq.0) then                         ; first level
                ii := ind(Var.lt.levels(0))
            else if(i.eq.nlevels) then              ; middle levels
                ii := ind(Var.ge.levels(nlevels-1))
            else                                    ; last level
                ii := ind(Var.ge.levels(i-1).and.Var.lt.levels(i))
            end if
            end if
            if(.not.any(ismissing(ii))) then
                mkres@gsMarkerColor = colors(i)
                ;markerid(i) = gsn_add_polymarker(wks,plot,flight_lat(ii),flight_alt(ii),mkres)
;print (bin_alt(ii,ip_bin))
                markerid(i,ip_bin) = gsn_add_polymarker(wks,plot,lat_bin(ii),1000*bin_val(ip_bin),mkres)
            end if
        end do
;        delete (Var)
    end do ;;ip_bin

    draw(plot)   ; This will draw map and the attached markers
;----------------------------------------------------------------------
; Draw a labelbar
;----------------------------------------------------------------------
    lbres                    = True
    lbres@vpWidthF           = 0.80             ; width
    lbres@vpHeightF          = 0.10             ; height
    lbres@lbPerimOn          = False            ; Turn off perimeter.
    lbres@lbOrientation      = "Horizontal"     ; Default is vertical.
    lbres@lbLabelAlignment   = "InteriorEdges"  ; Default is "BoxCenters".
    lbres@lbFillColors       = colors           ; Colors for boxes.
    lbres@lbMonoFillPattern  = True             ; Fill them all solid.
    lbres@lbLabelFontHeightF = 0.013            ; label font height
;  lbres@lbLabelPosition = "Center"

    lbres@lbTitleString      = "CH4 (ppbv)"         ; title
    lbres@lbTitlePosition    = "Bottom"         ; location of title
    lbres@lbTitleFontHeightF = 0.015             ; title font height
;;  lbres@lbLabelAutoStride = False ; let NCL determine label spacing 

    lbres@pmLabelBarOrthogonalPosF =0
    labels = sprintf("%4.0f",levels)
  gsn_labelbar_ndc (wks,nlevels+1,labels,0.15,0.2,lbres) 
;    gsn_labelbar_ndc (wks,nlevels+1,labels,0.0,0.8,lbres)

    frame(wks)
end ;;begin
