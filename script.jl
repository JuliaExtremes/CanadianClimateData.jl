using CSV, DataFrames, Test

using Pkg
pkg"activate ."

using CanadianClimateData

# Construct the idf_inventory.csv file

df = DataFrame(
    Province = String[], 
    ClimateID = String[],
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



