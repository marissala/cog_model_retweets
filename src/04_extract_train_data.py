"""
Get some tweets for training our model - use tweets that do not overlap with my data used in this.
1. Get data for January-March
2. Put that into one dataframe
3. Remove all the rows that are in my dfs

"""

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

mega_path = glob.glob('/data/001_twitter_hope/preprocessed/da/td_202003*.ndjson')

def generate_files():
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
        #df_user = df[df['userid'].isin(followers_ids)]#.drop_duplicates()

        if len(df) > 0:
                # Separate file created for each newspaper
            filename2 = "../without_group1/" + file_name + ".csv"

            with open(filename2, 'a+', newline='') as graphFile:
                graphFileWriter = csv.writer(graphFile)
                for row in range(0,len(df)):
                    graphFileWriter.writerow(df.iloc[row])

            print("Save of " + " file " + file_name + " done")
            print("-------------------------------------------\n")
            del df
        else:
            print("No data")
            print("-------------------------------------------\n")

def get_df(filenames):
    df = pd.read_csv(filenames[0], header=None)

    for file in filenames[1:]:
        df_0 = pd.read_csv(file, header = None)
        df = df.append(df_0)

    df = df.drop_duplicates()
    return df

def join_files(filenames, out_filename):
    print("Get data")
    df = get_df(filenames)
    #print("Start cleaning dates")
    #df = clean_dates(df)
    print("Save file")
    df.to_csv(out_filename, index=False)
    del df

def remove_group1_data():
    # These are the datasets for the five people - I don't think these include their own tweets though!
    df1 = pd.read_csv("../TobiasPetersen__data.csv").rename(columns={"0":"created_at", "1":"id", "2":"text", "3":"from_user_id"})
    df2 = pd.read_csv("../AllanSchmidt_data.csv").rename(columns={"0":"created_at", "1":"id", "2":"text", "3":"from_user_id"})
    df3 = pd.read_csv("../gaard_Hans_data.csv").rename(columns={"0":"created_at", "1":"id", "2":"text", "3":"from_user_id"})
    df4 = pd.read_csv("../GringoWalking_data.csv").rename(columns={"0":"created_at", "1":"id", "2":"text", "3":"from_user_id"})
    df5 = pd.read_csv("../torstenfroling_data.csv").rename(columns={"0":"created_at", "1":"id", "2":"text", "3":"from_user_id"})

    df = pd.concat([df1, df2, df3, df4, df5])
    df = df.drop_duplicates().reset_index(drop=True)
    
    df.id = df.id.astype(str)
    df.from_user_id = df.from_user_id.astype(str)

    all_data = pd.read_csv("../without_group1/without_group1_all.csv", sep=",", lineterminator='\n').rename(columns={"0":"created_at", "1": "id", "2":"text", "3": "from_user_id"})
    
    all_data.id = all_data.id.astype(str)
    all_data.from_user_id = all_data.from_user_id.astype(str)
    
    #merge_df = pd.merge(all_data, df, on="id", how="outer")
    
    merge_df = all_data[~all_data.id.isin(df.id)]
    
    print("len of merge ", len(merge_df))
    print("len of df", len(df))
    print("len of alldata", len(all_data))
    merge_df.to_csv("../without_group1_ready.csv", index = False)
    del merge_df
    
    return 0
            
if __name__ == "__main__":
    
    filenames = glob.glob("../without_group1/*.csv")
    out_filename = "../without_group1/without_group1_all.csv"
    
    #generate_files()
    
    #join_files(filenames, out_filename)
    
    remove_group1_data()