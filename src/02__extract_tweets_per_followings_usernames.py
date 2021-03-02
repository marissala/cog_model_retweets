"""
The following of each leader's tweets in the network should be in a separate file :)
"""

import pandas as pd

##########################################
### MODIFY BASED ON FILES YOU HAVE
    
usernames_filename = "../GroupX_following.txt"

data_filename = "../test_with_RTcount.csv"

output_path = "../data/GroupX_following_output.csv"

##########################################

def get_usernames_list(fname):
    f_users = open(fname, 'r') 
    users = f_users.readlines()

    user_list = []
    for element in users:
        user_list.append(element.strip())
    return user_list

if __name__ == "__main__":
    
    print("Load users")
    user_names = get_usernames_list(usernames_filename)
    
    print("Select users from our dataframe")
    df = pd.read_csv(data_filename)
    df_users = df[df['screen_names'].isin(user_names)].drop_duplicates()
    
    df_users.to_csv(output_path, index=False)
    del df
    print("Done")
