# Constants

station_inventory_url = "https://collaboration.cmc.ec.gc.ca/cmc/climate/Get_More_Data_Plus_de_donnees/Station%20Inventory%20EN.csv"

# Station inventory

"""
    download_station_inventory(; dir::String = pwd())

Downloads the ECCC station inventory CSV file to the folder specified by `dir` and returns the full path to the saved file.

## Details

### Arguments
- `dir`: Target directory for the downloaded file. Defaults to the current working directory.

### Returns
- Full path to the downloaded CSV file.

See also: [`load_station_inventory`](@ref), [`read_station_inventory`](@ref).
"""
function download_station_inventory(; dir::String = pwd())
    # Ensure directory exists
    isdir(dir) || mkpath(dir)

    # Define output file path
    filename = joinpath(dir, "Station Inventory EN.csv")

    # Download the file
    Downloads.download(station_inventory_url, filename)

    return filename
end


"""
    load_station_inventory(; dir::String = pwd())

Downloads and reads the ECCC station inventory as a `DataFrame`. The file is saved in the folder specified by `dir`.

## Details

### Arguments
- `dir`: Directory where the file will be downloaded. Defaults to the current working directory.

### Returns
- A `DataFrame` containing the station inventory.

### Examples
```julia-repl
julia> df = CanadianClimateData.load_station_inventory()
```

See also: [`download_station_inventory`](@ref), [`read_station_inventory`](@ref).
"""
function load_station_inventory(; dir::String=pwd())
   
    filename = download_station_inventory(dir=dir)
    
    df = read_station_inventory(filename)
    
    return df
    
end

"""
    read_station_inventory(station_inventory_path::String)

Reads the ECCC station inventory CSV file at `station_inventory_path` and returns it as a `DataFrame`.

## Details 

The function also prints the inventory's last updated timestamp, which is assumed to be on the first line of the file. The actual data is expected to start at line 4.

### Arguments
- `station_inventory_path`: Path to the station inventory CSV file.

### Returns
- A `DataFrame` containing the station inventory data.

See also: [`download_station_inventory`](@ref), [`load_station_inventory`](@ref).
"""
function read_station_inventory(station_inventory_path::String)
    @assert isfile(station_inventory_path) "File does not exist: $station_inventory_path"
    
    header_line = readline(station_inventory_path)
    println("Inventory last updated: $header_line")
    
    df = CSV.read(station_inventory_path, DataFrame; header=4)
    
    return df
end



"""
    select_station(df::DataFrame; Name::String = "", ClimateID::String = "", StationID::String = "")

Selects rows from the station inventory `DataFrame` `df` by one or more of the following identifiers:
- `Name`: the station name (exact match)
- `ClimateID`: the climate ID (string match)
- `StationID`: the station ID (string, parsed as integer)

Returns a filtered `DataFrame` containing only matching rows.

## Notes
- At least one of `Name`, `ClimateID`, or `StationID` must be provided.
"""
function select_station(df::DataFrame; Name::String = "", ClimateID::String = "", StationID::String = "")
    @assert any([!isempty(Name), !isempty(ClimateID), !isempty(StationID)]) "At least one of `Name`, `ClimateID`, or `StationID` must be provided."

    filtered_df = deepcopy(df)

    if !isempty(Name)
        filter!(row -> row.Name == Name, filtered_df)
    end

    if !isempty(ClimateID)
        filter!(row -> row."Climate ID" == ClimateID, filtered_df)
    end

    if !isempty(StationID)
        station_id = try
            parse(Int, StationID)
        catch
            error("`StationID` must be parseable as an integer: got \"$StationID\"")
        end
        filter!(row -> row."Station ID" == station_id, filtered_df)
    end

    return filtered_df
end



# Records retrieval


