
# Constants

idf_version = "idf_v3-30_2022_10_31"

repo_url = "https://collaboration.cmc.ec.gc.ca/cmc/climate/Engineer_Climate/IDF/"*idf_version*"/IDF_Files_Fichiers/"

prov_list = ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"]

# Download and extract files

"""
    download_idf_zip(province::String; dir::String = pwd())

Downloads the ZIP file containing IDF data for the given Canadian `province` into the specified directory `dir`.

## Details

## Arguments
- `province`: Two-letter province code (e.g., `"QC"`, `"ON"`). Must be in `prov_list`.
- `dir`: Target directory where the ZIP file will be saved. If empty, the file is downloaded in the current directory.

## Returns
- The full path to the downloaded ZIP file.
"""

function download_idf_zip(province::String; dir::String = pwd())
    @assert province ∈ prov_list "Invalid province code: '$province'."

    # Ensure target directory exists
    isdir(dir) || mkpath(dir)

    zip_filename = "$province.zip"
    zip_url = string(repo_url, zip_filename)
    zip_path = joinpath(dir, zip_filename)

    Downloads.download(zip_url, zip_path)

    return zip_path
end


"""
    unzip_idf_txt(zip_path::String, dir::String = pwd())

Unzips only the `.txt` files from the IDF ZIP archive located at `zip_path`. The files are extracted to `dir`.

## Details

If `dir` is not provided, it defaults to a folder named after the ZIP file (without extension).

### Arguments
- `zip_path`: Path to the IDF ZIP archive.
- `dir`: Optional target directory. If it exists, it will be cleared and recreated.

### Returns
- The full path to the directory containing the unzipped text files.

### Notes
- Only `.txt` files in the archive are extracted.
- This function uses the `unzip` shell command, so it works only on Unix-based systems (Linux/macOS).
- On Windows, unzip the archive manually.

See also: [`download_idf_zip`](@ref)
"""

function unzip_idf_txt(zip_path::String, dir::String = pwd())

    prov_folder, _ = splitext(basename(zip_path))

    target_dir = joinpath(dir, prov_folder)

    # Clear and create target directory
    isdir(target_dir) && rm(target_dir; force = true, recursive = true)
    mkpath(target_dir)

    # Unzip only .txt files into the target directory
    run(`unzip -j $zip_path '*.txt' -d $target_dir`)

    return target_dir
end


"""
    list_idf_txt_files(unzipped_folder_path::String)

Returns a list of `.txt` filenames from the provided `unzipped_folder_path` that match the global `idf_version`.

## Details

### Arguments
- `unzipped_folder_path`: Path to the directory containing unzipped IDF files.

### Returns
- A vector of filenames (strings) that:
    - end with `.txt`, and
    - contain the current `idf_version`.

See also: [`unzip_idf_txt`](@ref)
"""
function list_idf_txt_files(unzipped_folder_path::String)
    filenames = readdir(unzipped_folder_path)

    # Keep only .txt files that match the current IDF version
    filter!(x -> endswith(x, ".txt"), filenames)
    filter!(x -> contains(x, idf_version), filenames)

    @assert !isempty(filenames) "No IDF .txt files matching version '$idf_version' found in folder: $unzipped_folder_path."

    return filenames
end

"""
    select_idf_station(df::DataFrame; Name::String = "", ClimateID::String = "")

Filter the IDF station inventory `DataFrame` `df` by matching `Name`, and/or `ClimateID`.

## Details

###Arguments
- `Name`: Station name (exact match).
- `ClimateID`: Climate ID code (exact match).

### Returns
- A filtered `DataFrame` containing rows that match the provided criteria.

### Notes
- At least one of `Name` or `ClimateID` must be provided.
"""

function select_idf_station(df::DataFrame; Name::String = "", ClimateID::String = "")
    @assert any([!isempty(Name), !isempty(ClimateID)]) "At least one of `Name` or `ClimateID` must be provided."

    result = deepcopy(df)

    if !isempty(Name)
        filter!(row -> row.Name == Name, result)
    end

    if !isempty(ClimateID)
        filter!(row -> row.ClimateID == ClimateID, result)
    end

    return result
end



# Data retrieval


