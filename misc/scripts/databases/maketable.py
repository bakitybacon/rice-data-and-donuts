#!/usr/bin/python3
import airtableapi as at
import re
import sys

fields = ["Serial", "SID", "Submitted Time", "Full Name",
    "Email Address", "Rice NetID", "Rice Affiliation",
    "School, Department, or Program"]
needed = ["Full Name", "Email Address", "Rice Affiliation", 
  "School, Department, or Program"]

courses = ['Python Data Visualization with Matplotlib: Tuesday July 9 2019 @ 1-2:30 p.m.', 'Python for Beginners: Friday May 31 2019 @ 10-11:30 a.m.', '[Class is Full, registration closed] June 18 2019 @ 10-11:30p.m.', 'Introduction to R: Tuesday July 2 2019 @ 1-2:30 p.m.', 'Introduction to Effective Data Visualization: Wednesday June 12 2019 @ 10-11:30 a.m.', 'createdTime', '[Class is Full, registration closed] June 20 2019 @10-11:30 a.m.', 'Colors in Data Visualization: Wednesday June 19 2019 @ 10-11:30 a.m', 'Python-Pandas: Tuesday June 11 2019 @ 10-11:30 a.m.', 'R Visualization and Data Manipulation: Monday July 8 2019 @ 9-10:30 a.m.', 'The Absolute Basics of Jupyter Notebooks: Friday July 12 2019 @ 10-11 a.m.', '[Class is Full, registration closed] Using Excel to Manage and Analyze Data: Thursday June 13 2019 @ 10-11:30 a.m.', 'Introduction to GitHub: Tuesday June 18 2019 @ 2-3:30 p.m.', 'Introduction to Time Series Analysis: Thursday Aug 1 2019 @ 10-11 a.m.', "Using Rice's Private VM Cloud: Tuesday June 25 2019 @ 2-3:30 p.m."]

base = "approTOf3L5vt6c3Y"
table = "Course Data"

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

with open("key.txt") as f:
    key = f.readline().strip()

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
