
### Station inventory

"""
    download_station_inventory(; dir::String = "")

Downloads the ECCC station inventory to the folder specified by `dir` and returns its full path.

## Details

- To download the station inventory to the current directory, use `dir=".."`.
- If `dir` is not provided, a temporary folder is created.

See also: [`load_station_inventory`](@ref), [`read_station_inventory`](@ref).
"""
function download_station_inventory(; dir::String="")
   
    if isempty(dir)
        dir = mktempdir()
    end
    
    filename = joinpath(dirname(@__FILE__), dir, string("Station Inventory EN", ".csv"))
        
    station_inventory_url = "https://collaboration.cmc.ec.gc.ca/cmc/climate/Get_More_Data_Plus_de_donnees/Station%20Inventory%20EN.csv"
    
    Downloads.download(station_inventory_url, filename)
    
    return filename
    
end

"""
    load_station_inventory(; dir::String = "")

Downloads the ECCC station inventory to the folder specified by `dir` and reads it as a CSV file.

## Details

- To download the station inventory to the current directory, use `dir=".."`.
- If `dir` is not provided, a temporary folder is created for downloading the file.

# Examples
```julia-repl
julia> CanadianClimateData.download_station_inventory(dir="..")
```

See also: [`download_station_inventory`](@ref), [`read_station_inventory`](@ref).
"""
function load_station_inventory(; dir::String="")
   
    filename = download_station_inventory(dir=dir)
    
    df = read_station_inventory(filename)
    
    return df
    
end

"""
    read_station_inventory(station_inventory_path::String)

Read the station inventory CSV file specified in `station_inventory_path` and return a DataFrame

See also: [`download_station_inventory`](@ref), [`load_station_inventory`](@ref).
"""
function read_station_inventory(station_inventory_path::String)
    @assert isfile(station_inventory_path) "No such file '$station_inventory_path' exists"
   
    s = readline(station_inventory_path)
    
    println(s)
    
    df = CSV.read(station_inventory_path, DataFrame, header=4)
    
    return df
    
end


"""
    filter_station_inventory(df::DataFrame; Name::String = "", ClimateID::String = "", StationID::String="")

Filter the station inventory DataFrame `df` by station `Name`, `ClimateID`, `StationID`, or any combination of these.
"""
function filter_station_inventory(df::DataFrame ; Name::String="", ClimateID::String="", StationID::String="")
    @assert any([!isempty(Name),!isempty(ClimateID), !isempty(StationID)]) "At least one station charateristic between `Name`, `ClimateID` and `StationID` must be provided."

    station_df_line = deepcopy(df)

    if !isempty(Name)
        filter!(row->row.Name == Name, station_df_line)
    end

    if !isempty(ClimateID)
        filter!(row->row."Climate ID" == ClimateID, station_df_line)
    end

     if !isempty(StationID)
        filter!(row->row."Station ID" == parse(Int64, StationID), station_df_line)
    end

    return station_df_line

end


### Records retrieval


"""
    load_station_daily(; Name::String = "", ClimateID::String = "", StationID::Union{Int, Vector{Int}} = Int[])

Load the daily records of the station identified by `Name`, `ClimateID`, `StationID`, or any combination of these.

See also: [`load_station_hourly`](@ref)
"""
function load_station_daily(;Name::String="", ClimateID::String="", StationID::String="")
    @assert any([!isempty(Name),!isempty(ClimateID), !isempty(StationID)]) "At least one station charateristic between `Name`, `ClimateID` and `StationID` must be provided."

    df = load_station_inventory()

    df_line = filter_station_inventory(df, Name = Name, ClimateID = ClimateID, StationID = StationID)

    @assert !isempty(df_line) "No station with the provided identifier."

    StationID = df_line."Station ID"[]

    firstYear = df_line."DLY First Year"[]
    lastYear = df_line."DLY Last Year"[]

    # Download the data of the first year to set up the DataFrame 
    full_url = "https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=$StationID&Year=$firstYear&Month=1&Day=14&timeframe=2&submit=Download+Data"
    data = CSV.read(Downloads.download(full_url), DataFrame, delim=',')

    @showprogress for yr in (firstYear+1):lastYear
        full_url = "https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=$StationID&Year=$yr&Month=1&Day=14&timeframe=2&submit=Download+Data"
        subdata = CSV.read(Downloads.download(full_url), DataFrame, delim=',')
        append!(data, subdata, promote=true) end

    return data

end

"""
    load_station_hourly(; Name::String = "", ClimateID::String = "", StationID::Union{Int, Vector{Int}} = Int[])

Load the hourly records of the station identified by `Name`, `ClimateID`, `StationID`, or any combination of these.

!!! note "Hourly records"
    Although ECCC allows downloading hourly records, they are often empty because the data is not actually provided.

See also: [`load_station_daily`](@ref)
"""
function load_station_hourly(;Name::String="", ClimateID::String="", StationID::String="")
    @assert any([!isempty(Name),!isempty(ClimateID), !isempty(StationID)]) "At least one station charateristic between `Name`, `ClimateID` and `StationID` must be provided."

    df = load_station_inventory()

    df_line = filter_station_inventory(df, Name = Name, ClimateID = ClimateID, StationID = StationID)

    @assert !isempty(df_line) "No station with the provided identifier."

    StationID = df_line."Station ID"[]

    firstYear = df_line."HLY First Year"[]
    lastYear = df_line."HLY Last Year"[]

    @assert !ismissing(firstYear) "There is no hourly data for Station ID $StationID"

    # Download the data of the first year to set up the DataFrame 
    full_url = "https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=$StationID&Year=$firstYear&Month=1&Day=14&timeframe=1&submit=Download+Data"
    data_sample = CSV.read(Downloads.download(full_url), DataFrame, dateformat ="yyyy-mm-dd HH:MM", delim=',', silencewarnings=true)
    data = similar(data_sample,0)

    @showprogress for yr in firstYear:lastYear
        for imonth in 1:12
            full_url = "https://climate.weather.gc.ca/climate_data/bulk_data_e.html?format=csv&stationID=$StationID&Year=$yr&Month=$imonth&Day=14&timeframe=1&submit=Download+Data"
            subdata = CSV.read(Downloads.download(full_url), DataFrame, dateformat ="yyyy-mm-dd HH:MM", delim=',', silencewarnings=true)
            append!(data, subdata, promote=true)
        end end

    return data

end
