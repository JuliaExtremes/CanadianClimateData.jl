using CSV, DataFrames, Test

using Pkg
pkg"activate ."

using CanadianClimateData

# Construct the idf_inventory.csv file

df = DataFrame(
    Province = String[], 
    Climate_ID = String[],
    Name = String[],
    Lat = Float64[],
    Lon = Float64[],
    Elevation = Int64[]
    )


dir = mktempdir()
provinces = CanadianClimateData.prov_list

for province in provinces
    zip_path = CanadianClimateData.idf_zip_download(province, dir=dir)
    folderpath = CanadianClimateData.idf_unzip(zip_path)
    filenames = CanadianClimateData.idf_list(folderpath)

    for filename in filenames
        idf_file_path = joinpath(dirname(@__FILE__), folderpath, filename)
        ClimateID, Name, Lon, Lat, Elevation = CanadianClimateData.read_idf_station_info(idf_file_path)
        push!(df, [province, ClimateID, Name, Lat, Lon, Elevation])
    end
end


"""
    filter_idf_inventory(df::DataFrame; Name::String = "", ClimateID::String = "", StationID::String="")

Filter the idf inventory DataFrame `df` by station `Name`, `ClimateID`, `StationID`, or any combination of these.
"""
function filter_idf_inventory(df::DataFrame ; Name::String="", ClimateID::String="", StationID::String="")
    @assert any([!isempty(Name),!isempty(ClimateID)]) "At least one station charateristic between `Name` and `ClimateID` and must be provided."

    idf_df_line = deepcopy(df)

    if !isempty(Name)
        filter!(row->row.Name == Name, idf_df_line)
    end

    if !isempty(ClimateID)
        filter!(row->row."Climate ID" == ClimateID, idf_df_line)
    end

    return idf_df_line

end

res = CanadianClimateData.filter_idf_inventory(df, Name="WHITEHORSE AUTO")
@test res.Name == "WHITEHORSE AUTO"
res = CanadianClimateData.filter_idf_inventory(df, ClimateID="2101310")
@test res.ClimateID== "2101310"


