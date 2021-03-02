"""
Now that I have the followers and friends of the 30 users, I will extract the tweets of the leaders and their followers
"""


#############################################
###    INTERSECTIONS FOR ALL X USERS      ###
#############################################

import pandas as pd
import glob
import re
import csv
from icecream import ic

def extract_screenname(row):
    try:
        username = row["from_user_id"]
    except:
        username = 1
    return username
"""
fname = "../usernames.txt"
f_users = open(fname, 'r') 
users = f_users.readlines()

user_list = []
for element in users:
    user_list.append(element.strip())
"""
print("Compose dataframe of users followers")

user_list = ["TobiasPetersen_", "AllanSchmidt", "torstenfroling", "gaard_Hans", "GringoWalking"]

for user in user_list:
    username = user.lower()
    
    print("User:       ", username)

    file = "../data/" + username + "/network/followers.ndjson"

    data = pd.read_json(file, lines=True)
    #friends = data.screen_name
    followers_ids = data.id_str
    print(followers_ids)
    
    print("Length of friends: ", len(followers_ids))
    print(followers_ids[0:3])

    print("Retrieved friends!")
    
    ### Retrieve the user himself
    file = "../data/" + username + "/profile.json"
    data = pd.read_json(file)
    user_id = pd.Series(data.id_str[0])
    print(user_id)
    ic(type(user_id))
    ic(type(followers_ids))
    # Append user himself to the end of the series. Now I should get all tweets of him and his followers <3
    followers_ids = followers_ids.append(user_id).reset_index(drop=True)
    print("Appended user himself!")

    mega_path = glob.glob('/data/001_twitter_hope/preprocessed/da/td_2020*.ndjson')

    for file in mega_path:
        file_name = re.findall(r'(td.*)\.ndjson', file)[0]
        print("Opening " +  file_name)
        
        df = pd.read_json(file, lines=True)

        print("Begin processing of " + file_name)

        df["userid"] = df.apply(lambda row: extract_screenname(row), axis = 1)
        print("First screen names\n", df["userid"][0:3])
        
        df = df[["created_at", "id", "text", "userid"]].drop_duplicates()

        ##### --- #####
        print("Begin results appending")
        df_user = df[df['userid'].isin(followers_ids)]#.drop_duplicates()
        
        if len(df_user) > 0:
            # Separate file created for each newspaper
            filename2 = "../group1_ori/" + user + "_" + file_name + ".csv"

            with open(filename2, 'a+', newline='') as graphFile:
                graphFileWriter = csv.writer(graphFile)
                for row in range(0,len(df_user)):
                    graphFileWriter.writerow(df_user.iloc[row])
    
            print("Save of " + " file " + file_name + " done")
            print("-------------------------------------------\n")
            del df_user
        else:
            print("No data")
            print("-------------------------------------------\n")