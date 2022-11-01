import os
import sys
import glob
import json
import gzip
from datetime import date, timedelta


# Creates a list of year integers in the current path
def get_years(path):
    years = []
    folders = glob.glob(path + "/*")
    for f in folders:
        try:
            year = int(os.path.basename(f))
            years.append(year)
        except:
            pass
    years.sort()
    return years


# Creates a date from a yy/mmdd format string.
def file_to_date(filename):
    slash_split = filename.split("/")
    year = f"20{slash_split[0]}"
    month = slash_split[1][0:2]
    day = slash_split[1][2:4]
    return date(int(year), int(month), int(day))


# Creates a yy/mmdd format string.
def date_to_file(date):
    return f"{str(date.year)[2:4]}/{date.month:02d}{date.day:02d}"


# Performs a scan of the dataset
def scan_dataset(dataset_path, mode):
    print(f"Generating dataset info for {dataset_path}...")
    all_files = []
    years = get_years(dataset_path)

    # glob together all filenames in all year folders
    for y in years:
        year_files = glob.glob(os.path.join(dataset_path, str(y), "*"))
        all_files.extend(year_files)

    # Extract filenames into yy/mmdd dates and sort
    all_files = [
        f.split("/")[-2] + "/" + f.split("/")[-1].split("_")[0] for f in all_files
    ]
    all_files.sort()

    first = file_to_date(all_files[0])
    last = file_to_date(all_files[-1])

    # We are assuming the files have been 'dated' using UTC.

    # Determine the last date with 2 or more entries
    while all_files.count(date_to_file(last)) < 2:
        last = last - timedelta(days=1)

    current = first
    missing_dates = []

    # iterate between start and end, flag all dates missing from the 'all_files' list
    while current != last:
        if all_files.count(date_to_file(current)) < 2:
            if (
                (mode == "monthly" and current.day == 1)
                or (mode == "monthly grace" and current.day <= 4)
                or mode == "daily"
            ):
                missing_dates.append(current)
        current = current + timedelta(days=1)

    # Determine output data dict.
    return {
        "generated": str(date.today()),
        "frequency": mode,
        "startDate": str(first),
        "endDate": str(last),
        "missingDates": missing_dates,
    }


def write_manifest(output_data):

    print(f"Writing dataset_manifest.json...")
    # Write data to json file.
    with open("datasets_manifest.json", "w") as out_file:
        json.dump(
            output_data,
            out_file,
            default=str,
            indent=4,
            ensure_ascii=False,
        )

    # If we ever decide to gzip, this should work.
    # with gzip.open("datasets_manifest", "w") as fout:
    #     fout.write(json.dumps(output_data, default=str).encode("utf-8"))
    print("Dataset manifest generation complete.")


if len(sys.argv) > 0:
    print(sys.argv)

    argList = sys.argv[1].split(",")
    argPairs = [
        (arg, argList[index + 1]) for index, arg in enumerate(argList) if index % 2 == 0
    ]

    output_data = {}
    for argPair in argPairs:
        (dataset_path, mode) = argPair
        dataset_name = os.path.basename(os.path.normpath(dataset_path))
        output_data[dataset_name] = scan_dataset(dataset_path, mode)

    write_manifest(output_data)

# This script is expecting one long string array for an argument.
# Eg. run this in the folder that contains all the dataset folders:
# generate_datasets_manifest.py 'viirsToday,daily,newCo2Monthly,monthly,<datasetName>,<mode>,etc...'
# This will generate a json file in that same folder that will be the manifest for all the datasets, together in one json file.