"""
    read_idf_station_metadata(idf_txt_file_path::String)

Reads station metadata from an ECCC-style IDF `.txt` file.

## Details 

### Arguments
- `idf_txt_file_path`: Path to the IDF text file.

### Returns
A tuple containing the station’s:
1. Name (`String`)
2. Province (`String`)
3. Climate ID (`String`)
4. Latitude (in decimal degrees, `Float64`)
5. Longitude (in decimal degrees, negative for west, `Float64`)
6. Elevation (in meters, `Int`)

### Notes
- This function assumes the file follows the ECCC IDF text format.
- Latitude and longitude are rounded to 2 decimal places.
"""
function read_idf_station_metadata(idf_txt_file_path::String)
    @assert isfile(idf_txt_file_path) "File not found: $idf_txt_file_path"

    lines = readlines(idf_txt_file_path)

    name      = strip(lines[14][1:50])
    province  = strip(lines[14][55:59])
    climateID = strip(lines[14][60:end])

    stripchar = (s, r) -> replace(s, Regex("[$r]") => "")  # remove unwanted characters like `'`

    lat_deg = parse(Int, stripchar(lines[16][12:14], "'"))
    lat_min = parse(Int, stripchar(lines[16][15:17], "'"))
    latitude = round(lat_deg + lat_min / 60, digits = 2)

    lon_deg = parse(Int, stripchar(lines[16][34:37], "'"))
    if lon_deg ≥ 100
        lon_min = parse(Int, stripchar(lines[16][38:40], "'"))
    else
        lon_min = parse(Int, stripchar(lines[16][37:39], "'"))
    end
    longitude = -round(lon_deg + lon_min / 60, digits = 2)

    elevation = parse(Int, strip(lines[16][65:69]))

    return name, province, climateID, latitude, longitude, elevation
end


"""
    parse_idf_table(idf_txt_file_path::String)

Parses the IDF table from an ECCC-style IDF text file located at `idf_txt_file_path`.

## Details

### Arguments
- `idf_txt_file_path`: Path to the `.txt` file containing IDF data in plain-text format.

### Returns
- A `DataFrame` with the following columns:
  - `Year`, `5min`, `10min`, `15min`, `30min`, `1h`, `2h`, `6h`, `12h`, `24h`
- Missing values (denoted as `-99.9` in the raw file) are converted to `missing`.

### Notes
- Assumes the data block is between the line `"Année"` and a dashed line (`"-"` repeated 69 times).
"""

function parse_idf_table(idf_txt_file_path::String)
    @assert isfile(idf_txt_file_path) "File not found: $idf_txt_file_path"

    lines = readlines(idf_txt_file_path)
    slines = strip.(lines)

    header_line = findfirst(slines .== "Ann\xe9e")
    footer_line = findfirst(slines .== repeat("-", 69))

    @assert !isnothing(header_line) "Header line with 'Ann\xe9e' not found."
    @assert !isnothing(footer_line) "Footer line of dashes not found."

    nrows = footer_line - header_line - 1
    data = Matrix{Float64}(undef, nrows, 10)

    for (i, line) in enumerate(slines[(header_line + 1):(footer_line - 1)])
        data[i, :] = parse.(Float64, split(line))
    end

    replace!(data, -99.9 => missing)

    colnames = ["Year", "5min", "10min", "15min", "30min", "1h", "2h", "6h", "12h", "24h"]
    df = DataFrame(data, colnames)

    df.Year = Int.(df.Year)

    return df
end


## NetCDF functionalities

