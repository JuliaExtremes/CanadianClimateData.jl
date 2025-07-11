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

!!! note "Hourly records"
    This function works only for Unix and Mac users. For Windows users, the ZIP file should be unzipped externally.

See also: [`idf_zip_download`](@ref)
"""
function idf_unzip(zip_path::String)

    output_dir = splitext(zip_path)[1]

    run(`unzip -j $zip_path '*.txt' -d $output_dir`)

    return output_dir
end

# function idf_inventory(unzipped_folder_path::String)

#     filenames = readdir(unzipped_folder_path)

#     # Extract only the text filesname
#     filter!(x->endswith(x, ".txt"), filenames)
#     filter!(x->contains(x, idf_version), filenames)

#     @assert !isempty(filenames) "The provided folder $unzipped_folder_path does not contain any IDF text file."

# end


function read_idf_station_info(idf_txt_file_path::String)
    @assert isfile(idf_txt_file_path) 

    f = open(idf_txt_file_path, "r")
        lines = readlines(f)
    close(f)

    ClimateID = strip(lines[14][60:end])
    Name = strip(lines[14][1:50])

    stripchar = (s, r) -> replace(s, Regex("[$r]") => "")    # to remove ' from lat/lon

    lat_degree = parse(Int32, stripchar(lines[16][12:14],"'"))
    lat_minute = parse(Int32, stripchar(lines[16][15:17],"'"))

    lat = round(lat_degree + lat_minute/60, digits=2)

    lon_degree = parse(Int32, stripchar(lines[16][34:37],"'"))
    if lon_degree ≥ 100
        lon_minute = parse(Int32, stripchar(lines[16][38:40],"'"))
    else
        lon_minute = parse(Int32, stripchar(lines[16][37:39],"'"))
    end

    lon = - round(lon_degree + lon_minute/60, digits=2)

    elevation = parse(Int32, lines[16][65:69])

    return ClimateID, Name, lat, lon, elevation

end