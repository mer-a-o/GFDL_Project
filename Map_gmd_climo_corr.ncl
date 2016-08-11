
;_________________________________________________________________________
; Purpose: 
;   Calculate the correlation btw GMD stations (climo) and model (climo)
;   plots map of station locations colored by correlation values
;
;
; Modification History
;      Created on July 16, 2015, V. Naik
;      Modified on June 2015, MAO 
;________________________________________________________________________

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./getgmdstationinfo.ncl"


begin

;-- Define constants
    mw_air = 28.966  ; g/mole
    mw_h2o = 18.01528 ; g/mole
    pref = 1013.246  ; mbar  reference pressure
    tref = 288.15    ; K  reference temperature
    lapserate = 0.0065   ; K/m  lapse rate
    x = 0.190284     ; R gamma/g  (dry air)

    ; Specify species for we need plots
    species = (/"ch4"/)
    species_list = (/"Methane"/)    
    nspecies = dimsizes(species)

    ; Specify directories
    ;datadir = "/net2/van/obs_data/GMD/"
    ;workdir = "/net/van/obs_data/surface_gmd/"
;    datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/climatology_1988_2012/"
    datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ch4_flask_surface/climatology_199601-200512/"
;    obsdir_gmd        = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ncdf/"
    modeldir_conc     = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4conc_newinitcond/"
    modeldir_emis     = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4emis_newinitcond/"
    modeldir_emis30per     = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_30percentch4emis_newinitcond/"
    modeldir_emis40per = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_40percentch4emis_newinitcond/"
    
    workdir           = "./"

    station_file = workdir+"gmd_station_list.csv"

    ; run_mode = "conc"
      run_mode = "emis"
;;;*******************************************************
;; READ OBS
;;;*******************************************************
; Read stationinfo
    station_info = getgmdstationinfo(station_file)
    stationcode  = station_info(0,:)
    stationlat   = stringtofloat(station_info(1,:))
    stationlon   = stringtofloat(station_info(2,:))
    stationalt   = stringtofloat(station_info(3,:))
    stationname  = station_info(4,:)
    country      = station_info(5,:)
    nsites       = dimsizes(stationcode)
    stationlonforplot = stationlon
    stationlon   = where(stationlon.lt.0, stationlon+360., stationlon)
    stationstring = stationcode+","+stationname+","+sprintf("%4.1f",stationlat)+","+sprintf("%5.1f",stationlonforplot)+","+sprintf("%5.1f",stationalt)+"m"
print("nsites = " + nsites)
    ssites = stationcode
    nssites = dimsizes(ssites)
    site_indices = get1Dindex(stationcode,str_upper(ssites))

do sp = 0, nspecies-1
    xsp = species(sp)
; Define filenames and arrays to hold obs data
;    fsuff = "_surface_climo_1988_2012.nc"
    fsuff = "_surface_climo_199601-200512.nc"
    
    indir = datadir_climo
    infile = indir+xsp+"_"+str_lower(stationcode)+fsuff
    datacounter = new((/nssites,12/),integer)

;;---Get the index for sites with data    
    site_avail_counter := 0 
    do s1 = 0, nssites - 1
        if (isfilepresent(infile(site_indices(s1)))) then
            site_avail_counter := site_avail_counter+1
        end if
    end do ;s1
print ("# of sites w/ data"+site_avail_counter)

    site_ind = new (site_avail_counter,integer) ;;holds the ind of sites w data
    
    sitelat_plot = new (site_avail_counter,float)
    sitelon_plot = new (site_avail_counter,float)
    
    climoconc = new((/site_avail_counter,12/),float)
    climoconc!0 = "station"
    climoconc!1 = "time"
    
    site_avail_counter := 0

    do s = 0, nssites - 1
      site = stationcode(site_indices(s))
      if (isfilepresent(infile(site_indices(s)))) then
        obsin = addfile(infile(site_indices(s)),"r")
        climoconc(site_avail_counter,:) = (/obsin->$xsp$/)
        datacounter(s,:) = (/obsin->counter(:)/)
        site_ind (site_avail_counter) = s
        sitelat_plot(site_avail_counter) = stationlat(s)
        sitelon_plot(site_avail_counter) = stationlon(s)
        site_avail_counter := site_avail_counter+1
      end if
    end do  ;;s
    climoconc@_FillValue = -999.99   ; specifies the value of missing data
    datacounter@_FillValue = -999
