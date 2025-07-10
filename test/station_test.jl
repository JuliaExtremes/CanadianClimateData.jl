filename = CanadianClimateData.download_station_inventory()

@testset "download_station_inventory" begin
    @test isfile(filename)

    dir = mktempdir()
    specified_filename = CanadianClimateData.download_station_inventory(dir = dir)
    @test isfile(specified_filename)
end

@testset "read_station_inventory" begin
    @test_throws AssertionError CanadianClimateData.read_station_inventory("nonexistant")

    df = CanadianClimateData.read_station_inventory(filename)
    @test typeof(df)==DataFrame
end

@testset "load_station_inventory" begin
    @test_throws AssertionError CanadianClimateData.read_station_inventory("nonexistant")

    df = CanadianClimateData.read_station_inventory(filename)
    @test typeof(df)==DataFrame
end


@testset "filter_station_inventory" begin
    df = CanadianClimateData.read_station_inventory(filename)
    @test_throws AssertionError CanadianClimateData.filter_station_inventory(df)

    df_line = CanadianClimateData.filter_station_inventory(df, Name = "ACTIVE PASS")
    @test df_line.Name[] == "ACTIVE PASS"

    df_line = CanadianClimateData.filter_station_inventory(df, ClimateID = "1010066")
    @test df_line."Climate ID"[] == "1010066"

    df_line = CanadianClimateData.filter_station_inventory(df, StationID = "14")
    @test df_line."Station ID"[] == 14
end

@testset "load_station_daily" begin
    @test_throws AssertionError CanadianClimateData.load_station_daily()

     # Not a valid sation name
    @test_throws AssertionError CanadianClimateData.load_station_daily(ClimateID="nonexistant")

    df_station = CanadianClimateData.load_station_daily(Name="ACTIVE PASS")
    @test all(df_station."Station Name" .== "ACTIVE PASS")
    
end

@testset "load_station_hourly" begin
    @test_throws AssertionError CanadianClimateData.load_station_hourly()

    # No hourly data
    @test_throws AssertionError CanadianClimateData.load_station_hourly(Name="ACTIVE PASS")

    # Not a valid sation name
    @test_throws AssertionError CanadianClimateData.load_station_hourly(ClimateID="nonexistant")

    df_station = CanadianClimateData.load_station_hourly(ClimateID="1100004")
    @test all(df_station."Climate ID" .== 1100004)
end