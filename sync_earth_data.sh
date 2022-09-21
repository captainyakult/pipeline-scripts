#!/bin/bash

set -e

do_sync () {
				FROM=$1
				PROJECT=$2
				DATASET=$3
				EYES_FOLDER=$4
				MODE=$5

				# Get the base folder of the system.
				BASE=$(cd "$(dirname "$0")/../.."; pwd)
				DIR=$BASE'/data/earth_data'
				AWS_S3_SYNC_DIR=$BASE/code/aws-s3-sync

				if [ $1 = "esc_imaging_1a" ]; then
					SERVER_PATH=pipeline@esc-imaging-1a:/Volumes/esc/proj/$PROJECT/img/EyesData/$DATASET/
				elif [ $1 = "esc_imaging_2a" ]; then
					SERVER_PATH=pipeline@esc-imaging-2a:/Volumes/esc/proj/$PROJECT/img/EyesData/$DATASET/
				elif [ $1 = "esc_imaging_3a" ]; then
					SERVER_PATH=pipeline@esc-imaging-3a:/Volumes/esc/proj/$PROJECT/img/EyesData/$DATASET/
				fi

				rsync -avL --size-only --delete-before --delete-excluded --delete --no-motd -f'+ /[1-9][0-9]/' -f'+ /[1-9][0-9]/[0-9][0-9][0-9][0-9]_[0-6].png' -f'+ /[1-9][0-9]/[0-9][0-9][0-9][0-9]_cyl.png' -f'+ /[1-9][0-9]/[0-9][0-9][0-9][0-9]_7.unity3d' -f'- **' $SERVER_PATH $DIR/$EYES_FOLDER

				echo

				python3 $BASE/code/scripts/create_data_inventory.py $DIR/$EYES_FOLDER $MODE

				# Upload the files to AWS.
				$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstage/server/data/$EYES_FOLDER $DIR/$EYES_FOLDER
				$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-dev/assets/dynamic/earth/data/$EYES_FOLDER $DIR/$EYES_FOLDER
				$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-staging/assets/dynamic/earth/data/$EYES_FOLDER $DIR/$EYES_FOLDER
				$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyes-production/assets/dynamic/earth/data/$EYES_FOLDER $DIR/$EYES_FOLDER
				$AWS_S3_SYNC_DIR/sync.sh sync-s3-folder eyesstatic/server/data/$EYES_FOLDER $DIR/$EYES_FOLDER
}

# MODIS & VIIRS
do_sync esc_imaging_1a modis/modis_aqua modisAquaDay modisAquaToday daily
do_sync esc_imaging_1a modis/modis_terra modisTerraDay modisToday daily
do_sync esc_imaging_1a viirs/viirs_true_color viirsTrueColorDay viirsToday daily

# GRACE
do_sync  esc_imaging_1a grace/grace_gravity graceGravityMonthly graceMonthly "monthly grace"

# OCO-2 OC2
do_sync esc_imaging_1a oco2/oco2_co2x oco2Co2x_16dayAll oco216Day daily

# Sea Level
do_sync esc_imaging_1a jason/jason_sea_level_variation jasonSeaLevelVariation10dayAll akiko10Day daily
do_sync esc_imaging_1a jason/jason_sea_level_variation jasonSeaLevelVariationMonthly akikoMonthly monthly

# AIRS 10k ft Temp
do_sync esc_imaging_1a airs/airs_temp10kft airsTemp10kftDay3day dayTemp3Day daily
do_sync esc_imaging_1a airs/airs_temp10kft airsTemp10kftDayDay dayTempToday daily
do_sync esc_imaging_1a airs/airs_temp10kft airsTemp10kftNight3day nightTemp3Day daily
do_sync esc_imaging_1a airs/airs_temp10kft airsTemp10kftNightDay nightTempToday daily

# AIRS Water Vapor
do_sync esc_imaging_1a airs/airs_tot airsTot3day newVaporCol3Day daily
do_sync esc_imaging_1a airs/airs_tot airsTotDay newVaporColToday daily 
do_sync esc_imaging_1a airs/airs_tot airsTotMonthly newVaporColMonthly monthly

# AIRS Surface Temp
do_sync esc_imaging_1a airs/airs_sat airsSatDay3day airSurfaceDayTemp3Day daily
do_sync esc_imaging_1a airs/airs_sat airsSatDayDay airSurfaceDayTempToday daily
do_sync esc_imaging_1a airs/airs_sat airsSatNight3day airSurfaceNightTemp3Day daily
do_sync esc_imaging_1a airs/airs_sat airsSatNightDay airSurfaceNightTempToday daily

# AIRS CO2
do_sync esc_imaging_1a airs/airs_co2 airsCo2Monthly newCo2Monthly monthly

# AIRS Upper Water Vapor
do_sync esc_imaging_1a airs/airs_ut_humidity airsUtHumidity3day vaporUpper3Day daily
do_sync esc_imaging_1a airs/airs_ut_humidity airsUtHumidityDay vaporUpperToday daily

# SMAP
do_sync esc_imaging_1a smap/smap_soil_moisture_p_e smapSoilMoisturePEDayWeekly smapSoilMoisture8Day daily
do_sync esc_imaging_1a smap/smap_soil_moisture_p_e smapSoilMoisturePEDayMonthly smapSoilMoistureMonthly monthly
do_sync esc_imaging_1a smap/smap_rootzone_wetness smapRootzoneWetnessDayDay smapRootzoneWetnessDayToday daily
do_sync esc_imaging_1a smap/smap_gpp_mean smapGppMeanDayDay smapGppMeanDayToday daily
do_sync esc_imaging_1a smap/smap_salinity smapSalinityDayDay smapSalinity8Day daily

# AIRS CO
do_sync esc_imaging_1a airs/airs_cmono airsCmono3day mono3Day daily
do_sync esc_imaging_1a airs/airs_cmono airsCmonoDay monoToday daily

# OMI
do_sync esc_imaging_1a omi/omi_ozone omiOzoneDay omiOzoneToday daily

# MLS
do_sync esc_imaging_1a mls/mls_clo_v5 mlsCloV5Weekly clO7Day daily
do_sync esc_imaging_1a mls/mls_clo_v5 mlsCloV5Day clOToday daily
do_sync esc_imaging_1a mls/mls_hcl_v5 mlsHclV5Weekly hCl7Day daily
do_sync esc_imaging_1a mls/mls_hcl_v5 mlsHclV5Day hClToday daily
do_sync esc_imaging_1a mls/mls_hno3_v5 mlsHno3V5Weekly hNO37Day daily
do_sync esc_imaging_1a mls/mls_hno3_v5 mlsHno3V5Day hNO3Today daily
do_sync esc_imaging_1a mls/mls_n2o_v5 mlsN2oV5Weekly n2O7Day daily
do_sync esc_imaging_1a mls/mls_n2o_v5 mlsN2oV5Day n2OToday daily
do_sync esc_imaging_1a mls/mls_o3_v5 mlsO3_v5Day o3Today daily
do_sync esc_imaging_1a mls/mls_o3_v5 mlsO3_v5Weekly o37Day daily
