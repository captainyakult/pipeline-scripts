import os
import sys
import glob
import json
import gzip
from datetime import date, timedelta

# bad combos mode doesn't generate a file.
# It's printing out whether there are less than 6 files with the same date.
bad_combos_mode = "b" in sys.argv

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
def scan_dataset(base_path, mode):
    print(f"Generating dataset_manifest.json for {base_path}...")
    all_files = []
    years = get_years(base_path)

    # glob together all filenames in all year folders
    for y in years:
        year_files = glob.glob(os.path.join(base_path, str(y), "*"))
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

    if bad_combos_mode:
        while current != last:
            if date_to_file(current) in all_files:
                if all_files.count(date_to_file(current)) < 6:
                    print("rm " + base_path + "/" + date_to_file(current) + "*")
            current = current + timedelta(days=1)
    else:
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
        output_data = {
            "datasetName": os.path.basename(os.path.normpath(base_path)),
            "generated": str(date.today()),
            "frequency": mode,
            "startDate": str(first),
            "endDate": str(last),
            "missingDates": missing_dates,
        }

        # Write data to json file.
        with open(base_path + "/dataset_manifest.json", "w") as out_file:
            json.dump(
                output_data,
                out_file,
                default=str,
                indent=4,
                ensure_ascii=False,
            )

        # If we ever decide to gzip, this should work.
        # with gzip.open(path + "/manifeest_gzip", "w") as fout:
        #     fout.write(json.dumps(output_data, default=str).encode("utf-8"))
        print("Dataset manifest generation complete.")


if len(sys.argv) > 0:
    print(sys.argv)
    base_path = sys.argv[1]
    mode = sys.argv[2]

    scan_dataset(base_path, mode)
