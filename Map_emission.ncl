
;_________________________________________________________________________
; Purpose: 
;   Global Spatial distribution of different species from emission file.
;
;
; Modification History
;      
;    Created on July 2016, MAO (based on V. Naik original scripts)
;_________________________________________________________________________


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"


begin

;;---Constant values

    res = "1x1"
    scenario = "historical"

    source_list = (/"anthro","bb","ship","ch4_wetl","ocean","biogenic"/)
    ylabels = (/"Anthro","Biomass Burning","Ships","Wetlands","Ocean","Biogenic"/)
    nsource = dimsizes(source_list)

    xyear = (/2000/)
    
    xspecies_list = (/ "C2H6","CH4" /)
    mw_out = (/30.6, 16/)
    units = (/"Tg/yr","Tg/yr"/)

    archdir = "/Users/mabdioskouei/GFDL_METHANE/model_output/emission/emissions.1x1.2000.w_wetchimp_20perch4/"

    months = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
    imons = ispan(1,12,1)
    nmons = dimsizes(imons)
    daypm = (/31.,28.,31.,30.,31.,30.,31.,31.,30.,31.,30.,31 /)
    sec_per_mon = 86400. * daypm(:)

    pi = 4.*atan(1.)
    d2r = pi/180.
    rearth = 6371220 ; m
    g_to_kg = 1.e-3
    cm2_to_m2 = 1.e-4
    navo = 6.02214e23  ; molecules/mole



;;---Open and read emission file
    iyear = 0

    ;do i_spc =0,dimsizes(xspecies_list)-1
    do i_spc=1,1
        xspecies = xspecies_list (i_spc)
        fact =  mw_out(i_spc) / navo / cm2_to_m2
 
        do isource = 0, nsource - 1
            source = source_list(isource)
            filename = archdir+"/emissions."+str_lower(xspecies)+"."+res+"."+xyear(iyear)+".nc"
            varname = source
            fin = addfile(filename,"r")
            if(isfilevar(fin,source)) then
                emission = fin->$varname$ ; molec/cm2/s 
            else
                continue
            end if
            if (isdouble(emission)) then
                emis1 = doubletofloat(emission)
            else
                emis1 = emission
            end if
            copy_VarCoords(emission,emis1)

            if (iyear .eq. 0) then
                lat = fin->lat
                lon = fin->lon
                nlat = dimsizes(lat)
                nlon = dimsizes(lon)
                latb = new(nlat+1,"float")
                latb(1:nlat-1) = 0.5 * (lat(0:nlat-2)+lat(1:nlat-1))
                latb(0) = -90.
                latb(nlat) = 90.
                area = lat
                area = sin(latb(1:nlat)*d2r) - sin(latb(0:nlat-1)*d2r)
                area = 2 * pi * rearth^2 * area / nlon ; m^2 
            end if

            emis = emis1
            delete(emis1)
            seas_emis = emis
            seas_emis = seas_emis(:,:,:) * fact * conform(seas_emis,sec_per_mon,0) ; g/m2/month 
            yearly_emis = new((/nlat,nlon/),float)
            yearly_emis(:,:) = dim_sum_Wrap(seas_emis(lat|:,lon|:,time|:))  ; g/m2

            if (xspecies_list (i_spc).eq."C2H6") then
                yearly_emis@units = "gC2H6/m2"
            else if (xspecies_list (i_spc).eq."CH4") then
                yearly_emis@units = "gCH4/m2"
            end if
            end if  

            emis1 = seas_emis
            emis1 = seas_emis * conform(emis1,area,1) * 1.e-12 ; Tg/mon
; Calculate emission total 
            emis_total = sum(emis1(:,:,:))

;;----Plot resources
            plot_type = "pdf"
            plot_name = "emission_"+xspecies_list (i_spc)+"_"+source
            wks = gsn_open_wks (plot_type,plot_name)
            gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
            ;gsn_reverse_colormap(wks)
            mpres  =  True
            mpres@gsnMaximize = True
            mpres@cnFillOn = True
            mpres@cnLinesOn = False

            mpres@cnLevelSelectionMode = "ExplicitLevels"     ; set explicit contours
;            mpres@lbLabelBarOn = False
;            mpres@cnLineLabelsOn = False
;            mpres@cnInfoLabelOn = False
;            mpres@mpFillOn = False
            mpres@lbLabelFontHeightF = 0.018
            if (xspecies_list (i_spc).eq."C2H6") then
                mpres@cnLevels = (/0,0.001,0.002,0.003,0.004,0.005,0.05,0.1,1.,5.,10.,20.,40.,75.,100./)
            else if (xspecies_list (i_spc).eq."CH4") then
                mpres@cnLevels = (/0,0.005,0.05,0.1,1.,5.,10.,20.,40.,75.,100./)
            end if
            end if  



;            mpres@cnLevels = fspan (0,0.5,10) 

;            mpres@lbLabelBarOn = False
;            mpres@cnLineLabelsOn = False
;            mpres@cnInfoLabelOn = False
;            mpres@mpFillOn = False
            mpres@lbLabelFontHeightF = 0.018

            mpres@gsnCenterString = xspecies_list (i_spc) +" "+source 
            mpres@gsnLeftString = sprintf("%5.2f",emis_total)+ " Tgyr~S~-1~N~"
            plot = gsn_csm_contour_map_ce(wks,yearly_emis(:,:),mpres)
            delete(mpres)
        end do ;;isource
    end do ;;i_spc 
end