"""
    create_idf_netcdf(fileName::String)

Generates an empty NetCDF file named `fileName`, tailored to contain IDF data.
"""
function create_idf_netcdf(filename::String)
    @assert endswith(filename, ".nc") "Filename must end with `.nc`: $filename"

    # Create NetCDF dataset (overwrite mode)
    ds = Dataset(filename, "c")

    # Define dimensions
    defDim(ds, "station", Inf)
    defDim(ds, "obs", Inf)
    defDim(ds, "name_strlen", Inf)
    defDim(ds, "id_strlen", Inf)

    # Global attributes
    ds.attrib["featureType"] = "timeSeries"
    ds.attrib["title"] = "Short Duration Rainfall Intensity-Duration-Frequency Data (ECCC)"
    ds.attrib["Conventions"] = "CF-1.7"
    ds.attrib["comment"] = "see H.2.4. Contiguous ragged array representation of time series"

    # Coordinate variables
    defVar(ds, "lon", Float32, ("station",), attrib = Dict(
        "standard_name" => "longitude",
        "long_name" => "station longitude",
        "units" => "degrees_east"))

    defVar(ds, "lat", Float32, ("station",), attrib = Dict(
        "standard_name" => "latitude",
        "long_name" => "station latitude",
        "units" => "degrees_north"))

    defVar(ds, "alt", Float32, ("station",), attrib = Dict(
        "standard_name" => "height",
        "long_name" => "vertical distance above the surface",
        "units" => "m",
        "positive" => "up",
        "axis" => "Z"))

    # Station info
    defVar(ds, "station_name", Char, ("station", "name_strlen"), attrib = Dict(
        "long_name" => "station name"))

    defVar(ds, "station_ID", Char, ("station", "id_strlen"), attrib = Dict(
        "long_name" => "station id",
        "cf_role" => "timeseries_id"))

    defVar(ds, "row_size", Int32, ("station",), attrib = Dict(
        "long_name" => "number of observations for this station",
        "sample_dimension" => "obs"))

    # Time and rainfall variables
    defVar(ds, "time", Float64, ("obs",), attrib = Dict(
        "standard_name" => "time",
        "units" => "days since 1900-01-01"))

    for (dur, mins) in zip(["5min", "10min", "15min", "30min", "1h", "2h", "6h", "12h", "24h"],
                           [5, 10, 15, 30, 60, 120, 360, 720, 1440])
        defVar(ds, "max_rainfall_amount_$(dur)", Float32, ("obs",), attrib = Dict(
            "long_name" => "Annual maximum rainfall amount $(dur)",
            "coordinates" => "time lat lon alt station_ID",
            "cell_methods" => "time: sum over $(mins) min time: maximum within years",
            "units" => "mm"))
    end

    close(ds)
end


"""
    convert_idf_to_netcdf(idf_txt_file_path::String, nc_dir::String = pwd())

Converts an ECCC-style IDF text file (`idf_txt_file_path`) into a NetCDF file and saves it to the specified directory (`nc_dir`).

## Details

### Arguments
- `idf_txt_file_path`: Path to the `.txt` file containing IDF station data and annual maxima.
- `nc_dir`: Output directory for the generated `.nc` file (defaults to the current working directory).

### Behavior
- Extracts station metadata and IDF data.
- Creates a structured NetCDF file using `create_idf_netcdf`.
- Encodes time in CF-compliant format (`days since 1900-01-01`).
- Writes rainfall maxima from 5 min to 24 h durations.
- Overwrites the NetCDF file if it already exists.

### Returns
- Nothing. Writes file to disk.

### See also
- [`create_idf_netcdf`](@ref)
- [`read_idf_station_metadata`](@ref)
- [`parse_idf_table`](@ref)
"""
function convert_idf_to_netcdf(idf_txt_file_path::String, nc_dir::String = pwd())
    @assert isdir(nc_dir)

    # Read station metadata
    Name, Province, ClimateID, lat, lon, elevation = CanadianClimateData.read_idf_station_metadata(idf_txt_file_path)

    # Read IDF data table
    data = CanadianClimateData.parse_idf_table(idf_txt_file_path)

    # Generate NetCDF filename
    filename = splitext(basename(idf_txt_file_path))[1] * ".nc"
    nc_filepath = joinpath(nc_dir, filename)

    # Create an empty NetCDF file
    create_idf_netcdf(nc_filepath)

    # Open the NetCDF file for writing
    ds = Dataset(nc_filepath, "a")
    ds.attrib["original_source"] = basename(idf_txt_file_path)

    # Station info
    ds["lat"][1] = lat
    ds["lon"][1] = lon
    ds["alt"][1] = elevation
    ds["station_ID"][1, 1:length(ClimateID)] = collect(ClimateID)
    ds["station_name"][1, 1:length(Name)] = collect(Name)

    # Number of observations
    nb_obs = nrow(data)
    ds["row_size"][1] = nb_obs

    # Time encoding
    t = DateTime.(data.Year, 1, 1)
    time_encoded = NCDatasets.CFTime.timeencode(t, "days since 1900-01-01 00:00:00", "standard")
    ds["time"][1:nb_obs] = time_encoded

    # Rainfall amounts
    for (dur, colname) in zip(["5min", "10min", "15min", "30min", "1h", "2h", "6h", "12h", "24h"],
                              ["max_rainfall_amount_5min", "max_rainfall_amount_10min", "max_rainfall_amount_15min",
                               "max_rainfall_amount_30min", "max_rainfall_amount_1h", "max_rainfall_amount_2h",
                               "max_rainfall_amount_6h", "max_rainfall_amount_12h", "max_rainfall_amount_24h"])
        ds[colname][1:nb_obs] = Float32.(coalesce.(data[:, dur], NaN))
    end

    close(ds)
end
