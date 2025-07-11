using CSV, DataFrames, Test

using CanadianClimateData

zip_path = CanadianClimateData.idf_zip_download("PE", dir=mktempdir())
folderpath = CanadianClimateData.idf_unzip(zip_path)
idf_txt_file_path = joinpath(dirname(@__FILE__), folderpath, "idf_v3-30_2022_10_31_830_PE_8300301_CHARLOTTETOWN_A.txt")

res = CanadianClimateData.read_idf_station_info(idf_txt_file_path)

f = open(idf_txt_file_path, "r")
    lines = readlines(f)
close(f)




# TODO : à insérer dans une fonction permettant de lire les données

slines = strip.(lines)

data_header_line = findfirst(slines .== "Ann\xe9e")
data_bottom_line = findfirst(slines .== repeat("-",69))

n = data_bottom_line - data_header_line - 1
M = Matrix{Float64}(undef, n, 10)

i = 1
for line in slines[(data_header_line+1):(data_bottom_line-1)]
    M[i,:] = parse.(Float64, split(line))
    i+=1
end

M = replace(M, -99.9 => missing)

colnames = ["Year","5min","10min","15min","30min","1h","2h","6h","12h","24h"]

df = DataFrame(M, colnames)

df.Year = Int64.(df.Year)

df