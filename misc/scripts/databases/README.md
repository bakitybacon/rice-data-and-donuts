# Database Management Scripts

* airtableapi.py -> Uses the requests Python library to access and modify Airtable (https://airtable.com) databases quickly and easily. It's very lightweight, but does implement the features listed on their official API page. Necessary for the following to function.
* maketables.py -> Run before a class takes place to create a table of registrants for a course. 
* record.py -> Called in order to add a new record to the Airtable database of course registrations.
* mergeregistrations.py -> Ensures that the registration information in the main table is up to date with the registration information in the table for each course.


