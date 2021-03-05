# pangram
Riffing on the NYT Spelling Bee / Pangram game

Published at: https://pangram-ce21c.web.app/#/

Known issues:
* Missing words (e.g. warf)
* No shuffle key
* Only 10 boards
* No backspace
* Doesn't tell difference between known word vs. missing center.
* Layout breaks with too many words
* Should save state in local storage (which board you're on, words you've found) -- reload throws away all your work.
* Should put the board in the URL (so you can link to a board). (What is firebase's memcache?  Server should boot, self-populate.)

Visual issues
* Needs visual design
* Buttons should be more tactile (material splash, etc.)
* Enter key is too close.
* Should look different on tablet vs. phone.

Features
* Social, High-score, share link.  "beat your friend"
* Share a board on twitter.
* Add Analytics (firebase_analytics is not yet null-safe)
