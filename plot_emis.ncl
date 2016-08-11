; Calculate IPCC AR5 emissions global totals
; Get regional total emissions for HTAP regions


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"



res = "1x1"
scenario = "historical"

source_list = (/"anthro","bb","ship","ch4_wetl","ocean","biogenic"/)
ylabels = (/"Anthro","Biomass Burning","Ships","Wetlands","Ocean","Biogenic"/)
nsource = dimsizes(source_list)

xspecies_list = (/ "C2H6","CH4" /)
mw_out = (/30.6, 16/)
units = (/"Tg/yr","Tg/yr"/)

if (scenario .eq. "historical") then
   xyear = (/2000/)
;   archdir = "/archive/van/fms/INPUT/post_IPCC_AR5/emissions_withch4/historical/2000_1x1.no3dbb.fms/"
;   archdir = "/archive/van/fms/INPUT_post_IPCC_AR5/emiss_for_sims/2000_20perch4/"
;archdir = "/archive/van/fms/INPUT_post_IPCC_AR5/emiss_for_sims_withwetchimpch4/2000_20perch4"
;archdir = "/Users/mabdioskouei/GFDL_METHANE/model_output/emissions.1x1.2000.w_wetchimp_20perch4/"
archdir = "/Users/mabdioskouei/GFDL_METHANE/model_output/emission/emissions.ch4.1x1.2000.base.nc"

end if


; Define some contants
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


;*******************************
; Set up plot
;*******************************

wkstype = "pdf"
wks = gsn_open_wks(wkstype,"ch4_accmip_2000_wetchimp_20perch4")
gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")

r = True                                      ; no plot mods desired
r@gsnFrame = False                              ; required for panel plots
r@gsnDraw = False                               ; required for panel plots
r@cnFillOn = True                             ; turn on color fill
r@cnFillMode = "RasterFill"
r@cnLinesOn = False                             ; turn off contour lines
r@gsnStringFontHeightF = 0.024
r@txFontThicknessF = 2.0

r@cnLevelSelectionMode = "ExplicitLevels"     ; set explicit contours
r@lbLabelBarOn = False
r@cnLineLabelsOn = False
r@cnInfoLabelOn = False
r@mpFillOn = False
r@lbLabelFontHeightF = 0.018

r@tmXBLabelsOn         = True
r@tmXBLabelFontHeightF = 0.017
r@tmXBMajorOutwardLengthF = -0.00
r@tmXBMinorOutwardLengthF = -0.00
r@tmXBLabelStride = 2

r@tmYLLabelsOn = True
r@tmYLLabelFontHeightF = 0.017
r@tmYLMajorOutwardLengthF = -0.00
r@tmYRMajorOutwardLengthF = -0.00
r@tmYLMinorOutwardLengthF = -0.00
r@tmYRMinorOutwardLengthF = -0.00


r@tmYROn = True        ; Turn off right tickmarks.
r@tmYLOn = True
r@tmXTOn = True     ; Turn off top tickmarks
r@tmXBOn = True

rpanel = True
rpanel@txFuncCode    = "~"
rpanel@txFontThicknessF = 2.5
rpanel@gsnPanelLabelBar = True
rpanel@pmLabelBarWidthF = 0.8
rpanel@pmLabelBarHeightF = 0.08
rpanel@lbLabelFontHeightF = 0.015
rpanel@lbLabelFontThicknessF = 2.
;rpanel@lbTitleOn        =  True                ; turn on title
;rpanel@lbTitleString = "10~S~-12~N~ kgm~S~-2~N~s~S~-1~N~"
;rpanel@lbTitlePosition  = "Right"              ; title position
;rpanel@lbTitleFontHeightF= .018             ; make title smaller
;rpanel@lbTitleDirection = "Across"          ; title direction
;rpanel@lbTitleOffsetF = -0.02
;rpanel@lbTitleJust = "CenterRight"
;rpanel@gsnPanelYWhiteSpacePercent = 2.0
rpanel@gsnFrame=False
rpanel@gsnMaximize = True
rpanel@gsnPanelBottom = 0.05
r@cnFillColors = (/201,106,111,114,121,127,132,137,150,155,159,162,165,168,172,174/)
r@cnLevels = (/0.005,0.05,0.1,1.,5.,10.,20.,40.,75.,100.,150.,200.,250./) 


