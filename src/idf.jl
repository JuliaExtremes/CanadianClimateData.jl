idf_version = "idf_v3-30_2022_10_31"

repo_url = "https://collaboration.cmc.ec.gc.ca/cmc/climate/Engineer_Climate/IDF/"*idf_version*"/IDF_Files_Fichiers/"

prov_list = ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"]

"""
    idf_zip_download(province::String ; dir::String=pwd())

Download the ZIP files of the IDF of the province `province` in `dir`.
"""
function idf_zip_download(province::String ; dir::String="")
    @assert province ∈ prov_list "The provided province $province is not valid."

    if isempty(dir)
        dir = mktempdir()
    end

    zip_remote_filename = "$(province).zip"

    zip_remote_path = string(repo_url, zip_remote_filename)

    zip_local_path = joinpath(dirname(@__FILE__), dir, zip_remote_filename)

    Downloads.download(zip_remote_path, zip_local_path)

    return zip_local_path

end

"""
    idf_unzip(zip_path::String)

Unzip only the text files contained in the archive.

!!! note "Hourly records"
    This function works only for Unix and Mac users. For Windows users, the ZIP file should be unzipped externally.

See also: [`idf_zip_download`](@ref)
"""
function idf_unzip(zip_path::String, output_dir::String="")

    if isempty(output_dir)
        output_dir = splitext(zip_path)[1]
    end

    run(`unzip -j $zip_path '*.txt' -d $output_dir`)

    return output_dir
end

function idf_list(unzipped_folder_path::String)

    filenames = readdir(unzipped_folder_path)

    # Extract only the text files
    filter!(x->endswith(x, ".txt"), filenames)
    filter!(x->contains(x, idf_version), filenames)

    @assert !isempty(filenames) "The provided folder $unzipped_folder_path does not contain any IDF text file."

    return filenames

end

"""
    read_idf_station_info(idf_txt_file_path::String)

Read the station information from an ECCC-style text file located at `idf_txt_file_path``.

## Details

The function returns a tuple containing in order the station's:
    - Name
    - Province
    - Climate ID
    - Latitude
    - Longitude
    - Elevation 
"""
function read_idf_station_info(idf_txt_file_path::String)
    @assert isfile(idf_txt_file_path) 

    f = open(idf_txt_file_path, "r")
        lines = readlines(f)
    close(f)

    Name = strip(lines[14][1:50])
    Province = strip(lines[14][55:59])
    ClimateID = strip(lines[14][60:end])

    stripchar = (s, r) -> replace(s, Regex("[$r]") => "")    # to remove ' from lat/lon

    lat_degree = parse(Int32, stripchar(lines[16][12:14],"'"))
    lat_minute = parse(Int32, stripchar(lines[16][15:17],"'"))

    lat = round(lat_degree + lat_minute/60, digits=2)

    lon_degree = parse(Int32, stripchar(lines[16][34:37],"'"))
    if lon_degree ≥ 100
        lon_minute = parse(Int32, stripchar(lines[16][38:40],"'"))
    else
        lon_minute = parse(Int32, stripchar(lines[16][37:39],"'"))
    end

    lon = - round(lon_degree + lon_minute/60, digits=2)

    elevation = parse(Int32, lines[16][65:69])

    return Name, Province, ClimateID, lat, lon, elevation

end

"""
    read_idf_data(idf_txt_file_path::String)

Read the IDF data from an ECCC-style text file located at `idf_txt_file_path``.
"""
function read_idf_data(idf_txt_file_path::String)
    @assert isfile(idf_txt_file_path) 

    f = open(idf_txt_file_path, "r")
        lines = readlines(f)
    close(f)

    slines = strip.(lines)

    data_header_line = findfirst(slines .== "Ann\xe9e")
    data_bottom_line = findfirst(slines .== repeat("-",69))

    n = data_bottom_line - data_header_line - 1
    M = Matrix{Float64}(undef, n, 10)

    i = 1
    for line in slines[(data_header_line+1):(data_bottom_line-1)]
        M[i,:] = parse.(Float64, split(line))
        i+=1
    end

    M = replace(M, -99.9 => missing)

    colnames = ["Year","5min","10min","15min","30min","1h","2h","6h","12h","24h"]

    df = DataFrame(M, colnames)

    df.Year = Int64.(df.Year)

    return df

end

