
@testset "station" begin

    tmpdir = mktempdir()

    @testset "download_station_inventory" begin
        specified_filename= CanadianClimateData.download_station_inventory(dir=tmpdir)
        @test isfile(specified_filename)
    end

    @testset "read_station_inventory" begin
        @test_throws AssertionError CanadianClimateData.read_station_inventory("nonexistant")
        df = CanadianClimateData.read_station_inventory("Data/Station/Station Inventory EN.csv")
        @test typeof(df) == DataFrame
    end

    @testset "load_station_inventory" begin
        df = CanadianClimateData.load_station_inventory(dir=tmpdir)
        @test typeof(df) == DataFrame
    end

    df = CanadianClimateData.read_station_inventory("Data/Station/Station Inventory EN.csv")

    @testset "select_station" begin
        @test_throws AssertionError CanadianClimateData.select_station(df)

        df_line = CanadianClimateData.select_station(df, Name="ACTIVE PASS")
        @test df_line.Name[] == "ACTIVE PASS"

        df_line = CanadianClimateData.select_station(df, ClimateID="1010066")
        @test df_line."Climate ID"[] == "1010066"

        df_line = CanadianClimateData.select_station(df, StationID="14")
        @test df_line."Station ID"[] == 14

        @test_throws ErrorException CanadianClimateData.select_station(df, StationID="string")
    end

    @testset "fetch_daily_records" begin
        @test_throws AssertionError CanadianClimateData.fetch_daily_records()

        # Not a valid sation name
        @test_throws AssertionError CanadianClimateData.fetch_daily_records(ClimateID="nonexistant")

        df_station = CanadianClimateData.fetch_daily_records(Name="ACTIVE PASS")
        @test all(df_station."Station Name" .== "ACTIVE PASS")

    end

    @testset "fetch_hourly_records" begin
        @test_throws AssertionError CanadianClimateData.fetch_hourly_records()

        # No hourly data
        @test_throws AssertionError CanadianClimateData.fetch_hourly_records(Name="ACTIVE PASS")

        # Not a valid sation name
        @test_throws AssertionError CanadianClimateData.fetch_hourly_records(ClimateID="nonexistant")

        df_station = CanadianClimateData.fetch_hourly_records(ClimateID="1100004")
        @test all(df_station."Climate ID" .== 1100004)
    end

end
