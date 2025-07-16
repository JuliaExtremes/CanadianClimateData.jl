module CanadianClimateData

using CSV, DataFrames, Dates, Downloads, NCDatasets, ProgressMeter

include("station.jl")
include("idf.jl")

end
