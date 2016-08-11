;_________________________________________________________________________
; Purpose: 
;      Compare surface observations of CH4 
;      NOAA ESRL GMD Carbon Cycle Cooperative Global Air Sampling Network
;      with model output
;      CH4 (Y-Axis), Lat (X-Axis)--Panel monthly 
;      against model mean seasonal cycle
;
; Modification History
;      Created on July 2016, MAO
;_________________________________________________________________________


load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./getgmdstationinfo.ncl"


begin

; Define constants
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
    xsp = "ch4"

    ; Specify directories
    ;datadir = "/net2/van/obs_data/GMD/"
    ;workdir = "/net/van/obs_data/surface_gmd/"
    datadir_climo = "/Users/mabdioskouei/GFDL_METHANE/obs_data/climatology_1988_2012/"
    obsdir_gmd        = "/Users/mabdioskouei/GFDL_METHANE/obs_data/ncdf/"
    modeldir_conc = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4conc/"
    modeldir_emis = "/Users/mabdioskouei/GFDL_METHANE/model_output/c96L48_am4g10_fullchem_2000climo_ch4emis/"
    workdir           = "./"

    station_file = workdir+"gmd_station_list.csv"
   
;;----------------------------------------
; Read stationinfo
;;----------------------------------------
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

    ; Subset of sites
    ; Consider the following sites for climatological comparison
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
    site_indices = get1Dindex(stationcode,str_upper(ssites))


    fsuff = "_surface_climo_1988_2012.nc"
    indir = datadir_climo
    infile = indir+xsp+"_"+str_lower(stationcode)+fsuff

    ;fsuff = "_surface-flask_1983_2014.nc"
    ;indir = obsdir_gmd
    ;infile = indir+xsp+"_"+str_lower(stationcode)+fsuff


    obs_climo= new((/nssites,12/),float)
    obs_climo!0 = "station"
    obs_climo!1 = "time"
    datacounter = new((/nssites,12/),integer)

    do s = 0, nssites - 1
      site = stationcode(site_indices(s))
      if (isfilepresent(infile(site_indices(s)))) then
        obsin = addfile(infile(site_indices(s)),"r")
        print(obsin)
        obs_climo(s,:) = (/obsin->$xsp$/)
        datacounter(s,:) = (/obsin->counter(:)/)
      else
         print("Missing file "+infile(s))
         obs_climo(s,:) = -999.99
         datacounter(s,:) = -999
         continue  ; skip this missing file
      end if
    end do

