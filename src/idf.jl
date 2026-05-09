
# Constants

idf_version = "idf_v3-40_2025-12-5"

repo_url = "https://collaboration.cmc.ec.gc.ca/cmc/climate/Engineer_Climate/IDF/"*idf_version*".zip"

prov_list = ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"]

# Download and extract files


"""
    download_idf_zip(
        dir::AbstractString=pwd();
        url::AbstractString=repo_url,
        version::AbstractString=idf_version,
        downloader::Function=Downloads.download,
    ) -> String

Download the ZIP archive containing ECCC IDF data into `dir`.

The downloaded file is named according to `version`, with a `.zip` extension.
If `dir` does not exist, it is created.

# Arguments

- `dir::AbstractString=pwd()`: Directory where the ZIP archive is saved.

# Keywords

- `url::AbstractString=repo_url`: URL of the ZIP archive to download.
- `version::AbstractString=idf_version`: IDF data version used to name the
  downloaded file.
- `downloader::Function=Downloads.download`: Function used to download the
  archive. It must accept two arguments, `url` and `path`, where `path` is the
  destination file path. This keyword is mainly useful for testing.

# Returns

- `String`: Path to the downloaded ZIP archive.

# Throws

- `IOError`: If `dir` cannot be created.
- Any error thrown by `downloader`.

# Examples

Download the archive using the default URL and version:

```julia
download_idf_zip("data")
```

Use a fake downloader in tests to avoid downloading the full archive:

```julia
fake_downloader = (url, path) -> write(path, "fake zip content")

zip_path = download_idf_zip(
    tempdir();
    url="https://example.com/fake.zip",
    version="idf_test",
    downloader=fake_downloader,
)
```

See also: [`unzip_idf_txt`](@ref)
"""
function download_idf_zip(
    dir::AbstractString=pwd();
    url::AbstractString=repo_url,
    version::AbstractString=idf_version,
    downloader::Function=Downloads.download,
)
    isdir(dir) || mkpath(dir)

    zip_path = joinpath(dir, string(version, ".zip"))
    downloader(url, zip_path)

    return zip_path
end

"""
    unzip_idf_txt(
        zip_path::AbstractString;
        target_dir::AbstractString="",
        provinces=prov_list,
    ) -> String

Extract the IDF text files from `zip_path`.

If `target_dir` is not provided, the files are extracted to a directory with the
same path as `zip_path`, without the `.zip` extension. If `target_dir` already
exists, it is removed and recreated.

The ECCC IDF archive contains provincial ZIP archives. This function first
extracts those provincial archives, then extracts the `.txt` files from each
province listed in `provinces`.

# Arguments

- `zip_path::AbstractString`: Path to the IDF ZIP archive.

# Keywords

- `target_dir::AbstractString=""`: Directory where the IDF text files are
  extracted. If empty, defaults to `splitext(zip_path)[1]`.
- `provinces=prov_list`: Iterable containing the province or territory codes
  whose ZIP archives should be processed.

# Returns

- `String`: Path to the directory containing the extracted IDF text files.

# Throws

- `ArgumentError`: If `zip_path` is not a file or if an expected provincial ZIP
  archive is missing.
- Any error thrown by `rm`, `mkpath`, or `unzip`.

# Notes

This function uses the external `unzip` command and therefore requires it to be
available on the system.

See also: [`download_idf_zip`](@ref), [`list_idf_txt_files`](@ref)
"""
function unzip_idf_txt(
    zip_path::AbstractString;
    target_dir::AbstractString="",
    provinces=prov_list,
)
    isfile(zip_path) || throw(ArgumentError("ZIP archive not found: $zip_path."))

    target_dir = isempty(target_dir) ? splitext(zip_path)[1] : target_dir

    isdir(target_dir) && rm(target_dir; force=true, recursive=true)
    mkpath(target_dir)

    run(`unzip -j $zip_path "*.zip" -d $target_dir`)

    for prov in provinces
        prov_zip_path = joinpath(target_dir, string(prov, ".zip"))

        isfile(prov_zip_path) || throw(ArgumentError(
            "Expected provincial ZIP archive not found: $prov_zip_path."
        ))

        run(`unzip -j $prov_zip_path "*.txt" -d $target_dir`)
        rm(prov_zip_path)
    end

    return String(target_dir)
end

