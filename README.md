# CanadianClimateData 🇨🇦

[![Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Build Status](https://github.com/JuliaExtremes/CanadianClimateData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaExtremes/CanadianClimateData.jl/actions/workflows/CI.yml?query=branch%3Amain)

<!-- [![documentation stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaextremes.github.io/IDFDataCanada.jl/stable/) -->
<!-- [![documentation latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliaextremes.github.io/IDFDataCanada.jl/dev/) -->

**CanadianClimateData.jl** provides methods to retrieve historical meteorological data from Environment and Climate Change Canada (ECCC) stations via automatic download and extraction from archives hosted on [ECCC's server](https://collaboration.cmc.ec.gc.ca/cmc/climate/Engineer_Climate/IDF/).

## Installation

To install the package, run the following command in the Julia REPL:

```julia
julia> import Pkg
julia> Pkg.add(url = "https://github.com/JuliaExtremes/CanadianClimateData.jl", rev = "main")
```


## Retrieve the station inventory

The following command downloads the station inventory to a temporary folder and reads the CSV file into a `DataFrame`:

```julia
julia> using CanadianClimateData
julia> CanadianClimateData.load_station_inventory()
```

To download the file to the current directory, use the following command:
```julia
julia> CanadianClimateData.load_station_inventory(dir = "..")
```

This inventory is useful for identifying station names, station IDs, and climate IDs.

## Retrieve Daily Records

The following command downloads the daily data for the station with `ClimateID = "51157"` and returns it as a `DataFrame`:

```julia
julia> CanadianClimateData.load_station_daily(ClimateID="51157")
```

## Retrieve Hourly Records

The following command downloads the hourly data for the station with `ClimateID = "51157"` and returns it as a `DataFrame`:

```julia
julia> CanadianClimateData.load_station_hourly(ClimateID="51157")
```

!!! note "Hourly records"
    Although ECCC allows downloading hourly records, they are often empty because the data is not actually provided.




<!-- ## Documentation 

See the [Package Documentation](https://juliaextremes.github.io/IDFDataCanada.jl) for details and examples. -->