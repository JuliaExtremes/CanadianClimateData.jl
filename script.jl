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
    zip_path = CanadianClimateData.download_idf_zip(province, dir=download_dir)
    folderpath = CanadianClimateData.unzip_idf_txt(zip_path, extracted_files_dir)
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

filenames = CanadianClimateData.list_idf_txt_files(extracted_files_dir)

for filename in filenames
    idf_file_path = joinpath(dirname(@__FILE__), extracted_files_dir, filename)
    Name, Province, ClimateID, Lon, Lat, Elevation = CanadianClimateData.read_idf_station_metadata(idf_file_path)
    push!(df, [Name, Province, ClimateID, Lon, Lat, Elevation])
end

# Read a idf txt file


extracted_files_dir = "/Users/jalbert/Documents/PackageDevelopment.nosync/Data/"
idf_filename = "idf_v3-30_2022_10_31_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt"

df_file_path = joinpath(dirname(@__FILE__), extracted_files_dir, idf_filename)


CanadianClimateData.parse_idf_table(df_file_path)