"""
    list_idf_txt_files(unzipped_folder_path::AbstractString) -> Vector{String}

Return the names of IDF text files in `unzipped_folder_path` matching the
current value of `idf_version`.

A file is retained if its name ends with `.txt` and contains `idf_version`.

# Arguments

- `unzipped_folder_path::AbstractString`: Path to the directory containing the
  extracted IDF text files.

# Returns

- `Vector{String}`: Names of the matching IDF `.txt` files.

# Throws

- `ArgumentError`: If `unzipped_folder_path` is not a directory.
- `ArgumentError`: If no matching IDF text files are found.

See also: [`unzip_idf_txt`](@ref)
"""
function list_idf_txt_files(unzipped_folder_path::AbstractString)
    isdir(unzipped_folder_path) || throw(ArgumentError(
        "Directory not found: $unzipped_folder_path."
    ))

    idf_version_number = idf_version[1:9]

    filenames = filter(readdir(unzipped_folder_path)) do filename
        endswith(filename, ".txt") && contains(filename, idf_version_number)
    end

    isempty(filenames) && throw(ArgumentError(
        "No IDF .txt files matching version '$idf_version' found in folder: $unzipped_folder_path."
    ))

    return filenames
end

"""
    select_idf_station(df::DataFrame; Name::String = "", ID::String = "")

Filter the IDF station inventory `DataFrame` `df` by matching `Name`, and/or `ID`.

## Details

###Arguments
- `Name`: Station name (exact match).
- `ID`: code (exact match).

### Returns
- A filtered `DataFrame` containing rows that match the provided criteria.

### Notes
- At least one of `Name` or `ID` must be provided.
"""
function select_idf_station(df::DataFrame; Name::String = "", ID::String = "")
    @assert any([!isempty(Name), !isempty(ID)]) "At least one of `Name` or `ID` must be provided."

    result = deepcopy(df)

    if !isempty(Name)
        filter!(row -> row.Name == Name, result)
    end

    if !isempty(ID)
        filter!(row -> row.ID == ID, result)
    end

    return result
end



# Data retrieval


"""
    read_idf_station_metadata(idf_txt_file_path::AbstractString) -> NamedTuple

Read station metadata from an ECCC IDF text file.

# Arguments

- `idf_txt_file_path::AbstractString`: Path to the IDF text file.

# Returns

- `NamedTuple`: Station metadata with the following fields:

  - `name::String`: Station name.
  - `province::String`: Province or territory abbreviation.
  - `climate_id::String`: ECCC climate identifier.
  - `latitude::Float64`: Latitude in decimal degrees, rounded to two digits.
  - `longitude::Float64`: Longitude in decimal degrees, rounded to two digits
    and negative for locations west of Greenwich.
  - `elevation::Int`: Station elevation, in metres.

# Throws

- `ArgumentError`: If `idf_txt_file_path` is not a file.
- `ArgumentError`: If the file does not contain the expected metadata lines.

# Notes

This function assumes that the file follows the fixed-width ECCC IDF text
format.
"""
function read_idf_station_metadata(idf_txt_file_path::AbstractString)
    isfile(idf_txt_file_path) || throw(ArgumentError(
        "File not found: $idf_txt_file_path."
    ))

    lines = readlines(idf_txt_file_path)

    length(lines) >= 15 || throw(ArgumentError(
        "Invalid IDF file: expected at least 15 lines, found $(length(lines))."
    ))

    name = strip(lines[13][1:50])
    province = strip(lines[13][55:59])
    climate_id = strip(lines[13][60:end])

    lat_deg = parse(Int, replace(lines[15][12:14], "'" => ""))
    lat_min = parse(Int, replace(lines[15][15:17], "'" => ""))
    latitude = round(lat_deg + lat_min / 60, digits=2)

    lon_deg = parse(Int, replace(lines[15][34:37], "'" => ""))

    lon_min_range = lon_deg >= 100 ? (38:40) : (37:39)
    lon_min = parse(Int, replace(lines[15][lon_min_range], "'" => ""))
    longitude = -round(lon_deg + lon_min / 60, digits=2)

    elevation = parse(Int, strip(lines[15][65:69]))

    return (
        name=name,
        province=province,
        climate_id=climate_id,
        latitude=latitude,
        longitude=longitude,
        elevation=elevation)
end