"""
    fetch_daily_records(; Name::String = "", ClimateID::String = "", StationID::String = "")

Downloads daily climate records for the station identified by `Name`, `ClimateID`, `StationID`, or any combination of these, and returns them as a `DataFrame`.

    ## Details

Station metadata is retrieved from the ECCC station inventory.

### Arguments
- `Name`: Exact name of the station.
- `ClimateID`: Climate ID (e.g., "7025255").
- `StationID`: Station ID (integer or vector of integers). If multiple are provided, the first match is used.

### Returns
- A `DataFrame` containing daily climate records for the specified station.

### Notes
- At least one of `Name`, `ClimateID`, or `StationID` must be provided.
- Data is retrieved from Environment and Climate Change Canada's public archive.
- Some fields may contain missing values depending on data availability.

See also: [`fetch_hourly_records`](@ref), [`load_station_inventory`](@ref), [`select_station`](@ref).
"""
function fetch_daily_records(; Name::String = "", ClimateID::String = "", StationID::String="")
    @assert any([!isempty(Name), !isempty(ClimateID), !isempty(StationID)]) "At least one of `Name`, `ClimateID`, or `StationID` must be provided."

    # Load the station inventory
    df = load_station_inventory(dir = mktempdir())

    # Filter station
    df_line = select_station(df; Name = Name, ClimateID = ClimateID, StationID = StationID)

    @assert nrow(df_line) > 0 "No station matched the provided identifier."

    # Extract metadata
    station_id = df_line."Station ID"[1]
    first_year = df_line."DLY First Year"[1]
    last_year = df_line."DLY Last Year"[1]

    # URL constructor
    function record_url(year)
        "https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=$station_id&Year=$year&Month=1&Day=14&timeframe=2&submit=Download+Data"
    end

    # Download first year to initialize
    data = CSV.read(Downloads.download(record_url(first_year)), DataFrame, delim=',')

    # Append subsequent years
    @showprogress for yr in (first_year+1):last_year
        subdata = CSV.read(Downloads.download(record_url(yr)), DataFrame, delim=',')
        append!(data, subdata; promote = true) end

    return data
end


"""
    fetch_hourly_records(; Name::String = "", ClimateID::String = "", StationID::Union{Int, Vector{Int}} = Int[])

Downloads hourly climate records for the station identified by `Name`, `ClimateID`, or `StationID`, and returns them as a `DataFrame`.

## Details

Station metadata is retrieved from the ECCC station inventory.

!!! note "Hourly records"
    Although ECCC supports hourly downloads, many stations do not actually provide hourly data. In such cases, the returned `DataFrame` may be empty or contain only headers.

### Arguments
- `Name`: Exact name of the station.
- `ClimateID`: Climate ID (e.g., "7025255").
- `StationID`: Station ID (integer or vector of integers). If multiple are provided, the first match is used.

### Returns
- A `DataFrame` containing hourly records for the specified station, possibly empty if no data is available.

See also: [`fetch_daily_records`](@ref), [`load_station_inventory`](@ref), [`select_station`](@ref).
"""
function fetch_hourly_records(; Name::String = "", ClimateID::String = "", StationID::String="")
    @assert any([!isempty(Name), !isempty(ClimateID), !isempty(StationID)]) "At least one of `Name`, `ClimateID`, or `StationID` must be provided."

    df = load_station_inventory(dir = mktempdir())

    df_line = select_station(df; Name = Name, ClimateID = ClimateID, StationID = StationID)

    @assert nrow(df_line) > 0 "No station matched the provided identifier."

    station_id = df_line."Station ID"[1]
    first_year = df_line."HLY First Year"[1]
    last_year = df_line."HLY Last Year"[1]

    @assert !ismissing(first_year) "There is no hourly data available for station ID $station_id."

    # URL constructor
    function record_url(year, month)
        "https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=$station_id&Year=$year&Month=$month&Day=14&timeframe=1&submit=Download+Data"
    end

    # Load structure from first file
    sample_url = record_url(first_year, 1)
    sample_data = CSV.read(Downloads.download(sample_url), DataFrame; dateformat="yyyy-mm-dd HH:MM", delim=",", silencewarnings=true)
    data = similar(sample_data, 0)

    @showprogress for yr in first_year:last_year
        for mo in 1:12
            url = record_url(yr, mo)
            subdata = CSV.read(Downloads.download(url), DataFrame; dateformat="yyyy-mm-dd HH:MM", delim=",", silencewarnings=true)
            append!(data, subdata; promote=true)
        end end

    return data
end

