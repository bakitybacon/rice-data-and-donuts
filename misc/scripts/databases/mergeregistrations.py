#!/usr/bin/env python3
import airtableapi as at
import re
import sys

coursemapping = {"Python for Beginners: Tuesday Sept 17 2019 @ 1-2:30 p.m." : "PythonBeginners1",
	"Python for Beginners: Wednesday Sept 18 2019 @ 3-4:30 p.m." : "PythonBeginners2",
	"Introduction to GitHub: Tuesday Sept 17 2019 @ 6-7:30 p.m." : "GitHub1",
	"Introduction to GitHub: Thursday Sept 19 2019 @3-4:30 p.m." : "GitHub2",
	"Introduction to R: Wednesday Sept 18 2019 @ 1-2:30 p.m.": "IntroR1",
	"Non-Programmer's Introduction to Rice's Computing Infrastructure: Virtual Machines, Storage, and Supercomputing: Thursday Sept 19, 2019 @ 2:3:30 p.m.": "VMCloud",
	"Using Excel to Manage and Analyze Data: Friday Sept 20 2019 @ 10-11:30 a.m.": "Excel1",
	"Python-Pandas: Tuesday Sept 24 2019 @ 3-4:30 p.m.": "Pandas1",
	"Introduction to Time Series Analysis: Tuesday Sept 24 2019 @ 5:00-6:30 p.m." : "TimeSeries1",
	"Introduction to Time Series Analysis: Wednesday Sept 25 2019 @ 12-1:30 p.m." : "TimeSeries2",
	"Using Excel to Manage and Analyze Data: Wednesday Sept 25 2019 @ 10-11:30 a.m.": "Excel2",
	"Python-Pandas: Thursday Sept 26 2019 @ 1-2:30 p.m.": "Pandas2",
	"Introduction to R: Friday Sept 27 2019 @ 3:30-5:00 p.m.": "IntroR2",
	"Python Data Visualization with Matplotlib: Monday Sept 30 2019 @ 2-3:30 p.m.": "Matplot1",
	"Python Data Visualization with Matplotlib: Tuesday Oct 1 2019 @ 1-2:30 p.m.": "Matplot2",
	"Excel Charts Tips for Visualizing Data: Friday Oct 4 2019 @ 10-11:00 a.m." :  "ExcelVisualize",
	"R Visualization and Data Manipulation: Monday Oct 7 2019 @ 11:30-1:00 p.m.": "RViz1",
	"Web Scraping with Python: Tuesday Oct 8 2019 @2:30-3:45 p.m.": "WebScraping",
	"R Visualization and Data Manipulation: Wednesday Oct 9 2019 @ 1-2:30 p.m.": "RViz2",
	"Jupyter Notebook for Beginners: Thursday Oct 17 2019 @10-11:00 a.m.": "Jupyter",
	"R Visualization with ggplot2: Tuesday Oct 22 2019 @2-3:30 p.m.": "ggplot",
	"Introduction to Access: Thursday Oct 24 2019 @10-11:30 a.m." : "Access",
	"Introduction to Data Management: Friday Oct 25 2019 @10-11:30 a.m.": "DataManagement",
	"Introduction to SPSS: Tuesday Oct 29 2019 @ 1-2:30 p.m.": "SPSS",
	"Introduction to Shell Scripting in Bash: Tuesday Oct 29 2019 @ 3-4:30 p.m.": "Bash",
	"Introduction to TensorFlow: Thursday Nov 14 2019 @ 2-3:30 p.m.": "TensorFlow",
	"Introduction to SQL: Tuesday Nov 19 2019 @ 1-2:30 p.m.": "SQL"}

# reverse the course mapping so we can find by short key as well
tablemapping = {}

for key, val in coursemapping.items():
    tablemapping[val] = key

with open("base.txt") as f:
    base = f.readline().strip()
with open("key.txt") as f:
    key = f.readline().strip()
table = "Course Data"

def make_dict(record, column):
    """
    Makes the row palatable for the api.
    """
    return {'id': record['id'], "fields": {column: record[column]}}

def merge_registrations(app, table, column, coursetable, key):
    """
    Updates registrations in the main table and course tables 
    based on marked registration in class.
    """
    print(coursecol)

    basetable = at.read_all(app, table, key)
    basetable = basetable.reset_index()
    coursetab = at.read_all(app, coursetable, key)

    # copy attendance information from course tables to main table
    merged = basetable.merge(coursetab, on="Email Address", suffixes=("_l", "_r"), how="inner")
    merged = merged[["id", column+"_r"]]
    merged = merged.rename(columns={column+"_r": column})
    merged = merged[["id", column]]

    merged.apply(lambda rec: at.update(make_dict(dict(rec), column), app, table, key), axis=1)

    basetable = at.read_all(app, table, key)

    # copy course registration information from main table to course table
    sidemerged = coursetab.merge(basetable, on="Email Address", suffixes=("_l", ""), how="right")
    sidemerged = sidemerged[(sidemerged[column] == "X") & (sidemerged[column+"_l"].isnull())]
    sidemerged = sidemerged[["Full Name", "Email Address", "Rice Affiliation", "School, Department, or Program", column]]
    sidemerged = sidemerged.iloc[1:]
    print(sidemerged)
    if len(sidemerged) == 0:
        return
    sidemerged.apply(lambda rec: print(rec), axis=1)
    sidemerged.apply(lambda rec: at.create(dict(rec), app, coursetable, key), axis=1)

if not key:
    print("Could not read key!")
    exit(1)

if "all" in sys.argv:
    for coursecol, coursetab in coursemapping.items():
        merge_registrations(base, table, coursecol, coursetab, key)
    exit(0)

tab = sys.argv[1]

if not tab:
    print("Usage: ./mergeregistrations.py tab")
    exit(1)

merge_registrations(base, table, tablemapping[tab], tab, key)
