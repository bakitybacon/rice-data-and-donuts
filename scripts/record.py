#!/usr/bin/python3
import os

command = """curl -v -XPOST https://api.airtable.com/v0/apphRH8hymL6SwUPP/Summer%202019 -H "Authorization: &0" -H "Content-Type: application/json" --data '{
  "fields": {
    "Serial": &1,
    "SID": &2,
    "Submitted Time": "&3",
    "Full Name": "&4",
    "Email Address": "&5",
    "Rice NetID": "&6",
    "Rice Affiliation": "&7",
    "School, Department, or Program": "&8",
    "Course Selection": "&9"
  }
}'"""

fields = []

with open("key.txt") as f:
    command = command.replace("&0", f.readline().strip())

with open("record.txt") as f:
    line = f.readline()
    while line:
        fields.append(line.strip())
        line = f.readline()

for idx in range(len(fields)):
    command = command.replace("&"+str(idx+1), fields[idx])

os.system(command)
