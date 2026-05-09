using CSV, DataFrames, Test

using Pkg
pkg"activate ."
using CanadianClimateData

# Download all idf text files and compile the IDF inventory

zip_path = CanadianClimateData.download_idf_zip()

unzipped_folder_path = CanadianClimateData.unzip_idf_txt(zip_path)


filename = joinpath(unzipped_folder_path, "idf_v3-40_2025_12_5_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt")


metadata = CanadianClimateData.read_idf_station_metadata(filename)

df = CanadianClimateData.parse_idf_table(filename)

CanadianClimateData.convert_idf_to_netcdf(filename)