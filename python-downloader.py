# Tesseract OCR Config
DEBUG_RUN_OCR = True # Make False if not using Tesseract OCR
TesseractOCRPath = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# Subreddit Data Config
Subreddit_A = 'dankmemes'
Subreddit_A_short = 'dm_'
Subreddit_B = 'CoronavirusMemes'
Subreddit_B_short = 'cm_'

# Reddit PRAW Config
RedditClientID = 'xxxxxxxxxx'
RedditClientSecret = 'xxxxxxxxxx'
RedditUserAgent = 'xxxxxxxxxx'
RedditUsername = 'xxxxxxxxxx'
RedditPassword = 'xxxxxxxxxx'

SubredditImageCount = 20

import praw
import pandas as pd
import datetime as dt
import requests
import math
import os
from textblob import TextBlob
from textblob.sentiments import NaiveBayesAnalyzer

DEBUG_WRITE_DATA = True
DEBUG_DL_COMMENTS = True
DEBUG_EXPORT_TEXT = True
DEBUG_STRIP_TEXT = True

try:
    from PIL import Image
except ImportError:
    import Image
if DEBUG_RUN_OCR:
	import pytesseract
	pytesseract.pytesseract.tesseract_cmd = TesseractOCRPath

ex_url = "https://a.aa/a.gif"
ex_len = len(ex_url)

# Card analysis variables

export = { "words":[] }
frequency = { "word":[], "count":[], "class":[], "pol":[], "pos":[], "neg":[]}
total = { "class":[], "pol":[], "pos":[], "neg":[]}
cards = { "id":[], "pos":[], "neg":[], "pol":[]}

reddit = praw.Reddit(client_id=RedditClientID, client_secret=RedditClientSecret, user_agent=RedditUserAgent, username=RedditUsername, password=RedditPassword)

def main():
	download_sub(Subreddit_A, SubredditImageCount)
	download_sub(Subreddit_B, SubredditImageCount)
	if DEBUG_STRIP_TEXT:
		strip_text(Subreddit_B + "_raw_text.csv", Subreddit_B_short)
		strip_text(Subreddit_A + "_raw_text.csv", Subreddit_A_short)
	
def is_image(ext):
	if ext == "png" or ext == "jpeg" or ext == "jpg":
		return ext
	else:
		return "notanimage"

def download_sub(sr, limit):
	subreddit = reddit.subreddit(sr)
	
	subreddit_data = subreddit.hot()
	
	submission_data = { "id":[], "upvotes":[], "title":[], "url":[] }
	submission_raw_text = { "id":[], "title":[], "comments":[], "ocr":[] }
	
	dl_counter = 0
	
	for submission in subreddit_data:
		# Is the URL long enough to have an image
		if (len(submission.url) >= ex_len) and (dl_counter < limit) and (submission.score >= 1):
			if (not submission.over_18):
				find_ext = submission.url.rfind(".")
				ext = submission.url[find_ext+1:len(submission.url)]
				ext = is_image(ext)
				# If the file ext is short enough to be an image
				if (len(ext) <= 4):
					conv_score = str(submission.score)
					score_sig = conv_score[0:2]
					if int(score_sig) >= 30:
						score_sig = conv_score[0:1]
					submission_data["upvotes"].append(score_sig)
					total_score = math.floor((submission.score / (submission.upvote_ratio * 100)) * 100)
					submission_data["title"].append(get_title(submission.title))
					#submission_data["downvotes"].append(max(total_score - submission.score, 0))
					image_path = sr + "_" + submission.id + "." + ext
					submission_data["id"].append(image_path)
					submission_raw_text["id"].append(image_path)
					submission_raw_text["title"].append(submission.title)
					if DEBUG_DL_COMMENTS:
						_get_sub = reddit.submission(id=submission.id)
						comment_text = ""
						for comment in _get_sub.comments:
							if (hasattr(comment, 'body')):
								comment_text = comment_text + " " + comment.body
						submission_raw_text["comments"].append(comment_text)
					if DEBUG_WRITE_DATA:
						submission_data["url"].append(submission.url)
						img_data = requests.get(submission.url).content
						with open("images/" + image_path, 'wb') as handler:
							handler.write(img_data)
						submission_raw_text["ocr"].append(process_ocr(image_path))
					dl_counter+=1
	
	#Convert to pandas data frame
	if DEBUG_WRITE_DATA:
		subreddit_df = pd.DataFrame(submission_data)
		subreddit_df.to_csv(sr + '.csv', index=False)
		if DEBUG_EXPORT_TEXT:
			subreddit_df_rt = pd.DataFrame(submission_raw_text)
			subreddit_df_rt.to_csv(sr + '_raw_text.csv', index=False)

