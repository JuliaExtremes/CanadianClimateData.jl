@testset "idf_zip_download" begin
    @test_throws AssertionError CanadianClimateData.idf_zip_download("nonexistant")

    zip_path = CanadianClimateData.idf_zip_download("PE", dir=mktempdir())
    @test isfile(zip_path)

    folderpath = CanadianClimateData.idf_unzip(zip_path)
    txt_file_name = joinpath(dirname(@__FILE__), folderpath, "idf_v3-30_2022_10_31_830_PE_8300301_CHARLOTTETOWN_A.txt")
    @test isfile(txt_file_name)

    
    @testset "read_idf_station_info" begin
        res = CanadianClimateData.read_idf_station_info(txt_file_name)
        @test res[1] == "8300301"
        @test res[2] == "CHARLOTTETOWN A"
        @test res[3] ≈ 46.28
        @test res[4] ≈ -63.12
        @test res[5] == 48
    end
end






# end

# @testset "idf_unzip" begin
#     zip_path = CanadianClimateData.idf_zip_download("PE", dir=mktempdir())

#     folderpath = CanadianClimateData.idf_unzip(zip_path)

#     txt_file_name = joinpath(dirname(@__FILE__), folderpath, "idf_v3-30_2022_10_31_830_PE_8300516_NORTH_CAPE.txt")

#     @test isfile(txt_file_name)




# end

# @testset "read_idf_station_info" begin
    
# end