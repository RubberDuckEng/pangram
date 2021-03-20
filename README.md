# pangram
Riffing on the NYT Spelling Bee / Pangram game in Flutter for fun
Part of rubberduckeng.com weekly web show.

Published at: https://pangram-ce21c.web.app/#/

# Running locally
`dart bin\generate_boards_json.dart` to generate web/boards/*.json
`flutter run` should "just work" in a web browser.
`flutter pub run build_runner build ` is needed any time Board, Manifest or any other @JSONSerliazable is edited.

`.cache` is populated with word lists pulled from the web and can be safely deleted.

https://nytbee.com/ has lots of notes on how the NYT does this.

# Known issues
* Should put the board in the URL (so you can link to a board). (What is firebase's memcache?  Server should boot, self-populate.)
* Firebase automated deploy on checkin fails every time.

## Visual issues
* Needs visual design
* Buttons should be more tactile (material splash, etc.)
* Should look different on tablet vs. phone.
* Should hexegons still press when typing from keyboard?
* Error messages are too far away from the keys on desktop.

## Features
* Social, High-score, share link.  "beat your friend"
* Share a board on twitter.
* Add Analytics (firebase_analytics is not yet null-safe)
* Need progress towards max score.
* Analysis like https://nytbee.com/ has!

## A Server-side
* Some sort of (auto-curated) historical list to allow most users to play the same N puzzels?
