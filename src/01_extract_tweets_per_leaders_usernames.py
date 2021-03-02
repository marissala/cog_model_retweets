"""
Purpose: extract user tweets based on user_handles
"""

import pandas as pd
import glob
import re

##########################################
### MODIFY BASED ON FILES YOU HAVE
    
usernames_path = "../twitter_handles/*.txt" #"../GroupX_leaders.txt"

data_path = glob.glob("../data/file*.csv")  #"../test_with_RTcount.csv"

output_path = "../twitter_output/"
#"../data/GroupX_leaders_output.csv"

##########################################

def get_usernames_list(fname):
    f_users = open(fname, 'r') 
    users = f_users.readlines()

    user_list = []
    for element in users:
        user_list.append(element.strip())
    return user_list

if __name__ == "__main__":
    usernames = glob.glob(usernames_path)
    for group in usernames:
        print(group)
        print("Load users")
        user_names = get_usernames_list(group)
        
        df0 = pd.read_csv(data_path[0], lineterminator='\n')
        df_users0 = df0[df0['screen_names'].isin(user_names)].drop_duplicates()
        del df0
        
        for file in data_path[1:]:
            df = pd.read_csv(file, lineterminator='\n')
    
            print("Select users from our dataframe")
            df_users1 = df[df['screen_names'].isin(user_names)].drop_duplicates()
            
            df_users0 = pd.concat([df_users0, df_users1])
            
            del df
    
        print(re.findall(r'(Group.*).txt', group)[0])
        output_name = output_path + re.findall(r'(Group.*).txt', group)[0] + ".csv"
        df_users0.to_csv(output_name, index=False)
        del df_users0
        #del df
        print("Done")
        print("----------------------------")
