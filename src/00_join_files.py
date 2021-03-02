"""
Join the files in old_data into one file per username
"""

import glob
import pandas as pd
import re

### Define Functions ###

def get_df(filenames):
    df = pd.read_csv(filenames[0], header = None)

    i = 0
    for file in filenames[1:]:
        df_0 = pd.read_csv(file, header = None)
        df = df.append(df_0)
        print("Append done: ", i)
        i = i+1

    return df

def clean_dates(df):
    df.iloc[:,0] = pd.to_datetime(df.iloc[:,0], utc=True).dt.strftime('%Y-%m-%d %H:%M:%S')
    return df

## Run these functions
if __name__ == "__main__":
    filenames = glob.glob("../group1_ori/*.csv")
    
    usernames = []
    for file in filenames:
        usernames.append(re.findall(r'..\/group1_ori\/(.*)\_td', file)[0])

    usernames = list(set(usernames))
    
    # Let's just do group 1 and ignore the rest for now
    group1 = ["TobiasPetersen_", "AllanSchmidt", "torstenfroling", "gaard_Hans", "GringoWalking"]
    
    for user in group1:
        user_path = "../group1_ori/" + user + "*.csv"
        fnames = glob.glob(user_path)
        
        filename = "../" + user + "_data.csv"
    
        print("Get data: ", user)
        df = get_df(fnames)
        #print("Start cleaning dates")
        #df = clean_dates(df)
        print("Save file")
        print(df.head())
        df.to_csv(filename, index=False)
        del df
        print("----------")
        