"""
    filter_idf_inventory(df::DataFrame; Name::String = "", ClimateID::String = "", StationID::String="")

Filter the idf inventory DataFrame `df` by station `Name` and/or `ClimateID`.
"""
function filter_idf_inventory(df::DataFrame ; Name::String="", ClimateID::String="", StationID::String="")
    @assert any([!isempty(Name),!isempty(ClimateID)]) "At least one station characteristic between `Name` and `ClimateID` must be provided."

    idf_df_line = deepcopy(df)

    if !isempty(Name)
        filter!(row->row.Name == Name, idf_df_line)
    end

    if !isempty(ClimateID)
        filter!(row->row."ClimateID" == ClimateID, idf_df_line)
    end

    return idf_df_line

end


## NetCDF functionalities

"""
    netcdf_generator(fileName::String)

Generates an empty NetCDF file named `fileName`, tailored to contain IDF data.
"""
function netcdf_generator(fileName::String)
    @assert splitext(fileName)[2]==".nc" "Filename does not end with the `nc` extension : $fileName"
    # Creation of an empty NetCDF :
    ds = Dataset(fileName, "c")

    # Content definition :
    # Dimensions
    defDim(ds, "station", Inf)
    defDim(ds, "obs", Inf)
    defDim(ds, "name_strlen", Inf)
    defDim(ds, "id_strlen", Inf)

    # Global attributes
    ds.attrib["featureType"] = "timeSeries"
    ds.attrib["title"] = "Short Duration Rainfall Intensity-Duration-Frequency Data (ECCC)"
    ds.attrib["Conventions"] = "CF-1.7"
    ds.attrib["comment"] = "see H.2.4. Contiguous ragged array representation of time series"

    # Variables
    v1 = defVar(ds, "lon", Float32, ("station",))
    v1.attrib["standard_name"] = "longitude"
    v1.attrib["long_name"] = "station longitude"
    v1.attrib["units"] = "degrees_east"

    v2 = defVar(ds, "lat", Float32, ("station",))
    v2.attrib["standard_name"] = "latitude"
    v2.attrib["long_name"] = "station latitude"
    v2.attrib["units"] = "degrees_north"

    v3 = defVar(ds, "alt", Float32, ("station",))
    v3.attrib["long_name"] = "vertical distance above the surface"
    v3.attrib["standard_name"] = "height"
    v3.attrib["units"] = "m"
    v3.attrib["positive"] = "up"
    v3.attrib["axis"] = "Z"

    v4 = defVar(ds, "station_name", Char, ("station", "name_strlen"))
    v4.attrib["long_name"] = "station name"

    v5 = defVar(ds, "station_ID", Char, ("station", "id_strlen"))
    v5.attrib["long_name"] = "station id"
    v5.attrib["cf_role"] = "timeseries_id"

    v6 = defVar(ds, "row_size", Int32, ("station",))
    v6.attrib["long_name"] = "number of observations for this station"
    v6.attrib["sample_dimension"] = "obs"

    v7 = defVar(ds, "time", Float64, ("obs",))
    v7.attrib["standard_name"] = "time"
    v7.attrib["units"] = "days since 1900-01-01"

    v8 = defVar(ds, "max_rainfall_amount_5min", Float32, ("obs",))
    v8.attrib["long_name"] = "Annual maximum rainfall amount 5-minutes"
    v8.attrib["coordinates"] = "time lat lon alt station_ID"
    v8.attrib["cell_methods"] = "time: sum over 5 min time: maximum within years"
    v8.attrib["units"] = "mm"

    v9 = defVar(ds, "max_rainfall_amount_10min", Float32, ("obs",))
    v9.attrib["long_name"] = "Annual maximum rainfall amount 10-minutes"
    v9.attrib["coordinates"] = "time lat lon alt station_ID"
    v9.attrib["cell_methods"] = "time: sum over 10 min time: maximum within years"
    v9.attrib["units"] = "mm"

    v10 = defVar(ds, "max_rainfall_amount_15min", Float32, ("obs",))
    v10.attrib["long_name"] = "Annual maximum rainfall amount 15-minutes"
    v10.attrib["coordinates"] = "time lat lon alt station_ID"
    v10.attrib["cell_methods"] = "time: sum over 15 min time: maximum within years"
    v10.attrib["units"] = "mm"

    v11 = defVar(ds, "max_rainfall_amount_30min", Float32, ("obs",))
    v11.attrib["long_name"] = "Annual maximum rainfall amount 30-minutes"
    v11.attrib["coordinates"] = "time lat lon alt station_ID"
    v11.attrib["cell_methods"] = "time: sum over 30 min time: maximum within years"
    v11.attrib["units"] = "mm"

    v12 = defVar(ds, "max_rainfall_amount_1h", Float32, ("obs",))
    v12.attrib["long_name"] = "Annual maximum rainfall amount 1-hour"
    v12.attrib["coordinates"] = "time lat lon alt station_ID"
    v12.attrib["cell_methods"] = "time: sum over 1 hour time: maximum within years"
    v12.attrib["units"] = "mm"

    v13 = defVar(ds, "max_rainfall_amount_2h", Float32, ("obs",))
    v13.attrib["long_name"] = "Annual maximum rainfall amount 2-hours"
    v13.attrib["coordinates"] = "time lat lon alt station_ID"
    v13.attrib["cell_methods"] = "time: sum over 2 hour time: maximum within years"
    v13.attrib["units"] = "mm"

    v14 = defVar(ds, "max_rainfall_amount_6h", Float32, ("obs",))
    v14.attrib["long_name"] = "Annual maximum rainfall amount 6-hours"
    v14.attrib["coordinates"] = "time lat lon alt station_ID"
    v14.attrib["cell_methods"] = "time: sum over 6 hours time: maximum within years"
    v14.attrib["units"] = "mm"

    v15 = defVar(ds, "max_rainfall_amount_12h", Float32, ("obs",))
    v15.attrib["long_name"] = "Annual maximum rainfall amount 12-hours"
    v15.attrib["coordinates"] = "time lat lon alt station_ID"
    v15.attrib["cell_methods"] = "time: sum over 12 hours time: maximum within years"
    v15.attrib["units"] = "mm"

    v16 = defVar(ds, "max_rainfall_amount_24h", Float32, ("obs",))
    v16.attrib["long_name"] = "Annual maximum rainfall amount 24-hours"
    v16.attrib["coordinates"] = "time lat lon alt station_ID"
    v16.attrib["cell_methods"] = "time: sum over 24 hours time: maximum within years"
    v16.attrib["units"] = "mm"

    close(ds)
