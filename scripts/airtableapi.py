import os
import requests
import pandas as pd
import json

def read_response(recordlist):
    """
    Takes in a list of records and returns a
    pandas DataFrame that represents it.
    """
    records = []
    for record in recordlist:
        newrec = record['fields']
        newrec['id'] = record['id']
        newrec['createdTime'] = record['createdTime']
        records.append(newrec)

    table = pd.DataFrame.from_records(records)
    return table


def read_all(app, table, key):
    """
    Reads the entirety of the table specified into a
    pandas DataFrame. The data is indexed by a unique
    id given by the airtable server.
    """
    url = "https://api.airtable.com/v0/"+app+"/"+table
    headers = {"Authorization": "Bearer "+key}
    params = {}

    response = requests.get(url, headers=headers).json()
    table = read_response(response['records'])

    while 'offset' in response:
        params={'offset':response['offset']}
        response = requests.get(url, headers=headers, params=params).json()
        newtable = read_response(response['records'])
        table = pd.concat([table, newtable])

    return table.set_index('id')

def wrap_fields(record):
    """
    A helper method to add the 'fields' key to
    create and update requests.
    """
    newrecord = {'fields':record}
    return newrecord

def create(record, app, table, key):
    """
    Given record as a dictionary with format column -> val,
    add a new record to the table. Returns the response json.
    """
    if 'fields' not in record:
        record = wrap_fields(record)
    url = "https://api.airtable.com/v0/"+app+"/"+table
    headers = {"Authorization": "Bearer "+key, "Content-Type": "application/json"}

    response = requests.post(url, headers=headers, data=json.dumps(record)).json()
    return response

def delete(record, app, table, key):
    """
    Deletes the record from the table. Requires that record is a dictionary
    with a key 'id'.
    """
    if 'id' not in record:
        return

    id = record['id']

    url = "https://api.airtable.com/v0/"+app+"/"+table+"/"+id
    headers = {"Authorization": "Bearer "+key, "Content-Type": "application/json"}

    response = requests.delete(url, headers=headers).json()
    return response

def update(record, app, table, key):
    """
    Updates the record in the table. Requires that record is a dictionary
    with a key 'id'.
    """
    if 'id' not in record:
        return

    id = record['id']

    if 'fields' not in record:
        record = wrap_fields(record)

    record = {'fields':record['fields']} #drop all other keys

    url = "https://api.airtable.com/v0/"+app+"/"+table+"/"+id
    headers = {"Authorization": "Bearer "+key, "Content-Type": "application/json"}

    response = requests.patch(url, headers=headers, data=json.dumps(record)).json()
    return response
