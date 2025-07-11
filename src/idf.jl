idf_version = "idf_v3-30_2022_10_31"

repo_url = "https://collaboration.cmc.ec.gc.ca/cmc/climate/Engineer_Climate/IDF/"*idf_version*"/IDF_Files_Fichiers/"

prov_list = ["AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"]

"""
    idf_zip_download(province::String ; dir::String=pwd())

Download the ZIP files of the IDF of the province `province` in `dir`.
"""
function idf_zip_download(province::String ; dir::String=pwd())
    @assert province ∈ prov_list "The provided province $province is not valid."

    zip_remote_filename = "$(province).zip"

    zip_remote_path = string(repo_url, zip_remote_filename)

    zip_local_path = joinpath(dirname(@__FILE__), dir, zip_remote_filename)

    Downloads.download(zip_remote_path, zip_local_path)

    return zip_local_path

end

"""
    idf_unzip(zip_path::String)

Unzip only the text files contained in the archive.

See also: [`idf_zip_download`](@ref)
"""
function idf_unzip(zip_path::String)

    output_dir = splitext(zip_path)[1]

    run(`unzip -j $zip_path '*.txt' -d $output_dir`)

    return output_dir
end




#     for province in provinces
#         # Make a temp directory for all data :
#         try
#             cd("$(output_dir)/temp_data")
#         catch
#             mkdir("$(output_dir)/temp_data")
#             cd("$(output_dir)/temp_data")
#         end

#         file = "$(province).zip"

#         # Download the data (if not downloaded already) and unzip the data :
#         if file in glob("*", pwd())
#             run(`unzip $(file) "*.txt"`)   # unzip the data
#         else
#             Downloads.download("$(url)$(file)", "$(file)")
#             try
#                 run(`unzip $(file) "*.txt"`)   # unzip the data
#                 cd("$(output_dir)")
#             catch
#                 throw(error("Unable to unzip the data file."))
#             end
#         end

#         input_d = "$(output_dir)/temp_data/$(province)" # Where raw data are
#         if split
#             # Make the output directory if it doesn't exist :
#             try
#                 mkdir("$(output_dir)/$(province)")
#             catch
#                 nothing
#             end
#             output_d = "$(output_dir)/$(province)" # Where the netcdf/csv will be created
#         else
#             output_d = "$(output_dir)/"
#         end

#         # Convert the data in the specified format (CSV or NetCDF) :
#         if lowercase(format) == "csv"
#             #txt2csv(input_d, output_d, province)
#             info_df = vcat(info_df, txt2csv(input_d, output_d, province))
#         elseif lowercase(format) == "netcdf" || lowercase(format) == "nc"
#             txt2netcdf(input_d, output_d)
#         else
#             throw(error("Format is not valid"))
#         end

#         # Automatic deletion
#         if rm_temp
#             rm("$(output_dir)/temp_data", recursive=true)
#         end
#     end
#     if lowercase(format) == "csv"
#         output_info = "$(output_dir)/info_stations.csv"
#         CSV.write(output_info, info_df)
#     end
#     return nothing
# end
