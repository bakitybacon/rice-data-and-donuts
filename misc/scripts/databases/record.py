#!/usr/bin/python3
import airtableapi as at
import re

fields = ["Serial", "SID", "Submitted Time", "Full Name",
    "Email Address", "Rice NetID", "Rice Affiliation",
    "School, Department, or Program"]

base = "approTOf3L5vt6c3Y"
table = "Course Data"

def process_duplicates(app, table, key):
    """
    Condenses all duplicates in the table so we get one record
    per person with all registrations.
    """
    recordframe = at.read_all(app, table, key)
    namegroups = recordframe.groupby('Email Address').groups
    duplicates = list(filter(lambda person : len(namegroups[person]) > 1, namegroups.keys()))
    for duplicator in duplicates:
        records = recordframe[recordframe['Email Address'] == duplicator]
        records = records.sort_values(by='createdTime')
        delids = records.index[:-1]
        outid = records.index[-1] # last one is probably most corrected version?
        records = records.drop(columns=fields)
        updatefields = {}
        for col in records.columns:
            if sum(records[col] == 'X') > 0:
                updatefields[col] = 'X'
        newrecord = {'id': outid, 'fields': updatefields}
        at.update(newrecord, app, table, key)
        for delid in delids:
            at.delete({"id": delid}, app, table, key)

with open("key.txt") as f:
    key = f.readline().strip()

if not key:
    print("Could not read key!")
    exit(1)

record = {}
i = 0
registrations = ""

with open("record.txt") as f:
    line = f.readline().strip()
    while line:
        if i == len(fields):
            registrations = line
        else:
            if i <= 1:
                record[fields[i]] = int(line)
            else:
                record[fields[i]] = line
        i = i + 1
        line = f.readline().strip()

# use consistent format for dates by removing day of week
record['Submitted Time'] = record['Submitted Time'][5:]

# if we see the course with a 2 - 3:30 thing, condense it
registrations = re.sub(r"(\d) - (\d)", r"\1-\2", registrations)

# there's a weird apostrophe in a class title. remove it.
registrations = re.sub('’', "'", registrations)

# if more than one class has been selected, get an array
# remove first hyphen and split on all remaining hyphens
if registrations[0] == '-':
	classes = registrations[2:].split(" - ")
else:
	classes = [registrations]

# mark that we've entered
for clazz in classes:
    record[clazz.strip()] = "X"

newcomer = at.create(record, base, table, key)
process_duplicates(base, table, key)

if 'error' in newcomer:
    print(newcomer)
    exit(1)
