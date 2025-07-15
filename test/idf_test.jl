@testset "idf" begin

    tmpdir = mktempdir()

    idf_filename = "idf_v3-30_2022_10_31_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt"
    idf_txt_file_path = joinpath(dirname(@__FILE__), "Data/IDF/QC", idf_filename)

    @testset "idf_zip_download" begin
        zip_path = CanadianClimateData.idf_zip_download("PE", dir=tmpdir)
        @test_throws AssertionError CanadianClimateData.idf_zip_download("nonexistant")
        @test isfile(zip_path)
    end

    @testset "idf_unzip" begin
        unzipped_folder_path = CanadianClimateData.idf_unzip("Data/IDF/QC.zip", tmpdir)
        unzipped_file = joinpath(@__FILE__, unzipped_folder_path, idf_filename)
        @test isfile(unzipped_file)
    end
    
    @testset "read_idf_station_info" begin
        res = CanadianClimateData.read_idf_station_info(idf_txt_file_path)
        @test res[1] == "MONTREAL PIERRE ELLIOTT TRUDEAU INTL"
        @test res[2] == "QC"
        @test res[3] == "702S006"
        @test res[4] ≈ 45.47
        @test res[5] ≈ -73.73
        @test res[6] == 32
    end

    @testset "read_idf_data" begin
        # Those first and last row can change with IDF version published by ECCC. Here are the values of Version idf_v3-30_2022_10_31 for MONTREAL PIERRE ELLIOTT TRUDEAU INTL.
        firstrow = [1943., 11.7,14.2, 17.8, 20.8, 23.6, 26.7, 33.5, 48.3, 64.3]
        lastrow = [2021., 9.4, 13.2, 14.2, 15.8, 16.0, 16.4, 29.8, 31.0, 45.6]
        
        df = CanadianClimateData.read_idf_data(idf_txt_file_path)

        @test all(Vector{Float64}(df[1,:]) .≈ firstrow)
        @test all(Vector{Float64}(df[end,:]) .≈ lastrow)
    end

    @testset "idf_list" begin
        list = CanadianClimateData.idf_list("Data/IDF/QC")
        @test  idf_filename in list
    end


    @testset "filter_idf_inventory" begin

        df = CSV.read("../data/idf_inventory.csv", DataFrame)

        res = CanadianClimateData.filter_idf_inventory(df, Name="WHITEHORSE AUTO")
        @test res.Name[] == "WHITEHORSE AUTO"

        res = CanadianClimateData.filter_idf_inventory(df, ClimateID="2101310")
        @test res.ClimateID[]== "2101310"
    end

    @testset "netcdf_generator" begin
        @test_throws AssertionError CanadianClimateData.netcdf_generator("noextension")
        filepath = joinpath(@__FILE__, mktempdir(), "test.nc")
        CanadianClimateData.netcdf_generator(filepath)
        @test isfile(filepath)
    end

    @testset "idf2netcdf" begin
        filename, _ = splitext(basename(idf_txt_file_path))
        
        # CanadianClimateData.idf2netcdf(idf_txt_file_path)
        # nc_filepath = joinpath(@__FILE__, pwd(), filename * ".nc")
        # @test isfile(nc_filepath)

        CanadianClimateData.idf2netcdf(idf_txt_file_path, tmpdir)
        nc_filepath = joinpath(@__FILE__, tmpdir, filename * ".nc")
        @test isfile(nc_filepath)
    end

end