;print(site_ind)
;print(stationlat(site_ind))
;print(sitelat_plot)

;; READ MODEL
;;;*******************************************************
    user = "van"
    version    = "/awg/ulm_201505/"
    ;experiment   = "c96L48_am4g7_fullchem_lnox_rcp85"
    platform   = "/gfdl.ncrc3-intel15-prod-openmp/"
    experiment  = "test_runs"

    mod_mode = (/"conc","emis20","emis30","emis40"/)
    num_mode = dimsizes(mod_mode)
   ; plotvar = new((/3,nssites,12/),float)  ;;[conc, emis, obs]
    correlation = new((/num_mode,site_avail_counter/),float) ; conc, emis20 emis40
    correlation@_FillValue = -999.
    meanbias = new((/num_mode,site_avail_counter/),float)
    meanbias@_FillValue = -999.

    do i_mode=0, num_mode-1
        if (i_mode.eq.0)then
          modeldir = modeldir_conc
          print ("MODE = ch4conc")
        else if (i_mode.eq.1)then
          modeldir = modeldir_emis
          print ("MODE = ch4emis20")
        else if (i_mode.eq.2) then  
          modeldir = modeldir_emis30per
          print("MODE = ch4emis30")
        else if (i_mode.eq.3) then  
          modeldir = modeldir_emis40per
          print("MODE = ch4emis40")

        end if
        end if 
        end if
        end if 

        ;staticfile = "/archive/"+user+version+experiment+platform+"pp/tracer_level/tracer_level.static.nc"
        staticfile = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4conc/tracer_level.static.nc"

        static = addfile(staticfile,"r")
        mod_lat = static->lat
        mod_lon = static->lon
        bk = static->bk
        pk = static->pk
        npedge = dimsizes(static->phalf)
        npfull = npedge - 1
        fils := systemfunc ("ls "+modeldir+"tracer_level.*.nc")
        fin := addfiles(fils, "r")   ; note the "s" of addfile
        ListSetType(fin, "cat")

        pfull := fin[0]->pfull
        sfclev := dimsizes(pfull)-1
        sfcpfull := pfull(sfclev)

        time := fin[:]->time
        modelconc := fin[:]->$str_upper(xsp)$
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


        copy_VarCoords(modelconc,model_alt)
; Bilinear interpolation of model results at station lat and lon; need to interpolate altitude
; as well to derive vertical level at the site particularly if the stationlon is less than min(mod_lon).
; First encountered this problem when comparing against EMEP data.  
        modelconcatsite := linint2_points_Wrap(modlon,modlat,modelconc,True,stationlon(site_ind),stationlat(site_ind),0) ;;[time x pfull x stn]
        modelaltatsite = linint2_points_Wrap(modlon,modlat,model_alt,True,stationlon(site_ind),stationlat(site_ind),0)
        modelsphumatsite := linint2_points_Wrap(modlon,modlat,modelsphum,True,stationlon(site_ind),stationlat(site_ind),0)

        modconcatsite = new((/site_avail_counter,12/),float)
        modconcatsite!0 = "station"
        modconcatsite!1 = "time"
