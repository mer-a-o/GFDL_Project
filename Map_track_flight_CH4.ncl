


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

;**********************************************************************

begin

;    mission_name = "HIPPO"
;    mission_name = "CALIFORNIA-2013"
    mission_name = "ARCTAS"

;    ARCTAS_miss = "20080401_R14_thru20080419"
;    ARCTAS_miss = "20080618_R14_thru20080626"
     ARCTAS_miss = "20080629_R14_thru20080713"


    data_dir = "/Users/mabdioskouei/GFDL_METHANE/obs_data/Flight_Data/"+mission_name+"/"
    var_name = "CH4_MixingRatio"

;;---Read Flight Data
;    fils = systemfunc("ls "+data_dir+"*2011.nc")
    fils = systemfunc("ls "+data_dir+"/ARCTAS-mrg60-dc8_merge_"+ARCTAS_miss+".convert.nc")

    flight_file = addfile(fils, "r")   

    time_unit = flight_file->time
    flight_time  = flight_file->UTC ;; time_unit is the unit
    copy_VarAtts (time_unit,flight_time)

    flight_lat = flight_file->LATITUDE
    flight_lon = flight_file->LONGITUDE
    flight_alt = 1000*(flight_file->ALTP)  ;km to m
    flight_var = flight_file->$var_name$
;    flight_var = 1000*(flight_file->$var_name$) ;;SEAC4RS is in ppm
    num_data = dimsizes(flight_lat)     ;;# data points
;print (flight_var)
    if (any(flight_var.lt.0)) then
        flight_var(ind(flight_var.lt.0)) = -9999999 ;;covers different missing values or bugs in datasets
    end if



;;********************************************
;;Plotting
;;********************************************

    plot_type  =  "pdf"
;    plot_name  = "Flight_track_"+mission_name+"2011"
    plot_name = "Plot_Map_track_flight_CH4_"+mission_name+"_"+ARCTAS_miss

    wks = gsn_open_wks (plot_type, plot_name)
 ;   colormap = "StepSeq25"
    colormap = "MPL_jet"
    gsn_define_colormap (wks,colormap)
;    gsn_reverse_colormap (wks)
    cmap = gsn_retrieve_colormap(wks)
   
    levels = fspan (1700,1900,20)
    nlevels = dimsizes(levels)
; Get a nice span of colors through the current color map, but
; skip the first three colors (0-2).
;
    colors = span_color_indexes(cmap(3:,:),dimsizes(levels)+1) + 3

 ;   colors = (/0,26,24,22,21,20,19,17,16,14,12,11,9,7,6,5,4,3,2/)
 ;   ncolors = dimsizes(colors)
 ;   levels = fspan (1700,2000,ncolors-1)
    ;levels = (/1300, 1340,1380,1420,1460,1500,1540,1580,1620.,1660.,1700.,1740.,1760.,1800.,1820.,1840.,1860.,1900./)
    nlevels = dimsizes(levels)


;----------------------------------------------------------------------
; Create a map plot for which to add color-coded markers.
;----------------------------------------------------------------------
    mpres                       = True


    mpres@gsnMaximize           = True   ; maximize size of plot in window
    mpres@gsnDraw               = False  ; turn off draw
    mpres@gsnFrame              = False  ; turn off page advance
    mpres@mpDataBaseVersion     = "MediumRes"     ; Better map resolution
    mpres@mpLandFillColor       = "tan"
    mpres@tiMainFontHeightF = 0.02
    mpres@pmTickMarkDisplayMode = "Always"    ; Nicer map tickmarks

    mpres@mpProjection         = "Robinson"
    mpres@mpPerimOn            = True
    mpres@gsnStringFontHeightF = 0.02

;    mpres@tiMainString         = mission_name+" 2011"
    mpres@tiMainString         = mission_name+" "+ARCTAS_miss
    
    map = gsn_csm_map (wks,mpres)

;----------------------------------------------------------------------
; Group the wind speed values according to which range they fall
; in, and attach them to the map as a colored marker.
;----------------------------------------------------------------------
    mkres               = True
    mkres@gsMarkerIndex = 16        ; filled dot
    mkres@gsMarkerSizeF = 0.003
    markerid = new(nlevels+1,graphic)
    Var = flight_var
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
            markerid(i) = gsn_add_polymarker(wks,map,flight_lon(ii),flight_lat(ii),mkres)
        end if
    end do
    draw(map)   ; This will draw map and the attached markers

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
    lbres@lbTitleFontHeightF = 0.013             ; title font height
;;  lbres@lbLabelAutoStride = False ; let NCL determine label spacing 

    lbres@pmLabelBarOrthogonalPosF =0
    labels = sprintf("%4.0f",levels)
;;  gsn_labelbar_ndc (wks,nlevels+1,labels,0.1,0.23,lbres) 
  gsn_labelbar_ndc (wks,nlevels+1,labels,0.13,0.2,lbres)



    

    frame (wks)

end ;;begin
