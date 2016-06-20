;_________________________________________________________________________
; Purpose: 
;      Plot a Time Series of All gmd stations data from 1983 to 2014
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
  station_file      = workdir+"gmd_station_list.csv"

;;---Read Station Info
  station_info = getgmdstationinfo(station_file)
  stationcode  = station_info(0,:)
  stationlat   = stringtofloat(station_info(1,:))
  stationlon   = stringtofloat(station_info(2,:))
  stationlonforplot = stationlon
  stationlon   = where(stationlon.lt.0, stationlon+360., stationlon)
  stationalt   = stringtofloat(station_info(3,:))
  stationname  = station_info(4,:)
  country      = station_info(5,:)
  nsites       = dimsizes(stationcode)
  stationstring = stationcode+","+stationname+","+sprintf("%4.1f",stationlat)+","+sprintf("%5.1f",stationlonforplot)+","+sprintf("%5.1f",stationalt)+"m"

  do i_sp=0, nspecies-1







  end do ;;i_sp
end  ;;begin
