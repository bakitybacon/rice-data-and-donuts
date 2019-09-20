#!/usr/bin/env python3
import airtableapi as at
import re
import sys

fields = ["Serial", "SID", "Submitted Time", "Full Name",
    "Email Address", "Rice NetID", "Rice Affiliation",
    "School, Department, or Program"]
needed = ["Full Name", "Email Address", "Rice Affiliation", 
  "School, Department, or Program"]

courses = ["Python for Beginners: Tuesday Sept 17 2019 @ 1-2:30 p.m.",
	"Python for Beginners: Thursday Sept 18 2019 @3-4:30 p.m.",
	"Introduction to GitHub: Tuesday Sept 17 2019 @ 6-7:30 p.m.",
	"Introduction to GitHub: Thursday Sept 19 2019 @3-4:30 p.m.",
	"Introduction to R: Wednesday Sept 18 2019 @ 1-2:30 p.m.",
	"Non-Programmer's Introduction to Rice’s Computing Infrastructure: Virtual Machines, Storage, and Supercomputing: Thursday Sept 19, 2019 @ 2:3:30 p.m.",
	"Using Excel to Manage and Analyze Data: Friday Sept 20 2019 @ 10-11:30 a.m.",
	"Python-Pandas: Tuesday Sept 24 2019 @ 3-4:30 p.m.",
	"Introduction to Time Series Analysis: Tuesday Sept 24 2019 @ 5:00-6:30 p.m.",
	"Introduction to Time Series Analysis: Wednesday Sept 25 2019 @ 12-1:30 p.m.",
	"Using Excel to Manage and Analyze Data: Wednesday Sept 25 2019 @ 10-11:30 a.m.",
	"Python-Pandas: Thursday Sept 26 2019 @ 1-2:30 p.m.",
	"Introduction to R: Friday Sept 27 2019 @ 3:30-5:00 p.m.",
	"Python Data Visualization with Matplotlib: Monday Sept 30 2019 @ 2-3:30 p.m.",
	"Python Data Visualization with Matplotlib: Tuesday Oct 1 2019 @ 10-11:30 a.m.",
	"Excel Charts Tips for Visualizing Data: Friday Oct 4 2019 @ 10-11:00 a.m.",
	"R Visualization and Data Manipulation: Monday Oct 7 2019 @ 11:30-1:00 p.m.",
	"Web Scraping with Python: Tuesday Oct 8 2019 @2:30-3:45 p.m.",
	"R Visualization and Data Manipulation: Wednesday Oct 9 2019 @ 1-2:30 p.m.",
	"Jupyter Notebook for Beginners: Thursday Oct 17 2019 @10-11:00 a.m.",
	"R Visualization with ggplot2: Tuesday Oct 22 2019 @2-3:30 p.m.",
	"Introduction to Access: Thursday Oct 24 2019 @10-11:30 a.m.",
	"Introduction to Data Management: Friday Oct 25 2019 @10-11:30 a.m.",
	"Introduction to SPSS: Tuesday Oct 29 2019 @ 1-2:30 p.m.",
	"Introduction to Shell Scripting in Bash: Tuesday Oct 29 2019 @ 3-4:30 p.m.",
	"Introduction to TensorFlow: Thursday Nov 14 2019 @ 2-3:30 p.m.",
	"Introduction to SQL: Tuesday Nov 19 2019 @ 1-2:30 p.m."]

table = "Course Data"
with open("key.txt") as f:
    key = f.readline().strip()
with open("base.txt") as f:
    base = f.readline().strip()

def make_table(course, app, table, key):
    """
    Finds current registrations for each course and spits out a csv
    containing the Full Name, Email Address, Rice Affiliation, and 
    Department of each registrant.
    """
    recordframe = at.read_all(app, table, key)

    coursedata = recordframe[recordframe[course] == "X"]
    neededplus = list(needed)
    neededplus.append(course)
    coursedata = coursedata[neededplus]
    coursedata.to_csv(course+".csv", index=False)

if not key:
    print("Could not read key!")
    exit(1)

if sys.argv[1] == "all":
    for course in courses:
        make_table(course, base, table, key)
    exit(0)

if not sys.argv[1]:
    print("Please specify a table to create!")
    exit(1)

make_table(sys.argv[1], base, table, key)