;set up for line plots
rp = True
rp@gsnDraw = False
rp@gsnFrame = False

  
rp@tmXBLabelFontHeightF = 0.016     ; B-X axis font size
rp@tmXBLabelFontThicknessF = 2
rp@tmXBMajorOutwardLengthF = -0.00
rp@tmXBMinorOutwardLengthF = -0.00


rp@tiYAxisFont = "helvetica-bold"
rp@tiYAxisFontHeightF = 0.02
rp@tmYLLabelJust = "CenterRight"   ; right-justify labels
rp@tmYLLabelFontHeightF = 0.02   ; L-Y axis font size
rp@tmYLLabelFontThicknessF = 2


;rp@tmYRLabelFontHeightF = 0.03
rp@tmYLMajorOutwardLengthF = -0.00
rp@tmYRMajorOutwardLengthF = -0.00
rp@tmYLMinorOutwardLengthF = -0.00
rp@tmYRMinorOutwardLengthF = -0.00

rp@tiMainFontHeightF  = 0.02
rp@tiMainFontThicknessF = 2.2

rp@xyLineThicknessF = 4.
rp@xyDashPattern = 0
rp@xyLineColors = (/"black","orange","brown","red","blue","purple"/)

rp@vpWidthF  = 0.55  ; So they can all fit on same page.
rp@vpHeightF = 0.35

; for legend
;r@pmLegendDisplayMode	 = "Always"
rp@pmLegendDisplayMode	 = "NoCreate"
rp@pmLegendSide  	 = "Top"
rp@pmLegendWidthF	 = 0.06
rp@pmLegendHeightF	 = 0.14
rp@lgPerimOn		 = False
rp@lgLabelFontHeightF	 = 0.018
rp@lgLabelFontThicknessF	 = 2.0
rp@pmLegendParallelPosF   = 0.25


rppanel = True
rppanel@txFuncCode    = "~"
rppanel@txFontThicknessF = 2.5
rppanel@gsnFrame=False
rppanel@gsnMaximize = True
rppanel@txFontHeightF = 0.012
;**********************************************************************************

do iyear = 0, dimsizes(xyear) - 1
emis_grand_sum = new(dimsizes(xspecies_list),float)


;do ixspecies = 0,dimsizes(xspecies_list)-1   ; species loop
do ixspecies = 1,1
   xspecies = xspecies_list(ixspecies)
   print(xspecies+" "+xyear(iyear)+"     Totals")
   fact =  mw_out(ixspecies) / navo / cm2_to_m2
   
   emis_avg = new(dimsizes(source_list),float)
   emis_seas = new((/6,12/),float)
   sumsource_total = 0.0
   plot = new(nsource+1,"graphic")
   plot_seas = new(nsource,"graphic")
   lat_dist = new((/nsource,180/),float)

   do isource = 0, nsource - 1
     source = source_list(isource)     
     ;filename = archdir+"/emissions."+str_lower(xspecies)+"."+res+"."+xyear(iyear)+".nc"
     filename = archdir
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
     yearly_emis@units = "gCH4/m2"
 
     emis1 = seas_emis
     emis1 = seas_emis * conform(emis1,area,1) * 1.e-12 ; Tg/mon
     
  
; Calculate emission total 
     emis_total = sum(emis1(:,:,:))
; Lat distribution
    lat_dist(isource,:) = dim_sum_Wrap(dim_sum_Wrap(emis1(lat|:,time|:,lon|:))) ; Tg
   

; Accumulate all sources to plot total emission    
     if (isource .eq. 0) then
       sumsource =  new((/nlat,nlon/),float)   ; accumulates all sources
       sumsource = 0.0
     end if
     sumsource(:,:) = sumsource(:,:) + yearly_emis(:,:)
     sumsource@units = "gCH4/m2"
     sumsource_total = sumsource_total + emis_total
     
     copy_VarCoords(yearly_emis,sumsource)
     r@gsnCenterString = source
     r@gsnLeftString = sprintf("%5.2f",emis_total)+ " Tgyr~S~-1~N~"
     rpanel@txString = "Annual total "+xspecies+ " emissions "+xyear(iyear)
     plot(isource) = gsn_csm_contour_map_ce(wks,yearly_emis(:,:),r)

     print(source+"  "+sprintf("%6.2f",emis_total))
      
