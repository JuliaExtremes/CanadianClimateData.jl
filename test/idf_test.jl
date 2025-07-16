@testset "idf" begin

    tmpdir = mktempdir()

    idf_filename = "idf_v3-30_2022_10_31_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt"
    idf_txt_file_path = joinpath(dirname(@__FILE__), "Data/IDF/QC", idf_filename)

    @testset "download_idf_zip" begin
        zip_path = CanadianClimateData.download_idf_zip("PE", dir=tmpdir)
        @test_throws AssertionError CanadianClimateData.download_idf_zip("nonexistant")
        @test isfile(zip_path)
    end

    @testset "unzip_idf_txt" begin
        unzipped_folder_path = CanadianClimateData.unzip_idf_txt("Data/IDF/QC.zip", tmpdir)
        unzipped_file = joinpath(@__FILE__, unzipped_folder_path, idf_filename)
        @test isfile(unzipped_file)
    end
    
    @testset "read_idf_station_metadata" begin
        res = CanadianClimateData.read_idf_station_metadata(idf_txt_file_path)
        @test res[1] == "MONTREAL PIERRE ELLIOTT TRUDEAU INTL"
        @test res[2] == "QC"
        @test res[3] == "702S006"
        @test res[4] ≈ 45.47
        @test res[5] ≈ -73.73
        @test res[6] == 32
    end

    @testset "parse_idf_table" begin
        # Those first and last row can change with IDF version published by ECCC. Here are the values of Version idf_v3-30_2022_10_31 for MONTREAL PIERRE ELLIOTT TRUDEAU INTL.
        firstrow = [1943., 11.7,14.2, 17.8, 20.8, 23.6, 26.7, 33.5, 48.3, 64.3]
        lastrow = [2021., 9.4, 13.2, 14.2, 15.8, 16.0, 16.4, 29.8, 31.0, 45.6]
        
        df = CanadianClimateData.parse_idf_table(idf_txt_file_path)

        @test all(Vector{Float64}(df[1,:]) .≈ firstrow)
        @test all(Vector{Float64}(df[end,:]) .≈ lastrow)
    end

    @testset "list_idf_txt_files" begin
        list = CanadianClimateData.list_idf_txt_files("Data/IDF/QC")
        @test  idf_filename in list
    end


    @testset "select_idf_station" begin

        df = CSV.read("../data/idf_inventory.csv", DataFrame)

        res = CanadianClimateData.select_idf_station(df, Name="WHITEHORSE AUTO")
        @test res.Name[] == "WHITEHORSE AUTO"

        res = CanadianClimateData.select_idf_station(df, ClimateID="2101310")
        @test res.ClimateID[]== "2101310"
    end

    @testset "create_idf_netcdf" begin
        @test_throws AssertionError CanadianClimateData.create_idf_netcdf("noextension")
        filepath = joinpath(@__FILE__, mktempdir(), "test.nc")
        CanadianClimateData.create_idf_netcdf(filepath)
        @test isfile(filepath)
    end

    @testset "convert_idf_to_netcdf" begin
        filename, _ = splitext(basename(idf_txt_file_path))
        
        # CanadianClimateData.convert_idf_to_netcdf(idf_txt_file_path)
        # nc_filepath = joinpath(@__FILE__, pwd(), filename * ".nc")
        # @test isfile(nc_filepath)

        CanadianClimateData.convert_idf_to_netcdf(idf_txt_file_path, tmpdir)
        nc_filepath = joinpath(@__FILE__, tmpdir, filename * ".nc")
        @test isfile(nc_filepath)
    end

end