end

"""
    idf2netcdf(idf_txt_file_path::String, nc_dir::String = pwd())

Converts the IDF text file at `idf_txt_file_path` into a NetCDF file saved in the directory `nc_dir`.
"""
function idf2netcdf(idf_txt_file_path::String, nc_dir::String=pwd())
    @assert isdir(nc_dir)

    # Read IDF station info
    Name, Province, ClimateID, lat, lon, elevation = CanadianClimateData.read_idf_station_info(idf_txt_file_path)

    #Read IDF data
    data = CanadianClimateData.read_idf_data(idf_txt_file_path)

    # Generate an empty NetCDF
    filename, _ = splitext(basename(idf_txt_file_path))
    nc_filepath = joinpath(@__FILE__, nc_dir, filename * ".nc")
    netcdf_generator(nc_filepath)

    # Append data to the empty NetCDF
    ds = Dataset(nc_filepath, "a")
    ds.attrib["original_source"] = basename(idf_txt_file_path)

    # Station infos :
    ds["lat"][1] = lat
    ds["lon"][1] = lon
    ds["alt"][1] = elevation
    ds["station_ID"][1, 1:length(ClimateID)] = collect(ClimateID)
    ds["station_name"][1, 1:length(Name)] = collect(Name)

    # Number of observations :
    nb_obs = nrow(data)
    ds["row_size"][1] = nb_obs

    # Time :
    t = DateTime.(data[:, 1], 1, 1) # Convert years to Date format
    units = "days since 1900-01-01 00:00:00"
    timedata = NCDatasets.CFTime.timeencode(t, "days since 1900-01-01 00:00:00", "standard")    # Encode Dates in days since format
    ds["time"][1:nb_obs] = timedata

    # Data from table 1 :
    ds["max_rainfall_amount_5min"][1:nb_obs] = Float32.(coalesce.(data[:, "5min"], NaN))
    ds["max_rainfall_amount_10min"][1:nb_obs] = Float32.(coalesce.(data[:, "10min"], NaN))
    ds["max_rainfall_amount_15min"][1:nb_obs] = Float32.(coalesce.(data[:, "15min"], NaN))
    ds["max_rainfall_amount_30min"][1:nb_obs] = Float32.(coalesce.(data[:, "30min"], NaN))
    ds["max_rainfall_amount_1h"][1:nb_obs] = Float32.(coalesce.(data[:, "1h"], NaN))
    ds["max_rainfall_amount_2h"][1:nb_obs] = Float32.(coalesce.(data[:, "2h"], NaN))
    ds["max_rainfall_amount_6h"][1:nb_obs] = Float32.(coalesce.(data[:, "6h"], NaN))
    ds["max_rainfall_amount_12h"][1:nb_obs] = Float32.(coalesce.(data[:, "12h"], NaN))
    ds["max_rainfall_amount_24h"][1:nb_obs] = Float32.(coalesce.(data[:, "24h"], NaN))

    close(ds)
end