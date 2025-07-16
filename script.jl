using CanadianClimateData, CSV, DataFrames, Test

# Download all idf text files and compile the IDF inventory

download_dir = mktempdir()

provinces = CanadianClimateData.prov_list

df = DataFrame(
    Name = String[],
    Province = String[], 
    ClimateID = String[],
    Lat = Float64[],
    Lon = Float64[],
    Elevation = Int64[]
    )

for province in provinces
    zip_path = CanadianClimateData.download_idf_zip(province, dir=download_dir)
    folderpath = CanadianClimateData.unzip_idf_txt(zip_path)

    filenames = CanadianClimateData.list_idf_txt_files(folderpath)
    
    for filename in filenames
        idf_file_path = joinpath(dirname(@__FILE__), extracted_files_dir, filename)
        Name, Province, ClimateID, Lon, Lat, Elevation = CanadianClimateData.read_idf_station_metadata(idf_file_path)
        push!(df, [Name, Province, ClimateID, Lon, Lat, Elevation])
    end
end