; Define time variable
    imons = ispan(0,11,1)
    mons = (/"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
    nmons = dimsizes(mons)
printVarSummary(stationlat)
printVarSummary(obs_climo(:,0))
;;-------------------------------------------------------------
;; Reading Model Values
;;-------------------------------------------------------------
    user = "van"
    version    = "/awg/ulm_201505/"
    experiment   = "c96L48_am4g10_fullchem_2000climo_ch4"
    platform   = "/gfdl.ncrc3-intel15-prod-openmp/"

    correlation = new((/2,nssites/),float)
    correlation@_FillValue = -999.
    meanbias = new((/2,nssites/),float)
    meanbias@_FillValue = -999.

    model_val = new((/2,nssites,12/),float)  ;;[conc, emis, obs]


    do i_mode = 0,1  ;;conc and emis mode 

        if (i_mode.eq.0)then
            modeldir = modeldir_conc
            print ("MODE = ch4conc")
        else
            modeldir = modeldir_emis
            print ("MODE = ch4emis")
        end if

;staticfile = "/archive/"+user+version+experiment+platform+"pp/tracer_level/tracer_level.static.nc"
        staticfile = modeldir+"tracer_level.static.nc"

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

        printVarSummary(model_alt)

        printVarSummary(modelconc)

        copy_VarCoords(modelconc,model_alt)

        ; Bilinear interpolation of model results at station lat and lon; need to interpolate altitude
        ; as well to derive vertical level at the site particularly if the stationlon is less than min(mod_lon).
        ; First encountered this problem when comparing against EMEP data.  
        modelconcatsite := linint2_points_Wrap(modlon,modlat,modelconc,True,stationlon(site_indices),stationlat(site_indices),0) ;;[time x pfull x stn]
        modelaltatsite = linint2_points_Wrap(modlon,modlat,model_alt,True,stationlon(site_indices),stationlat(site_indices),0)
        modelsphumatsite := linint2_points_Wrap(modlon,modlat,modelsphum,True,stationlon(site_indices),stationlat(site_indices),0)

        modconcatsite = new((/nssites,12/),float)
        modconcatsite!0 = "station"
        modconcatsite!1 = "time"

       do m = 0, 11
          do st = 0, nssites - 2
            if (isfilepresent(infile(site_indices(st)))) then
              if (stationalt(site_indices(st)) .lt. modelaltatsite(m, npfull-1,st)) then
                ilev = npfull - 1
              else
                ilev = ind_nearest_coord(stationalt(site_indices(st)),modelaltatsite(m,:,st),0)   ; get model altitude nearest to the station altitude
              end if
        ;      print(" "+stationcode(site_indices(st))+" "+ilev+" ")
              if (st .eq. nsites-1) then
               print(" "+ilev +" "+ssiteid(nsites-1))
              end if
              modconcatsite(st,m) = 1000000000*(/modelconcatsite(m,ilev,st)/(1-(modelsphumatsite(m,ilev,st)/(mw_h2o/mw_air)))/)
            else
              modconcatsite(st,m) = -999.9
            end if
          end do  ; sites
        end do
        modconcatsite@_FillValue = -999.9
        model_val(i_mode,:,:) = modconcatsite
    end do ;;i_mode



;----------------------------------------------------------------------
;; Plotting
;----------------------------------------------------------------------
    res                       = True

    res@gsnMaximize           = True   ; maximize size of plot in window
;    res@gsnDraw               = False  ; turn off draw
    res@gsnFrame              = False  ; turn off page advance
    res@vpWidthF    = 0.44
    res@vpHeightF   = 0.25
    res@gsnPaperOrientation = "landscape"
  
;;---Y Axis
    res@trYMinF = 1300
    res@trYMaxF = 2000
    res@tiYAxisString = "Surface CH4(ppb)"
    res@tiYAxisFontHeightF = 0.01
    res@tmYLLabelFontHeightF = 0.01

;;--- X Axis 
    res@tiXAxisString = "Lat"
    res@tiXAxisFontHeightF = 0.01
    res@tmXBLabelFontHeightF = 0.01
;;---Markers formant
    res@xyMarkLineMode   = "MarkLines"               ; choose which have markers
    res@xyMarkers         =  (/7,6,16/)                      ; choose type of marker  
    res@xyMarkerColors    = (/"red","green","black"/)   ; Marker color
    res@xyMarkerSizeF     = (/0.01,0.01,0.0005/)                     ; Marker size (default 0.01)
    res@xyMarkerThicknessF = (/3.0,3,1/)
    res@xyLineColors      = (/"red","green","black"/)
    res@xyDashPattern     = 0.
    res@xyLineThicknessF  = (/3,3,3/)
;;---Create legend
    lgres                    = True
    lgres@vpWidthF           = 0.2                   ; width of legend (NDC)
    lgres@vpHeightF          = 0.08                   ; height of legend (NDC)
    lgres@lgPerimOn          = False                 ; turn off perimeter
    lgres@lgMarkerIndexes    = (/7,6,16/)              ; dash indexes
    lgres@lgItemType         = "MarkLines"
    lgres@lgMarkerColors     = (/"red","green","black"/)          ; colors for legend lines
    lgres@lgLineColors       = (/"red","green","black"/)
    lgres@lgDashIndexes      = (/0., 0.,0./)
    lgres@lgOrientation      = "Vertical"
    lgres@lgLabelsOn         = "True"
    lgres@lgAutoManage       = True
    lgres@lgLabelFontHeightF = 0.1
        
;;---Paneling 
    rpanel = True
    rpanel@txFontHeightF = 0.015
    rpanel@gsnFrame = False                ; required for panel plots
    rpanel@gsnMaximize = True
    rpanel@gsnPaperOrientation = "landscape"

    rpanel@gsnPanelLabelBar = False
    rpanel@gsnPanelBottom = 0.02
    rpanel@gsnPanelTop = 0.95

;print(model_val(1,:,8)-model_val(1,:,2))
;print (obs_climo(:,2)-obs_climo(:,10))
    do i_mon=0,11
        plot_type = "x11"
        plot_name = "plot_XY_CH4_lat_gmd_sim_"+mons(i_mon)
        plot = new (12,graphic)
        wks = gsn_open_wks (plot_type, plot_name)
 
        
        var_mat = new((/3,nssites,2/),float)  ;;(mode,ch4,lat) 
    
        var_mat(0,:,0) = model_val(0,:,i_mon) 
        var_mat(1,:,0) = model_val(1,:,i_mon)
        var_mat(2,:,0) = obs_climo(:,i_mon) 
        
        var_mat(0,:,1) = (/stationlat(site_indices)/)
        var_mat(1,:,1) = (/stationlat(site_indices)/)
        var_mat(2,:,1) = (/stationlat(site_indices)/)
        res@tiMainString = "1988-2012 Climo GMD vs. "+experiment+" "+mons(i_mon)
        res@tiMainFontHeightF = 0.01

        plot = gsn_csm_xy(wks,var_mat(:,:,1),var_mat(:,:,0),res)
        gsn_legend_ndc(wks,3,(/"conc","emis","GMD"/),0.5,0.1,lgres)
;;        draw(plot)
        frame (wks)
    end do ;;i_mon

end ;;begn 