; Find the pressure level nearest to station altitude - not using annual mean pressure as pressure 
; changes from month-to-month
;        print (modelaltatsite)
        do m = 0, 11
            do st = 0, site_avail_counter - 1
                if (.not.ismissing(modelaltatsite(m,npfull-1,st)).and.isfilepresent(infile(site_ind(st)))) then
                  if (stationalt(site_ind(st)) .lt. modelaltatsite(m,npfull-1,st)) then
                    ilev = npfull - 1
                  else
                    ilev = ind_nearest_coord(stationalt(site_ind(st)),modelaltatsite(m,:,st),0)   ; get model altitude nearest to the station altitude
                  end if
            ;      print(" "+stationcode(site_indices(st))+" "+ilev+" ")
                  ;if (st .eq. site_avail_counter-1) then
                   ;print(" "+ilev +" "+ssiteid(site_avail_counter-1))
                  ;end if
                  ;print ("station lat" + stationlat(site_ind(st)))
                  modconcatsite(st,m) = 1000000000*(/modelconcatsite(m,ilev,st)/(1-(modelsphumatsite(m,ilev,st)/(mw_h2o/mw_air)))/)
                else
                  modconcatsite(st,m) = -999.9
                  print("Out of the range"+stationcode(site_ind(st)))
                end if
            end do  ; st
        end do ;;m
        modconcatsite@_FillValue = -999.9
;printMinMax(modconcatsite,0)
; Calculate comparison statistics
;**********************************
        correlation(i_mode,:) = escorc(modconcatsite(station|:,time|:),climoconc(station|:,time|:))
        correlation@_FillValue = -999.
        ;plotvar(i_mode,:,:) = modconcatsite
                         
    end do ;;i_mode
print (modconcatsite)
print(correlation)
;;***********************************
;; Plotting 
;;*********************************
    
    ip_mode =0  ;;0=conc  1=emis20  2=emis40

    do ip_mode = 0, num_mode-1

        plot_type = "pdf"
        plot_name = "plot_Map_gmd_climo_corr_"+xsp+"_"+mod_mode(ip_mode)

        wks = gsn_open_wks (plot_type, plot_name)
        gsn_define_colormap(wks,"BlueRed")
        cmap = gsn_retrieve_colormap(wks)

        arr = fspan(-1.0,1.0,21)
        num_distinct_markers = dimsizes(arr)+1        ; number of distinct markers

        ; Get a nice span of colors through the current color map, but
        ; skip the first three colors (0-2).
        ;

        colors = span_color_indexes(cmap(3:,:),num_distinct_markers+1)
    ;---Set up some map resources.
        mpres              = True
        mpres@gsnMaximize  = True             ; Maximize plot in frame.
        mpres@gsnFrame     = False            ; Don't advance the frame
        mpres@gsnDraw      = False            ; Don't advance the frame
     
        mpres@tiMainString = "Correlation coefficient, GMD stations, model mode  "+mod_mode(ip_mode)
     
        mpres@tmYLLabelFontHeightF = 0.015
        mpres@tmYLMajorOutwardLengthF = -0.00
        mpres@tmYRMajorOutwardLengthF = -0.00
        mpres@tmYLMinorOutwardLengthF = -0.00
        mpres@tmYRMinorOutwardLengthF = -0.00
      
        mpres@tmXBMajorOutwardLengthF = -0.00
        mpres@tmXBMinorOutwardLengthF = -0.00
      
    ;    mpres@cnLinesOn = False
    ;    mpres@cnFillOn = True
    ;    mpres@lbLabelBarOn   = False
    ;    mpres@cnLevelSelectionMode = "ExplicitLevels"     ; set explicit contours
    ;    mpres@cnLineLabelsOn = False
    ;    mpres@cnInfoLabelOn  = False
      
        mpres@mpProjection         = "Robinson"
        mpres@mpPerimOn            = True
        mpres@gsnStringFontHeightF = 0.02

        gsres               = True
        gsres@gsMarkerIndex = 16  ; Use filled dots for markers.
        gsres@gsMarkerSizeF = 0.015
        mkres = True              ; for hollow markers so that each of the colored markers can have an outline
        mkres@gsMarkerIndex = 4   ; hollow dots
        mkres@gsMarkerColor    = "black"
        mkres@gsMarkerSizeF     = 0.015



        lat_new = new((/num_distinct_markers,site_avail_counter/),float,-999)
        lon_new = new((/num_distinct_markers,site_avail_counter/),float,-999)

    ;    mpres@cnLevels = arr
    ;    mpres@cnFillColors = colors

    ;---Group the points according to which range they fall in.
    ;    do m = 0, nmons-1    ; for each month
        do i = 0, num_distinct_markers-1
            if (i.eq.0) then
                indexes = ind(correlation(ip_mode,:).lt.arr(0))
            
            else if (i.eq.num_distinct_markers-1) then
                 indexes = ind(correlation(ip_mode,:).ge.(max(arr)))
            else
            ;if (i.gt.0.and.i.lt.num_distinct_markers-1) then       
                 indexes = ind(correlation(ip_mode,:) .ge.arr(i-1).and.correlation(ip_mode,:).lt.arr(i))
            end if
            end if
    ;print (indexes)