; Plot seasonal cycle at different latitude bands
   emis_seas(0,:) =dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,lat|:,lon|:)))
   emis_seas(1,:) =dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|60:90},lon|:)))
   emis_seas(2,:) =dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|30:60},lon|:)))
   emis_seas(3,:) =dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|-90:30},lon|:)))
   emis_seas(4,:) =dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|30:90},lon|:)))
   emis_seas(5,:) =dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|-30:-90},lon|:)))

;    emis_seas(1:,) = dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|60:90},lon|:)))
;    emis_seas(2:,) = dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|30:60},lon|:)))
;    emis_seas(3:,) = dim_sum_Wrap(dim_sum_Wrap(emis1(time|:,{lat|-90:30},lon|:)))

   print(max(emis_seas)+" "+min(emis_seas))

    Region = (/"Global","60-90N","30N-60N","90S-30N","30N-90N","30S-90S"    /)

    do i_print =0,3
print (Region(i_print)+" " +varname+" ="+ sum(emis_seas(i_print,:)))
    end do ;;i_print

   rp@tiYAxisString = ylabels(isource)+" Tg/mo"   
   rp@pmLegendOrthogonalPosF = -0.50
   
   rp@trXMinF = 0        
   rp@trXMaxF = 13
   rp@tmXBMode = "Explicit"
   rp@tmXBMinorPerMajor = 1
   rp@tmXBLabelsOn = True
   rp@tmXBValues = imons
   rp@tmXBLabels = months
   rp@tmXMajorGrid                = True          ; implement x grid
   rp@tmXMajorGridThicknessF      = 0.4           ; 2.0 is default
   rp@tmXMajorGridLineDashPattern = 2             ; select short dash lines
   rp@tmYMajorGrid                = True          ; implement y grid
   rp@tmYMajorGridThicknessF      = 0.4           ; 2.0 is default
   rp@tmYMajorGridLineDashPattern = 2             ; select short dash lines
   if (isource .eq. 0) then
    rp@pmLegendDisplayMode	 = "Always"
    rp@xyExplicitLegendLabels = (/"Global","0-20N","30S-30N","20S-0","30N-90N","30S-90S"/)
   else
    rp@pmLegendDisplayMode	 = "NoCreate"
   end if
   plot_seas(isource) = gsn_csm_xy(wks,imons(:),emis_seas(:,:),rp)
   
   
   delete(seas_emis)
   delete(emis1)  
  end do  ; isource
   rppanel@txString = "Monthly total "+xspecies+ " emissions for "+xyear(iyear)
   gsn_panel(wks,plot_seas,(/3,2/),rppanel)
   frame(wks)
   delete(rp@trXMinF)	
   delete(rp@trXMaxF)     
   delete(rp@tmXBMode)	
   delete(rp@tmXBValues)	
   delete(rp@tmXBLabelsOn)
   delete(rp@tmXBLabels)
   delete(rp@xyExplicitLegendLabels)
   
   rp@pmLegendDisplayMode	 = "Always"
   rp@xyExplicitLegendLabels = ylabels
   rp@tiYAxisString = "Tg/yr"
   rp@trYMinF = -0.5
   plot_lat = gsn_csm_xy(wks,lat_dist&lat,lat_dist,rp)
   rppanel@txString = "Zonal total "+xspecies+" emissions"
   gsn_panel(wks,plot_lat,(/2,2/),rppanel)
   frame(wks)
   delete(rp@trYMinF)
   
   r@gsnCenterString = "Total"
   r@gsnLeftString = 0.01*round(sumsource_total*100.,1) + " Tgyr~S~-1~N~"
   plot(nsource) = gsn_csm_contour_map_ce(wks,sumsource(:,:),r)
     
   gsn_panel(wks,plot,(/4,2/),rpanel)
   delete(sumsource)
   frame(wks)
   delete(rp@xyExplicitLegendLabels)
end do ; (ixspecies)

end do ; (iyear)

