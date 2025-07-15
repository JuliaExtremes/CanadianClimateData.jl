using CanadianClimateData
using Test

using CSV, DataFrames

@testset "CanadianClimateData.jl" begin
    include("station_test.jl")
    include("idf_test.jl")
end

