#!/bin/bash

NB_INPUT_SRID="${NB_INPUT_SRID:-4326}"
NB_OUTPUT_SRID="${NB_OUTPUT_SRID:-2163}"
NB_MAX_TRIP_DISTANCE="${NB_MAX_TRIP_DISTANCE:-2680}"
NB_POSTGRESQL_HOST="${NB_POSTGRESQL_HOST:-127.0.0.1}"
NB_POSTGRESQL_DB="${NB_POSTGRESQL_DB:-pfb}"
NB_POSTGRESQL_USER="${NB_POSTGRESQL_USER:-gis}"
NB_POSTGRESQL_PASSWORD="${NB_POSTGRESQL_PASSWORD:-gis}"

source "$(dirname $0)"/../scripts/utils.sh

set -e

if [[ -n "${PFB_DEBUG}" ]]; then
    set -x
fi

function usage() {
    echo -n \
"
Usage: $(basename "$0") <neighborhood_boundary_shapefile> <neighborhood_tiger_state_id>

Import neighborhood boundary to postgres database, overwriting any existing boundary

Requires passing path (relative or absolute) to the neighborhood boundary shapefile.
Requires passing the state FIPS ID that the neighborhood boundary is found in. e.g. MA is 25
    See: https://www.census.gov/geo/reference/ansi_statetables.html

Optional ENV vars:

NB_INPUT_SRID - Default: 4326
NB_OUTPUT_SRID - Default: 2163
NB_MAX_TRIP_DISTANCE - Default: 2680 (in the units of NB_OUTPUT_SRID)
NB_BOUNDARY_BUFFER - Default: NB_MAX_TRIP_DISTANCE (in the units of NB_OUTPUT_SRID)
NB_POSTGRESQL_HOST - Default: 127.0.0.1
NB_POSTGRESQL_DB - Default: pfb
NB_POSTGRESQL_USER - Default: gis
NB_POSTGRESQL_PASSWORD - Default: gis

"
}

