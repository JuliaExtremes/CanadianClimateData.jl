using CSV, DataFrames, Test

using Pkg
pkg"activate ."
using CanadianClimateData

# Download all idf text files and compile the IDF inventory

download_dir = pwd()
zip_path = CanadianClimateData.download_idf_zip(download_dir)


    zip_path = "/Users/jalbert/Documents/PackageDevelopment.nosync/CanadianClimateData.jl/idf_v3-40_2025-12-5.zip"

CanadianClimateData.unzip_idf_txt(zip_path)
CanadianClimateData.list_idf_txt_files("/Users/jalbert/Documents/PackageDevelopment.nosync/CanadianClimateData.jl/idf_v3-40_2025-12-5")






idf_txt_file_path = "/Users/jalbert/Documents/PackageDevelopment.nosync/CanadianClimateData.jl/idf_v3-40_2025-12-5/idf_v3-40_2025_12_5_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt"
metadata = CanadianClimateData.read_idf_station_metadata(idf_txt_file_path)

df = CanadianClimateData.parse_idf_table(idf_txt_file_path)


CanadianClimateData.create_idf_netcdf("test.nc")

CanadianClimateData.convert_idf_to_netcdf(idf_txt_file_path)