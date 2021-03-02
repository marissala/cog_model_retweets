import pandas as pd
import re
import spacy
import string
from string import digits
import nltk

df = pd.read_csv("../retweets_GROUP1.csv")
print(df.head())

# Remove RT and @ from texts
file = open("../../hope-b117/stop_words.txt","r+")
stop_words = file.read().split()

sp = spacy.load('da_core_news_lg')

def remove_emoji(string):
    emoji_pattern = re.compile("["
                               u"\U0001F600-\U0001F64F"  # emoticons
                               u"\U0001F300-\U0001F5FF"  # symbols & pictographs
                               u"\U0001F680-\U0001F6FF"  # transport & map symbols
                               u"\U0001F1E0-\U0001F1FF"  # flags (iOS)
                               u"\U00002500-\U00002BEF"  # chinese char
                               u"\U00002702-\U000027B0"
                               u"\U00002702-\U000027B0"
                               u"\U000024C2-\U0001F251"
                               u"\U0001f926-\U0001f937"
                               u"\U00010000-\U0010ffff"
                               u"\u2640-\u2642"
                               u"\u2600-\u2B55"
                               u"\u200d"
                               u"\u23cf"
                               u"\u23e9"
                               u"\u231a"
                               u"\ufe0f"  # dingbats
                               u"\u3030"
                               "]+", flags=re.UNICODE)
    return emoji_pattern.sub(r'', string)


def clean_tweets(row):
    tweet = row["text"].lower()
    
    clean_tweet = re.sub(r'^rt', '', tweet) #RT
    clean_tweet = re.sub(r'@(\S*)\w', '', tweet) #mentions
    clean_tweet = re.sub(r'#\S*\w', '', clean_tweet) #hashtags
    # Remove URLs
    url_pattern = re.compile(
        r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})')
    clean_tweet = re.sub(url_pattern, '', clean_tweet)
    
    clean_tweet = remove_emoji(clean_tweet)
    
    clean_tweet = clean_tweet.translate(str.maketrans('', '', string.punctuation))
    clean_tweet = clean_tweet.replace('”', '')
    clean_tweet = clean_tweet.replace('“', '')
    
    # Remove stopwords
    words = clean_tweet.split()
    res = [x for x in words if x not in stop_words]
    
    res = ' '.join(res)
    
    sentence = sp(res)
    lemmas = []
    for word in sentence:
        lemmas.append(word.lemma_)
    
    if len(lemmas) > 3:
        return ' '.join(lemmas)
    else:
        return 1

print("Start")
df["clean_text"] = df.apply(lambda row: clean_tweets(row), axis = 1)
df = df[df["clean_text"] != 1].reset_index(drop=True)

#italian_documents = df["clean_text"].to_list()

print("Saving")
df.to_csv("../clean_GROUP1_topic_model_testset.csv", index = False)

