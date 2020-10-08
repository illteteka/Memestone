# Memestone

The digital card game for understanding digital communication

Memestone Demo: https://www.youtube.com/watch?v=3QloUiGR00o

## Dependencies

[Python 3.X latest](https://www.python.org/downloads/)

[LÖVE 11.3](https://love2d.org/)

[PRAW](https://praw.readthedocs.io/en/latest/getting_started/installation.html)

[Pandas](https://pandas.pydata.org/docs/getting_started/install.html)

[NLTK](https://www.nltk.org/install.html)

[TextBlob](https://textblob.readthedocs.io/en/dev/install.html)

## Optional dependencies

[Tesseract OCR](https://pypi.org/project/pytesseract/)

## Usage

You need to create a burner Reddit account and make a new app to generate your ClientID, ClientSecret, and UserAgent:
https://www.reddit.com/prefs/apps

All of these need to be added to the beginning of **python-downloader.py**

The variables Subreddit_A/B and Subreddit_(A/B)_short can be customized to use custom subreddits, however the filename changes need to be updated in the variables at the top of **main.lua**

Optionally, if you do not want to install Tesseract OCR, you should change DEBUG_RUN_OCR to False in **python-downloader.py**

After installing all dependencies, you can download the memes and text data by running

    python python-downloader.py

in the same directory as Memestone

If done correctly, the directory can be run in LÖVE on Windows with

    "C:\Program Files\LOVE\love.exe" .

see https://love2d.org/wiki/Getting_Started for running on macOS, Linux, etc.
