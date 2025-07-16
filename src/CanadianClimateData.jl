module CanadianClimateData

using CSV, DataFrames, Dates, Downloads, NCDatasets, ProgressMeter

global station_inventory_url = "https://collaboration.cmc.ec.gc.ca/cmc/climate/Get_More_Data_Plus_de_donnees/Station%20Inventory%20EN.csv"

include("station.jl")
include("idf.jl")

end