def process_ocr(x):
	output = ""
	if DEBUG_RUN_OCR:
		try:
			output = pytesseract.image_to_string(Image.open("images\\" + x), timeout=2) # Timeout after 2 seconds
		except RuntimeError as timeout_error:
			# Tesseract processing is terminated
			print("")
		pass
	return output
	
# Card analysis methods

def strip_text(raw_text, short_name):
	load_csv = pd.read_csv(raw_text)
	
	for id_count in range(len(load_csv["id"])):
		rip_data(load_csv, load_csv["id"][id_count], id_count, short_name)
		
	cards_df = pd.DataFrame(cards)
	cards_df.to_csv(short_name + 'cards.csv', index=False)
	
	for key in cards:
		cards[key].clear()

def banned_words(str):
	if (str == "the") or (str == "to") or (str == "and") or (str == "in") or (str == "is") or (str == "for") or (str == "of") or (str == "that") or (str == "you") or (str == "it") or (str == "be") or (str == "have") or (str == "on") or (str == "as") or (str == "with") or (str == "are") or (str == "all") or (str == "www") or (str == "https") or (str == "com") or (str == "this") or (str == "if") or (str == "so") or (str == "but") or (str == "my") or (str == "some") or (str == "at") or (str == "how") or (str == "how") or (str == "your") or (str == "get") or (str == "or") or (str == "by") or (str == "me") or (str == "had") or (str == "has") or (str == "no") or (str == "lol") or (str == "then") or (str == "re") or (str == "don") or (str == "lot"):
		return ""
	else:
		return str

def get_words(str):
	i = 0
	word_list = ""
	word = ""
	if type(str) is not float:
		for i in range(len(str)):
			j = ord(str[i])
			num = ((j >= 48) and (j <= 57))
			cap = ((j >= 65) and (j <= 90))
			low = ((j >= 97) and (j <= 122))
			if (num or cap or low or (j == 39)):
				if cap:
					word = word + str[i].lower()
				else:
					word = word + str[i]
			else:
				word = banned_words(word)
				if len(word) > 1:
					word_list += word + " "
				word = ""
	return word_list

def get_title(str):
	i = 0
	word = ""
	for i in range(len(str)):
		j = ord(str[i])
		num = ((j >= 32) and (j <= 122))
		exc = ((j != 44) and (j != 34) and (j != 39))
		if (num and exc):
			word = word + str[i]
	return word
				
def rip_data(data_url, freq_name="freq", id=0, short_name=""):
	# Clear array vars
	export["words"].clear()
	for key in frequency:
		frequency[key].clear()
		
	for key in total:
		total[key] = 0
	
	# Load all words from the current set, includes cleaning up of data
	_t = []
	_t.append(get_words(data_url["title"][id]))
	_t.append(get_words(data_url["comments"][id]))
	_t.append(get_words(data_url["ocr"][id]))
	
	_pol = 0
	_pos = 0
	_neg = 0
	
	i = 0
	for i in range(2):
		total_pol = 0
		blob = TextBlob(_t[i])
		for sentence in blob.sentences:
			total_pol += sentence.sentiment.polarity
		blob2 = TextBlob(_t[i], analyzer=NaiveBayesAnalyzer())
		_pos += blob2.sentiment.p_pos
		_neg += blob2.sentiment.p_neg
		_pol += total_pol
		
	_pol /= 3
	_pos /= 3
	_neg /= 3
	
	cards["id"].append(freq_name)
	cards["pol"].append(math.floor(_pol*100))
	cards["pos"].append(_pos)
	cards["neg"].append(_neg)

main()