# Function to import a shapefile (using 'dump' mode for quickness) and convert it to the target SRID
function import_and_transform_shapefile() {
    IMPORT_FILE="${1}"
    IMPORT_TABLENAME="${2}"
    IMPORT_SRID="${3:-4326}"

    echo "START: Importing ${IMPORT_TABLENAME}"
    shp2pgsql -I -d -D -s "${IMPORT_SRID}" "${IMPORT_FILE}" "${IMPORT_TABLENAME}" \
        | psql -h "${NB_POSTGRESQL_HOST}" -U "${NB_POSTGRESQL_USER}" -d "${NB_POSTGRESQL_DB}" > /dev/null
    psql -h "${NB_POSTGRESQL_HOST}" -U "${NB_POSTGRESQL_USER}" -d "${NB_POSTGRESQL_DB}" \
        -c "ALTER TABLE ${IMPORT_TABLENAME} ALTER COLUMN geom \
            TYPE geometry(MultiPolygon,${NB_OUTPUT_SRID}) USING ST_Force2d(ST_Transform(geom,${NB_OUTPUT_SRID}));"
    echo "DONE: Importing ${IMPORT_TABLENAME}"
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]
then
    if [ "${1:-}" = "--help" ] || [ -z "${1:-}" ]
    then
        usage
    else
        NB_BOUNDARY_FILE="${1}"
        NB_STATE_FIPS="${2}"

        NB_TEMPDIR="${NB_TEMPDIR:-$(mktemp -d)}/import_neighborhood"
        mkdir -p "${NB_TEMPDIR}"

        NB_BOUNDARY_BUFFER="${NB_BOUNDARY_BUFFER:-$NB_MAX_TRIP_DISTANCE}"

        # Import neighborhood boundary
        update_status "IMPORTING" "Importing boundary shapefile"
        import_and_transform_shapefile "${NB_BOUNDARY_FILE}" neighborhood_boundary "${NB_INPUT_SRID}"

        update_status "IMPORTING" "Downloading water blocks"
        # Create water blocks table
        psql -h "${NB_POSTGRESQL_HOST}" -U "${NB_POSTGRESQL_USER}" -d "${NB_POSTGRESQL_DB}" \
            -c "
        CREATE TABLE IF NOT EXISTS \"water_blocks\" (
            \"STATEFP10\" integer,
            \"COUNTYFP10\" integer,
            \"TRACTCE10\" integer,
            \"BLOCKCE10\" integer,
            GEOID varchar(15),
            \"NAME10\" char(10),
            \"MTFCC10\" char(5),
            \"UR10\" char(1),
            \"UACE10\" integer,
            \"UATYP10\" char(1),
            \"FUNCSTAT10\" char(1),
            \"ALAND10\" integer,
            \"AWATER10\" bigint,
            \"INTPTLAT10\" decimal,
            \"INTPTLON10\" decimal
        );"

        # Import water file
        WATER_FILENAME="censuswaterblocks"
        WATER_DOWNLOAD="${NB_TEMPDIR}/${WATER_FILENAME}.zip"
        wget -nv -O "${WATER_DOWNLOAD}" "https://s3.amazonaws.com/pfb-public-documents/censuswaterblocks.zip"
        unzip "${WATER_DOWNLOAD}" -d "${NB_TEMPDIR}"
        psql -h "${NB_POSTGRESQL_HOST}" -U "${NB_POSTGRESQL_USER}" -d "${NB_POSTGRESQL_DB}" \
             -c "\copy water_blocks FROM ${NB_TEMPDIR}/${WATER_FILENAME}.csv delimiter ',' csv header"
        echo "DONE: Importing water blocks"

        # Get blocks for the state requested
        update_status "IMPORTING" "Downloading census blocks"

        NB_BLOCK_FILENAME="$(./../scripts/download_census_blocks.py \
            --local-dir=${NB_TEMPDIR} \
            --state-fips=${NB_STATE_FIPS} \
            --storage-bucket=${AWS_STORAGE_BUCKET_NAME})"

        # Import block shapefile
        update_status "IMPORTING" "Loading census blocks"
        import_and_transform_shapefile "${NB_BLOCK_FILENAME}" neighborhood_census_blocks 4326

        # Only keep blocks in boundary+buffer
        update_status "IMPORTING" "Applying boundary buffer"
        echo "START: Removing blocks outside buffer with size ${NB_BOUNDARY_BUFFER}"
        psql -h "${NB_POSTGRESQL_HOST}" -U "${NB_POSTGRESQL_USER}" -d "${NB_POSTGRESQL_DB}" \
            -c "DELETE FROM neighborhood_census_blocks AS blocks USING neighborhood_boundary \
                AS boundary WHERE NOT ST_DWithin(blocks.geom, boundary.geom, \
                ${NB_BOUNDARY_BUFFER});"
        echo "DONE: Finished removing blocks outside buffer"
        
        # Discard blocks that are all water / no land area
        update_status "IMPORTING" "Removing water blocks"
        echo "START: Removing blocks that are 100% water from analysis"
        psql -h "${NB_POSTGRESQL_HOST}" -U "${NB_POSTGRESQL_USER}" -d "${NB_POSTGRESQL_DB}" \
            -c "DELETE FROM neighborhood_census_blocks AS blocks USING water_blocks \
                AS water WHERE blocks.BLOCKID10 = water.geoid;"
        echo "DONE: FINISHED removing blocks that are 100% water"

        BLOCK_COUNT=$(psql -h "${NB_POSTGRESQL_HOST}" -U "${NB_POSTGRESQL_USER}" -d "${NB_POSTGRESQL_DB}" \
            -t -c "SELECT count(*) as total_census_blocks FROM neighborhood_census_blocks;")
        echo "Census Blocks in analysis: ${BLOCK_COUNT}"
        set_job_attr "census_block_count" "${BLOCK_COUNT}"

        # Remove NB_TEMPDIR
        rm -rf "${NB_TEMPDIR}"
    fi
fi
