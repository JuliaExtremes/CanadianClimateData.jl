# CanadianClimateData 🇨🇦

[![Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Build Status](https://github.com/JuliaExtremes/CanadianClimateData.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaExtremes/CanadianClimateData.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/JuliaExtremes/CanadianClimateData.jl/branch/dev/graph/badge.svg?token=7UGVMF0ENE)](https://codecov.io/gh/JuliaExtremes/CanadianClimateData.jl)

**CanadianClimateData.jl** provides methods to retrieve historical meteorological data from Environment and Climate Change Canada (ECCC) via automatic download and extraction from archives hosted on [ECCC's server](https://collaboration.cmc.ec.gc.ca/cmc/climate/Engineer_Climate/IDF/). The package enables users to extract data from meteorological stations as well as from the Intensity-Duration-Frequency (IDF) engineering dataset.

## Installation

To install the package, run the following command in the Julia REPL:

```julia
julia> import Pkg
julia> Pkg.add(url = "https://github.com/JuliaExtremes/CanadianClimateData.jl", rev = "main")
```

## Station data

### Retrieve the station inventory

The following command downloads the station inventory into the working directory and reads the CSV file into a DataFrame:

```julia
julia> using CanadianClimateData
julia> CanadianClimateData.load_station_inventory()
```

This inventory is useful for identifying station names, station IDs, and climate IDs.

### Retrieve Daily Records

The following command downloads the daily data for the station with `ClimateID = "702S006"` and returns it as a `DataFrame`:

```julia
julia> CanadianClimateData.fetch_daily_records(ClimateID="702S006")
```

### Retrieve Hourly Records

The following command downloads the hourly data for the station with `ClimateID = "702S006"` and returns it as a `DataFrame`:

```julia
julia> CanadianClimateData.fetch_hourly_records(ClimateID="702S006")
```

!!! note "Hourly records"
    Although ECCC allows downloading hourly records, they are often empty because the data is not actually provided.

## IDF data

### Download the ZIP IDF files of a province

The following command downloads the IDF ZIP file for the province "QC" into the working directory and returns the local path of the archive:

```julia
julia> zip_path = CanadianClimateData.download_idf_zip("QC")
```

### Unzip the ZIP IDF files on Unix-based systems (Linux/macOS)

The following command unzips the `.txt` files contained in the archive and returns the path of the unzipped folder:

```julia
julia> unzipped_folder_path = CanadianClimateData.unzip_idf_txt(zip_path)
```

For Windows user, the archive should be unzipped externally.

### Read the IDF text file

The following commands read the text file for the station `MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL` and return a `DataFrame`:

```julia
julia> filename = joinpath(unzipped_folder_path, "idf_v3-30_2022_10_31_702_QC_702S006_MONTREAL_PIERRE_ELLIOTT_TRUDEAU_INTL.txt")
julia> df = CanadianClimateData.parse_idf_table(filename)
```

### Convert the text file to a NetCDF file

The IDF text file can be converted to a NetCDF file as follows:

```julia
julia> CanadianClimateData.convert_idf_to_netcdf(filename)
```

