@testset "idf" begin

    tmpdir = mktempdir()

    idf_filename = "idf_v3-40_2025_12_5_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt"
    idf_txt_file_path = joinpath(dirname(@__FILE__), "Data/IDF", idf_filename)

    @testset "download_idf_zip" begin
        import CanadianClimateData.download_idf_zip

        mktempdir() do dir
            fake_downloader = function(url, path)
            write(path, "fake zip content")
            return path
        end

        zip_path = download_idf_zip(
            dir;
            url="https://example.com/idf.zip",
            version="test_idf",
            downloader=fake_downloader,
        )

        @test zip_path == joinpath(dir, "test_idf.zip")
        @test isfile(zip_path)
        @test read(zip_path, String) == "fake zip content"
    end
end

@testset "unzip_idf_txt" begin
    
    import CanadianClimateData.unzip_idf_txt
    
    zip_path = joinpath(@__DIR__, "Data", "IDF",  "idf_v3-40_2025-12-5.zip")


    mktempdir() do target_dir
        unzipped_dir = unzip_idf_txt(
            zip_path;
            target_dir=target_dir,
            provinces=["QC", "YT"],
        )

        @test unzipped_dir == target_dir
        @test isdir(unzipped_dir)

        txt_files = filter(file -> endswith(file, ".txt"), readdir(unzipped_dir))

        @test !isempty(txt_files)
        @test "idf_v3-40_2025_12_5_210_YT_2100LRP_DAWSON.txt" ∈ txt_files
        @test "idf_v3-40_2025_12_5_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt" ∈ txt_files
        @test !isfile(joinpath(unzipped_dir, "QC.zip"))
        @test !isfile(joinpath(unzipped_dir, "YT.zip"))
    end
end
    
    @testset "read_idf_station_metadata" begin
        res = CanadianClimateData.read_idf_station_metadata(idf_txt_file_path)
        @test res[1] == "MONTREAL PIERRE ELLIOTT TRUDEAU INTL"
        @test res[2] == "QC"
        @test res[3] == "702S006"
        @test res[4] ≈ 45.47
        @test res[5] ≈ -73.73
        @test res[6] == 32

        res = CanadianClimateData.read_idf_station_metadata("Data/IDF/idf_v3-40_2025_12_5_210_YT_2100LRP_DAWSON.txt")
        @test res[5] ≈ -139.12 atol=1e-2
    end

    @testset "parse_idf_table" begin
        # Those first and last row can change with IDF version published by ECCC. Here are the values of Version idf_v3-40_2025_12_5 for MONTREAL PIERRE ELLIOTT TRUDEAU INTL.
        firstrow = [1943., 11.7,14.2, 17.8, 20.8, 23.6, 26.7, 33.5, 48.3, 64.3]
        lastrow = [2024., 8.4, 14.2, 17.0, 24.2, 32.4, 49.6, 70.8, 80.4, 138.2]
        
        df = CanadianClimateData.parse_idf_table(idf_txt_file_path)

        @test all(Vector{Float64}(df[1,:]) .≈ firstrow)
        @test all(Vector{Float64}(df[end,:]) .≈ lastrow)
    end

    @testset "list_idf_txt_files" begin
        list = CanadianClimateData.list_idf_txt_files("Data/IDF")
        @test  idf_filename in list
    end


    @testset "select_idf_station" begin

        df = CSV.read("../data/idf_v-3.40_2025_12_5_log_included.csv", DataFrame)

        res = CanadianClimateData.select_idf_station(df, Name="WHITEHORSE AUTO")
        @test res.Name[] == "WHITEHORSE AUTO"

        res = CanadianClimateData.select_idf_station(df, ID="2101310")
        @test res.ID[]== "2101310"
    end

    @testset "create_idf_netcdf" begin
        @test_throws ArgumentError CanadianClimateData.create_idf_netcdf("noextension")
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