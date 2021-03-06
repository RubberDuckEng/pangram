# pangram
Riffing on the NYT Spelling Bee / Pangram game in Flutter for fun
Part of rubberduckeng.com weekly web show.

Published at: https://pangram-ce21c.web.app/#/

# Running locally
`dart bin\generate_boards_json.dart` to generate web/boards/*.json
`flutter run` should "just work" in a web browser.
`flutter pub run build_runner build ` is needed any time Board, Manifest or any other @JSONSerliazable is edited.

# Known issues
* Missing words (e.g. warf)
* Layout breaks with too many words
* Should save state in local storage (which board you're on, words you've found) -- reload throws away all your work.
* Should put the board in the URL (so you can link to a board). (What is firebase's memcache?  Server should boot, self-populate.)

## Visual issues
* Needs visual design
* Buttons should be more tactile (material splash, etc.)
* Should look different on tablet vs. phone.
* Needs a text field for when using a keyboard. (Hexegons should still press when typing from keyboard?)

## Features
* Social, High-score, share link.  "beat your friend"
* Share a board on twitter.
* Add Analytics (firebase_analytics is not yet null-safe)
