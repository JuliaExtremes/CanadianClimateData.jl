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

    @testset "netcdf_generator" begin
        @test_throws AssertionError CanadianClimateData.netcdf_generator("noextension")
        filepath = joinpath(@__FILE__, mktempdir(), "test.nc")
        CanadianClimateData.netcdf_generator(filepath)
        @test isfile(filepath)
    end

    @testset "idf2netcdf" begin
        extracted_files_dir = "Data/IDF/QC"
        idf_filename = "idf_v3-30_2022_10_31_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt"
        idf_txt_file_path = joinpath(dirname(@__FILE__), extracted_files_dir, idf_filename)
        filename, _ = splitext(basename(idf_txt_file_path))
        
        # CanadianClimateData.idf2netcdf(idf_txt_file_path)
        # nc_filepath = joinpath(@__FILE__, pwd(), filename * ".nc")
        # @test isfile(nc_filepath)

        tmpdir = mktempdir()
        CanadianClimateData.idf2netcdf(idf_txt_file_path, tmpdir)
        nc_filepath = joinpath(@__FILE__, tmpdir, filename * ".nc")
        @test isfile(nc_filepath)
    end

end