"""
    parse_idf_table(idf_txt_file_path::AbstractString) -> DataFrame

Parse the annual maximum IDF table from an ECCC IDF text file.

Missing values coded as `-99.9` in the raw file are converted to `missing`.

# Arguments

- `idf_txt_file_path::AbstractString`: Path to the ECCC IDF text file.

# Returns

- `DataFrame`: Annual maximum precipitation table with columns:

  - `Year`
  - `5min`
  - `10min`
  - `15min`
  - `30min`
  - `1h`
  - `2h`
  - `6h`
  - `12h`
  - `24h`

# Throws

- `ArgumentError`: If `idf_txt_file_path` is not a file.
- `ArgumentError`: If the table header or footer cannot be found.
- `ArgumentError`: If a row has an unexpected number of columns.

# Notes

The table is assumed to start after a line equal to `Année` or `Year` and to
end at the first dashed line following the header.
"""
function parse_idf_table(idf_txt_file_path::AbstractString)
    isfile(idf_txt_file_path) || throw(ArgumentError(
        "File not found: $idf_txt_file_path."
    ))

    lines = readlines(idf_txt_file_path)
    slines = strip.(lines)

    header_line = findfirst(line -> startswith(line, "Year  5 min"), slines)

    isnothing(header_line) && throw(ArgumentError(
        "IDF table header line not found. Expected `Year  5 min ...`."
    ))

    footer_line = findnext(line -> startswith(line, "---"), slines, header_line + 1)

    isnothing(footer_line) && throw(ArgumentError(
        "IDF table footer line of dashes not found."
    ))

    table_lines = slines[(header_line + 2):(footer_line - 1)]

    colnames = [
        "Year", "5min", "10min", "15min", "30min",
        "1h", "2h", "6h", "12h", "24h",
    ]

    ncols = length(colnames)
    data = Matrix{Union{Missing, Float64}}(undef, length(table_lines), ncols)

    for (i, line) in enumerate(table_lines)
        values = split(line)

        length(values) == ncols || throw(ArgumentError(
            "Invalid IDF table row $i: expected $ncols columns, found $(length(values))."
        ))

        parsed_values = parse.(Float64, values)
        data[i, :] .= ifelse.(parsed_values .== -99.9, missing, parsed_values)
    end

    df = DataFrame(data, colnames)

    df.Year = Int.(df.Year)

    return df
end


## NetCDF functionalities

"""
    create_idf_netcdf(filename::AbstractString) -> String

Create an empty NetCDF file for storing ECCC IDF station data.

The resulting file uses the CF contiguous ragged array representation for
time series. Stations are stored along the `station` dimension, observations
are stored along the `obs` dimension, and `row_size` gives the number of
observations associated with each station.

# Arguments

- `filename::AbstractString`: Path of the NetCDF file to create. The filename
  must end with `.nc`.

# Returns

- `String`: Path to the created NetCDF file.

# Throws

- `ArgumentError`: If `filename` does not end with `.nc`.
- Any error thrown while creating or writing the NetCDF file.

# Notes

The file is initialized with station metadata variables, coordinate variables,
a time variable, and annual maximum rainfall variables for the standard ECCC
IDF durations.
"""
function create_idf_netcdf(filename::AbstractString)
    endswith(filename, ".nc") || throw(ArgumentError(
        "Filename must end with `.nc`: $filename."
    ))

    durations = [
        "5min" => 5,
        "10min" => 10,
        "15min" => 15,
        "30min" => 30,
        "1h" => 60,
        "2h" => 120,
        "6h" => 360,
        "12h" => 720,
        "24h" => 1440,
    ]

    ds = Dataset(filename, "c")

    try
        # Dimensions
        defDim(ds, "station", Inf)
        defDim(ds, "obs", Inf)
        defDim(ds, "name_strlen", 64)
        defDim(ds, "id_strlen", 32)

        # Global attributes
        ds.attrib["featureType"] = "timeSeries"
        ds.attrib["title"] = "Short Duration Rainfall Intensity-Duration-Frequency Data (ECCC)"
        ds.attrib["Conventions"] = "CF-1.7"
        ds.attrib["comment"] = "CF contiguous ragged array representation of time series."

        # Coordinate variables
        defVar(ds, "lon", Float32, ("station",), attrib=Dict(
            "standard_name" => "longitude",
            "long_name" => "station longitude",
            "units" => "degrees_east",
        ))

        defVar(ds, "lat", Float32, ("station",), attrib=Dict(
            "standard_name" => "latitude",
            "long_name" => "station latitude",
            "units" => "degrees_north",
        ))

        defVar(ds, "alt", Float32, ("station",), attrib=Dict(
            "standard_name" => "height",
            "long_name" => "station elevation above sea level",
            "units" => "m",
            "positive" => "up",
            "axis" => "Z",
        ))

        # Station metadata
        defVar(ds, "station_name", Char, ("station", "name_strlen"), attrib=Dict(
            "long_name" => "station name",
        ))

        defVar(ds, "station_id", Char, ("station", "id_strlen"), attrib=Dict(
            "long_name" => "station identifier",
            "cf_role" => "timeseries_id",
        ))

        defVar(ds, "row_size", Int32, ("station",), attrib=Dict(
            "long_name" => "number of observations for this station",
            "sample_dimension" => "obs",
        ))

        # Time variable
        defVar(ds, "time", Float64, ("obs",), attrib=Dict(
            "standard_name" => "time",
            "long_name" => "time",
            "units" => "days since 1900-01-01",
            "calendar" => "standard",
        ))

        # Annual maximum rainfall variables
        for (duration, minutes) in durations
            defVar(ds, "max_rainfall_amount_$duration", Float32, ("obs",), attrib=Dict(
                "long_name" => "annual maximum rainfall amount for duration $duration",
                "coordinates" => "time lat lon alt station_id",
                "cell_methods" => "time: sum over $minutes minutes time: maximum within years",
                "units" => "mm",
            ))
        end
    finally
        close(ds)
    end

    return String(filename)
