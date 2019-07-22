# Database Management Scripts

* airtableapi.py -> Uses the requests Python library to access and modify Airtable (https://airtable.com) databases quickly and easily. It's very lightweight, but does implement the features listed on their official API page. Necessary for the following to function.
* maketable.py -> Run before a class takes place to create a table of registrants for a course. Run ./maketable.py (CLASS NAME) to build a table. It will spit out a csv that can be imported into Airtable.
* record.py -> Called in order to add a new record to the Airtable database of course registrations.
* mergeregistrations.py -> Ensures that the registration information in the main table is up to date with the registration information in the table for each course. Use ./mergeregistrations.py all to update all tables, or ./mergeregistrations.py (SOURCE TABLE NAME) to integrate information from the source table back into the combined database.


