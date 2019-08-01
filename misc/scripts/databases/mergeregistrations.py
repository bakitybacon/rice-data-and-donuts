#!/usr/bin/python3
import airtableapi as at
import re
import sys

coursemapping = {
    'Python Data Visualization with Matplotlib: Tuesday July 9 2019 @ 1-2:30 p.m.' : 'PythonVis',
    'Python for Beginners: Friday May 31 2019 @ 10-11:30 a.m.': 'Python',
    '[Class is Full, registration closed] June 18 2019 @ 10-11:30p.m.': 'DataManagement',
    'Introduction to R: Tuesday July 2 2019 @ 1-2:30 p.m.': 'RIntro',
    'Introduction to Effective Data Visualization: Wednesday June 12 2019 @ 10-11:30 a.m.': 'Effective',
    'Colors in Data Visualization: Wednesday June 19 2019 @ 10-11:30 a.m': 'Color',
    'Python-Pandas: Tuesday June 11 2019 @ 10-11:30 a.m.': 'Pandas',
    'R Visualization and Data Manipulation: Monday July 8 2019 @ 9-10:30 a.m.': 'Rvis',
    'The Absolute Basics of Jupyter Notebooks: Friday July 12 2019 @ 10-11 a.m.': 'Jupyter',
    'Introduction to GitHub: Tuesday June 18 2019 @ 2-3:30 p.m.': 'GitHub',
    'Using Rice\'s Private VM Cloud: Tuesday June 25 2019 @ 2-3:30 p.m.': 'VMCloud',
    'Introduction to Time Series Analysis: Thursday Aug 1 2019 @ 10-11 a.m.': 'TimeSeries'}

# reverse the course mapping so we can find by short key as well
tablemapping = {}

for key, val in coursemapping.items():
    tablemapping[val] = key

base = "approTOf3L5vt6c3Y"
table = "Course Data"

def make_dict(record, column):
    """
    Makes the row palatable for the api.
    """
    return {'id': record['id'], "fields": {column: record[column]}}

def merge_registrations(app, table, column, coursetable, key):
    """
    Updates registrations in the main table based on marked registration
    in class.
    """
    basetable = at.read_all(app, table, key)
    basetable = basetable.reset_index()
    coursetab = at.read_all(app, coursetable, key)

    merged = basetable.merge(coursetab, on="Email Address", suffixes=("_l", "_r"), how="inner")
    merged = merged[["id", column+"_r"]]
    merged = merged.rename(columns={column+"_r": column})
    merged = merged[["id", column]]

    merged.apply(lambda rec: at.update(make_dict(dict(rec), column), app, table, key), axis=1)

with open("key.txt") as f:
    key = f.readline().strip()

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
