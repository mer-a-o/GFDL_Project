;_________________________________________________________________________
; Purpose: 
;      Compare surface observations of CH4 and CO from the 
;      NOAA ESRL GMD Carbon Cycle Cooperative Global Air Sampling Network
;      with model output
;      Creates station plots of observed and model timeseries 
;
; Modification History
;      Created on Febraury 16, 2015, V. Naik 
;_________________________________________________________________________

  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "./getgmdstationinfo.ncl"

