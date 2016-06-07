;_________________________________________________________________________
; Purpose: 
;      Read information on station codes and locations for the GMD network
; 
; Modification History
;      Created on August 21, 2014, V. Naik
;_________________________________________________________________________

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "/home/van/ncl_scripts/shea_util.ncl"


undef("get_gmdstationinfo")
function getgmdstationinfo (station_list:string)

local infile, nfields, delimiter, var_names, read_data, header, \
     data, nrows, station_info
begin

infile = station_list

;if (isfilepresent(infile))
;  print("getgmdstationinfo: Reading station list")
;else 
;  print("getgmdstationinfo: Need station list to proceed further")
;  exit
;end if

nfields   = 7                         ; # of fields
delimiter = ","                       ; field delimiter
var_names   = new(nfields,string)

; Read ascii station list file
read_data = asciiread(infile,-1,"string")
header = read_data(0)
data   = read_data(1:)       ; Get rid of first line which is a header.
nrows  = dimsizes(data)      ; Number of rows.
nfields   = str_fields_count(header,delimiter)
station_info = new((/nfields,nrows/),string)

do i=0,nfields-1
    var_names(i) = str_get_field(header,i+1,delimiter)
    print(var_names(i)+" ")
    if (var_names(i) .eq. "Code ") then
      station_info(0,:) = str_right_strip(str_get_field(data,i+1,delimiter))
    else if (var_names(i) .eq. "Latitude ") then
      station_info(1,:) = str_get_field(data,i+1,delimiter)
    else if (var_names(i) .eq. "Longitude ") then
      station_info(2,:) = str_get_field(data,i+1,delimiter)
    else if (var_names(i) .eq. "Elevation (meters) ") then
      station_info(3,:) = str_get_field(data,i+1,delimiter)
    else if (var_names(i) .eq. "Name ") then
      station_info(4,:) = str_get_field(data,i+1,",")
    else if (var_names(i) .eq. "Country ") then
      station_info(5,:) = str_get_field(data,i+1,",")
    else if (var_names(i) .eq. "State") then
      station_info(6,:) = str_get_field(data,i+1,",")
    end if
    end if
    end if
    end if
    end if
    end if
    end if    
end do
return(station_info)


end

