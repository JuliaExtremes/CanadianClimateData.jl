using CSV, DataFrames, Test

using Pkg
pkg"activate ."

using CanadianClimateData


# Dowload all idf text files

download_dir = mktempdir()
extracted_files_dir = joinpath(@__DIR__,"..","Data")

mkdir(extracted_files_dir)

provinces = CanadianClimateData.prov_list

for province in provinces
    zip_path = CanadianClimateData.idf_zip_download(province, dir=download_dir)
    folderpath = CanadianClimateData.idf_unzip(zip_path, extracted_files_dir)
end


# Compile the idf inventory

df = DataFrame(
    Name = String[],
    Province = String[], 
    ClimateID = String[],
    Lat = Float64[],
    Lon = Float64[],
    Elevation = Int64[]
    )

filenames = CanadianClimateData.idf_list(extracted_files_dir)

for filename in filenames
    idf_file_path = joinpath(dirname(@__FILE__), extracted_files_dir, filename)
    Name, Province, ClimateID, Lon, Lat, Elevation = CanadianClimateData.read_idf_station_info(idf_file_path)
    push!(df, [Name, Province, ClimateID, Lon, Lat, Elevation])
end





