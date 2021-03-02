"""
Clean up the 10 megafile pieces to contain only what I need, without duplicates and with retweets
"""

import pandas as pd
import glob
import ndjson
import re
import string

mega_path = glob.glob('/home/commando/data_processed/megafiles/da_created_october2020/ultimate_megafile_pieces/*.ndjson')


i = 0

remove = string.punctuation
remove = remove.replace("#", "") # don't remove hashtags
pattern = r"[{}]".format(remove) # create the pattern

def retrieve_retweets(row):
    if re.match("^RT", row["text"]):
        RT = True
    else:
        RT = False
    return RT

def remove_retweets(ori_data):
    patternDel = "^RT"
    filtering = data['text'].str.contains(patternDel)
    removed_RT = ori_data[~filtering].reset_index(drop=True)
    
    return removed_RT

def extract_usernames(row):
    username_list = list(re.findall(r'@(\S*)\w', row["text"]))
    return username_list

def extract_screenname(row):
    try:
        username = row["user"]["screen_name"]
    except:
        username = 1
    return username

for file in mega_path:
    testset = []

    print("Opening " +  re.findall(r'file\d\d', file)[0])

    with open(file, 'r') as myfile:
        head=myfile.readlines()

    for i in range(len(head)):
        try:
            testset.extend(ndjson.loads(head[i]))
        except:
            print("err in ", file)
            pass

    data = pd.DataFrame(testset)
    del testset
    print("Begin processing " +  re.findall(r'file\d\d', file)[0])

    df = data
    #df["mentioned_users"] = df.apply(lambda row: extract_usernames(row), axis = 1)
    df["retweets"] = df.apply(lambda row: retrieve_retweets(row), axis = 1)
    df["screen_names"] = df.apply(lambda row: extract_screenname(row), axis = 1)
    
    df0 = df[["created_at", "id_str", "text", "retweets", "screen_names"]]
    
    #################
    print("Length of whole data:     ",len(df0))
    df0 = df0.drop_duplicates()
    print("Length of no duplicates:  ", len(df0))
    print("How many unique users:    ", len(set(df0.id_str)))
    print("How many dates:           ", len(set(df0.created_at)))
    print("Number of retweets:       ", len(df0[df0["retweets"] == True]))
    print("Number of unique retweets:", len(set(df0[df0["retweets"] == True].text)))
    #################
    
    filename = "../data/" + re.findall(r'file\d\d', file)[0] + ".csv"
    df0.to_csv(filename, index = False)
    del df0
    print("Save of " + re.findall(r'file\d\d', file)[0] + " done")
    print("-------------------------------------------\n")
    
    i = i+1