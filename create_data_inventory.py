import os
import sys
import glob
from datetime import date
from datetime import timedelta

bad_combos_mode = 'b' in sys.argv

#returns a list of year integers in a current folder
def getyears(path):
	years = []
	folders =  glob.glob(path+"/*")
	for f in folders:
		try:
			f = f.split("/")[-1]
			int(f)
			years.append(f)
		except:
			pass
	years.sort()
	return years

#returns a date from a yy/mmdd format string
def file_to_date(filename):
	year = "20"+filename.split("/")[0]
	month = filename.split("/")[1][0:2]
	day = filename.split("/")[1][2:4]
	return date(int(year),int(month),int(day))

#returns a yy/mmdd format string
def date_to_file(date):
	return str(date.year)[2:4]+"/"+"%02d"%date.month+"%02d"%date.day

def checkfolder(path, mode):
	print("Generating data_inventory.txt for " + path)
	files=[]
	years = getyears(path)
	print("Years: " + str(years))

	#glob together all filenames in all year folders
	for y in years:
		files = files + glob.glob(path+"/"+str(y)+"/*")

	#format filenames into yy/mmdd dates

	files = [f.split("/")[-2]+"/"+f.split("/")[-1].split("_")[0].replace(".png", "") for f in files]

	files.sort()
	print("First Date: " + files[0])
	print("Late Date: " + files[-1]);

	first =  file_to_date(files[0])
	last = file_to_date(files[-1])
	while files.count(date_to_file(last)) < 2:
		last = last - timedelta(days=1)
	current = first
	
	missing_dates = []

	if bad_combos_mode:
		while current != last:
			if date_to_file(current) in files:
				if(files.count(date_to_file(current)) < 6):
					print('rm ' + path + '/' + date_to_file(current) + '*')
			current = current + timedelta(days=1)
	else:
		#iterate between start and end, flag all dates missing from the 'files' list
		while current != last:
			if files.count(date_to_file(current)) < 2:
				if (mode == "monthly" and current.day == 1) or (mode == "monthly grace" and current.day <= 4) or mode == "daily" :
					missing_dates.append(current)
			current = current + timedelta(days=1)

		#output our missing dates to the missing date file
		outfile = open(path+"/data_inventory.txt",'w');
		outfile.write("This file is automatically generated by data_inventory.py. Last generation: " + str(date.today())+"\n")
		outfile.write(str(first)+"-"+str(last))
		for m in missing_dates:
			outfile.write("\n"+str(m))
		outfile.close();

if len(sys.argv) > 0:
	folder = sys.argv[1]
	mode = sys.argv[2]
	checkfolder(folder, mode)
else:
	with open(os.path.join(os.path.dirname(__file__), "to_check.txt")) as f:
		mode = 'daily'
		for line in f:
			this_line = line.strip()
			print(this_line)
			if this_line == "daily" or this_line == "monthly" or this_line == "monthly grace":
				mode = this_line
			else:
				if this_line != "":
					checkfolder('/var/server/data' + this_line, mode);