end

"""
    convert_idf_to_netcdf(
        idf_txt_file_path::AbstractString,
        nc_dir::AbstractString=pwd(),
    ) -> String

Convert an ECCC IDF text file to a NetCDF file.

The function reads station metadata and annual maximum rainfall amounts from
`idf_txt_file_path`, creates a NetCDF file in `nc_dir`, and writes the data using
the IDF NetCDF schema defined by [`create_idf_netcdf`](@ref).

# Arguments

- `idf_txt_file_path::AbstractString`: Path to the ECCC IDF text file.
- `nc_dir::AbstractString=pwd()`: Directory where the NetCDF file is written.

# Returns

- `String`: Path to the generated NetCDF file.

# Throws

- `ArgumentError`: If `idf_txt_file_path` is not a file.
- Any error thrown by [`read_idf_station_metadata`](@ref),
  [`parse_idf_table`](@ref), [`create_idf_netcdf`](@ref), or `NCDatasets`.

# Notes

The output file has the same basename as `idf_txt_file_path`, with extension
`.nc`. If the output file already exists, it is overwritten by
[`create_idf_netcdf`](@ref).

See also: [`create_idf_netcdf`](@ref), [`read_idf_station_metadata`](@ref),
[`parse_idf_table`](@ref)
"""
function convert_idf_to_netcdf(
    idf_txt_file_path::AbstractString,
    nc_dir::AbstractString=pwd(),
)
    isfile(idf_txt_file_path) || throw(ArgumentError(
        "IDF text file not found: $idf_txt_file_path."
    ))

    isdir(nc_dir) || mkpath(nc_dir)

    metadata = read_idf_station_metadata(idf_txt_file_path)
    data = parse_idf_table(idf_txt_file_path)

    filename = splitext(basename(idf_txt_file_path))[1] * ".nc"
    nc_filepath = joinpath(nc_dir, filename)

    create_idf_netcdf(nc_filepath)

    durations = [
        "5min", "10min", "15min", "30min", "1h",
        "2h", "6h", "12h", "24h",
    ]

    ds = Dataset(nc_filepath, "a")

    try
        ds.attrib["original_source"] = basename(idf_txt_file_path)

        # Station metadata
        ds["lat"][1] = Float32(metadata.latitude)
        ds["lon"][1] = Float32(metadata.longitude)
        ds["alt"][1] = Float32(metadata.elevation)

        station_id = collect(metadata.climate_id)
        station_name = collect(metadata.name)

        ds["station_id"][1, 1:length(station_id)] = station_id
        ds["station_name"][1, 1:length(station_name)] = station_name

        # Number of observations for the station
        nb_obs = nrow(data)
        ds["row_size"][1] = Int32(nb_obs)

        # Time encoding
        dates = [DateTime(year, 1, 1) for year in data.Year]
        time_encoded = NCDatasets.CFTime.timeencode(
            dates,
            "days since 1900-01-01 00:00:00",
            "standard",
        )
        ds["time"][1:nb_obs] = time_encoded

        # Annual maximum rainfall amounts
        for duration in durations
            varname = "max_rainfall_amount_$duration"
            values = coalesce.(data[:, duration], NaN)
            ds[varname][1:nb_obs] = Float32.(values)
        end
    finally
        close(ds)
    end

    return String(nc_filepath)
end