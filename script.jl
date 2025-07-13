using CSV, DataFrames, Test

using Pkg
pkg"activate ."

using CanadianClimateData

zip_path = CanadianClimateData.idf_zip_download("PE", dir=mktempdir())
folderpath = CanadianClimateData.idf_unzip(zip_path)

filenames = CanadianClimateData.idf_list(folderpath)