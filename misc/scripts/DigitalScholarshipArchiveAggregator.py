#!/home/infrared/anaconda3/bin/python3
import requests
import json
import pandas as pd
from bs4 import BeautifulSoup as bs
import sys

def get_community(jsonroot, name):
    """
    Recursively find a community in dictionary jsonroot 
    with the given name.
    Returns None if no match is found.
    """
    community = None
    for subcommunity in jsonroot['community']:
        if subcommunity['name'] == name:
            return subcommunity
        subsearch = get_community(subcommunity, name)
        if subsearch:
            return subsearch
        
    return None

def get_all_collections(jsonroot):
    """
    Recursively find all collections in dictionary jsonroot.
    Returns a dataframe with columns id, name, and handle.
    """
    ids = []
    names = []
    handles = []
    
    for collection in jsonroot['collection']:
        ids.append(collection['id'])
        names.append(collection['name'])
        handles.append(collection['handle'])
        
    collections = pd.DataFrame({'id': ids, 'name': names, 'handle': handles})
    
    for subcommunity in jsonroot['community']:
        subframe = get_all_collections(subcommunity)
        collections = pd.concat([collections, subframe], ignore_index=True)
    
    return collections

def aggregate_community(communityName, verbose=False):
    """
    Aggregates statistics for all collections present in the community
    communityName. Returns a pandas series of views by collection name.
    """

    #### Step 1: Find the community of interest.


    # the hierarchy page contains the entire tree-like structure of the Digital Scholarship Archive,
    #   where a community is an interior node and a collection is a leaf with associated file data.
    hierarchyurl = 'https://scholarship.rice.edu/rest/hierarchy'

    response = requests.get(hierarchyurl)
    data = json.loads(response.text)
    communitydata = get_community(data, communityName)

    #### Step 2: Extract all collections.

    allcollections = get_all_collections(communitydata)
    allcollections['url'] = 'https://scholarship.rice.edu/rest/collections/' + allcollections['id'] + '/items'

    handles = []
    collectionnames = []
    collectionurls = []

    for idx, row in allcollections.iterrows():
        url = row['url']
        
        response = requests.get(url)
        jresponse = json.loads(response.text)

        # annoyingly, there are collections with no items.
        #  this test will throw out such collections.
        if len(jresponse) == 0:
            continue

        data = jresponse[0]
        handles.append(data['handle'].split("/")[1])
        collectionnames.append(row['name'])
        collectionurls.append(url)
        
    allcollections = pd.DataFrame({'handle': handles, 'collectionname': collectionnames, 'link': collectionurls})

    #### Step 3: Find all item records that live in any collection. Tag each item with the collection it came from.

    combine = []
    parentcollections = []
    names = []

    pagesize = 1000

    for idx, row in allcollections.iterrows():
        # handle pagination
        offset = 0
        stop = False
        
        while not stop:
            # get a page of data
            response = requests.get(row['link'], params={'limit': pagesize, 'offset': offset})
            items = json.loads(response.text)

            # extract item handle, item name, and tag with parent collection.
            for item in items:
                itemno = item['handle'].split('/')[1]
                combine.append(itemno)
                names.append(item['name'])
                parentcollections.append(row['handle'])
                
            # if we have fewer than pagesize records, then we are done.
            #  otherwise, get the next page.
            if len(items) < pagesize:
                stop = True
            else:
                offset += pagesize

    allitems = pd.DataFrame({'itemhandle': combine, 'handle': parentcollections, 'name': names})
    allitems['link'] = 'https://scholarship.rice.edu/handle/1911/' + allitems['itemhandle'] + '/statistics'

    #### Step 4: Query each item record to find all associated files, and for each file, extract how many views it has.

    allrecords = pd.DataFrame({"itemhandle": [], "filename":[], "views": []})

    for idx, row in allitems.iterrows():
        url = row['link']
        r = requests.get(url)
        page = r.text
        soup = bs(page,'html.parser')
       
        res = soup.find_all('table', {'id':"aspect_statistics_StatisticsTransformer_table_list-table"})
        headings = soup.find_all('h3', class_='ds-table-head')
       
        labels = []
        data = []
        handles = []
        
        index = 0
       
        for heading in headings:
            if heading.string == 'File Visits':
                record = res[index]
                labels.extend(list(map(lambda rec: rec.string, record.find_all('td', class_='labelcell'))))
                data.extend(list(map(lambda rec: rec.string, record.find_all('td', class_='datacell'))))
                handles.extend(list(map(lambda rec: row['handle'], record.find_all('td', class_='datacell'))))
            index += 1
           
        itemfiles = pd.DataFrame({'itemhandle': handles, 'filename': labels, 'views': data})
        allrecords = pd.concat([allrecords, itemfiles], ignore_index=True)

    #### Step 5: Merge the tables we have created to produce a final dataframe with only File Name, Views, and Collection Name as columns.

    final = allrecords.merge(allitems.merge(allcollections, on='handle'),on='itemhandle')
    final = final[['filename', 'views', 'collectionname']]
    final['views'] = final.views.astype(int)

    #### Step 6: Group by collection name and aggregate the number of views for all files in each community.

    if verbose:
        print('counts:')
        print(final.groupby('collectionname').filename.count())
    return final.groupby('collectionname').views.sum()

# CLI: passing by command line argument
args = sys.argv
if 'python' in sys.argv[0]:
    args = args[1:]

if len(args) > 1 and args[1]:
    aggregate_community(args[1])

else:
    # CLI: passing by stdin
    community = input('Enter Community Name Here >')
    aggregate_community(community)

