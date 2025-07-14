@testset "idf_zip_download" begin

    zip_path = CanadianClimateData.idf_zip_download("PE", dir=mktempdir())

    @testset "idf_zip_download" begin
        @test_throws AssertionError CanadianClimateData.idf_zip_download("nonexistant")
         @test isfile(zip_path)
    end

    folderpath = CanadianClimateData.idf_unzip(zip_path)
    filename = string(CanadianClimateData.idf_version, "_830_PE_8300301_CHARLOTTETOWN_A.txt")
    txt_file_path = joinpath(dirname(@__FILE__), folderpath, filename)

    @testset "idf_unzip" begin
        @test isfile(txt_file_path)

        tmpdir = mktempdir()
        folderpath = CanadianClimateData.idf_unzip(zip_path, tmpdir)
        filename = string(CanadianClimateData.idf_version, "_830_PE_8300301_CHARLOTTETOWN_A.txt")
        txt_file_path = joinpath(dirname(@__FILE__), folderpath, filename)

    end
    
    @testset "read_idf_station_info" begin
        res = CanadianClimateData.read_idf_station_info(txt_file_path)
        @test res[1] == "CHARLOTTETOWN A"
        @test res[2] == "PE"
        @test res[3] == "8300301"
        @test res[4] ≈ 46.28
        @test res[5] ≈ -63.12
        @test res[6] == 48
    end

    @testset "read_idf_data" begin
        # Those first and last row can change with IDF version published by ECCC. Here are the values of Version idf_v3-30_2022_10_31 for CHARLOTTETOWN A.
        firstrow = [1967., 7.1, 10.9, 12.2, 21.3, 32.0, 51.8, 76.7, 97.5, 100.8]
        lastrow = [2016., 8.3, 10.2, 13.2, 19.0, 19.2, 19.2, 31.1, 46.6, 70.9]
        
        df = CanadianClimateData.read_idf_data(txt_file_path)

        @test all(Vector{Float64}(df[1,:]) .≈ firstrow)
        @test all(Vector{Float64}(df[end,:]) .≈ lastrow)
    end

    @testset "idf_list" begin
        list = CanadianClimateData.idf_list(folderpath)
        @test filename in list
    end


    @testset "filter_idf_inventory" begin

        df = CSV.read("../data/idf_inventory.csv", DataFrame)

        res = CanadianClimateData.filter_idf_inventory(df, Name="WHITEHORSE AUTO")
        @test res.Name[] == "WHITEHORSE AUTO"

        res = CanadianClimateData.filter_idf_inventory(df, ClimateID="2101310")
        @test res.ClimateID[]== "2101310"
    end
end