;
; Now that we have the set of indexes whose values fall within 
; the given range, take the corresponding lat/lon values and store
; them, so later we can color this set of markers with the appropriate
; color.
;
            if (.not.any(ismissing(indexes))) then 
                 npts_range = dimsizes(indexes)   ; # of points in this range.
                 lat_new(i,0:npts_range-1) = sitelat_plot(indexes)
                 lon_new(i,0:npts_range-1) = sitelon_plot(indexes)                 
            end if
        
            delete(indexes)            ; Necessary b/c "indexes" may be a different
                                       ; size next time.
        end do ;;i

    ;    mpres@gsnCenterString = mons(m)
    ;    mpres@gsnRightString = "# sites="+ct(m)
        map = gsn_csm_map(wks,mpres)

print (num_distinct_markers)
print(dimsizes(colors))
    ;---Loop through each "bin" and attach the markers to the map.
        do ii = 0, num_distinct_markers-1
            if (.not.ismissing(lat_new(ii,0)))
            print ("Print "+lat_new(ii,:))
                gsres@gsMarkerColor      = colors(ii)
                dumstr = unique_string("marker")
                map@$dumstr$ = gsn_add_polymarker(wks,map,lon_new(ii,:),lat_new(ii,:),gsres)
                holstr = unique_string("marker")  ; for marker (black) outline
                map@$holstr$ = gsn_add_polymarker(wks,map,lon_new(ii,:),lat_new(ii,:),mkres)
             end if
        end do ;;ii
    ;    end do ; m
;printMinMax(lat_new,0)
;printMinMax(correlation,0)
;  Adding Labels
        lbres   = True    
        lbres@vpWidthF           = 0.70
        lbres@vpHeightF          = 0.10
        lbres@lbPerimOn          = False            ; Turn off perimeter.
        lbres@lbOrientation      = "Horizontal"     ; Default is vertical.
        lbres@lbLabelAlignment   = "ExternalEdges"  
        lbres@lbFillColors       = colors(1:)
        lbres@lbMonoFillPattern  = True             ; Fill them all solid.
        lbres@lbLabelFontHeightF = 0.013            ; label font height

        lbid = gsn_create_labelbar(wks,dimsizes(arr)-1,sprintf("%0.1f",arr),lbres)
    ;
    ; Create some annotation resources indicating how we want to
    ; attach the labelbar to the plot. Here, we are using the top center
    ; of the labelbar as the point which we are going to position
    ; it, and then we use amOrthogonalPosF to move it down.
    ;                                                                 
        amres                  = True
        amres@amJust           = "TopCenter"
        amres@amOrthogonalPosF = 0.6    ;Move down, away from the plot
        annoid = gsn_add_annotation(map,lbid,amres)



        draw (map)
        frame (wks)
;print (correlation)
    end do ;;ip_mode
end do;;sp
end ;;begin

