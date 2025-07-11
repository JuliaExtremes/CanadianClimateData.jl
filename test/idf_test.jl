@testset "idf_zip_download" begin
    @test_throws AssertionError CanadianClimateData.idf_zip_download("nonexistant")
    @test isfile(CanadianClimateData.idf_zip_download("PE", dir=mktempdir()))
end

@testset "idf_unzip" begin
    zip_path = CanadianClimateData.idf_zip_download("PE", dir=mktempdir())

    folderpath = CanadianClimateData.idf_unzip(zip_path)

    txt_file_name = joinpath(dirname(@__FILE__), folderpath, "idf_v3-30_2022_10_31_830_PE_8300516_NORTH_CAPE.txt")

    @test isfile(txt_file_name)
end
