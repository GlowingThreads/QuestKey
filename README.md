# quest_key

Developed By: Bryce Fisher

DMIT 2025

Mobile Application Developemnt 


**Overview:**

*Intro:*

Quest Key

This questy to-do application actually came together pretty well. I had the general concept floating around in my head for a while, so finally being able to build it out and see it working felt really cool. I wanted something that made task tracking feel a bit more fun and engaging, and I think I got close to that with the hero and quest setup. There were definitely moments where I felt like I was in way over my head T_T, especially trying to get everything tied together the way I imagined it, but I learned a lot just by pushing through it. There’s still a ton I’d like to improve (and will probably rebuild), but for where I’m at with Flutter right now, I’m actually proud of how it turned out.

*Build:*

Once I had a decent idea of what I wanted the app to look like, I just started putting stuff togeher and building outwards from there. I focused mostly on getting the layout and visuals together first because that’s what helps me stay motivated — if it looks like something, then I can get driving on it. I was trying to build pieces I knew I’d need (like character creation and quest tracking) and then I just kind of tied them together as I went. A lot of stuff changed halfway through and I ended up restructuring things more than once, but that actually helped me figure out what was working/needed and what could be less messy. I didn’t go in with a fully mapped-out plan, so it was definitely more of an as-I-went process, but I learned a lot just by figuring it out piece by piece.

*Issues:*

The main thing that was a struggle for me was getting the idea that I had to start taking shape. I have been thinking about making something like this for a long time and luckily I was already started on the assets and notes. I would definetely say my understanding of what can be built in dart/flutter and my expirience limited how much I was able to do and the time that it took. Though becasue I was so excited I put way way more time in on this than I thought I would. There are still things that I would like to improve and the more I researched, the more I realized that I've barely scratched the surface.

As usual for me too my workflow was hectic, I ended up starting everything at once so I could at least get a visual of things (thats something I find motivates me to get going) and ended up not sticking to a set plan really until I got in the habit of recording things in the readme. I think with structure and not jumping around I could have had an easier time and done less reworking. I had an idea of how to make things work and ended up moving things around to simplify pages so my organization is not on point that is also something that got me a few times. Because I am also slower at test driven deleopment I did end up writing tests at the end - this is something I would also like to improve as I do think it is the way to go as far as streamlining the process start to finish. 

For quests I did have to make the complete/ delete only available when the user is on the in progress tab and the delete only on the completed tab - because this is not super intuitive I would have liked to figure out a way to do it better. 

For hero creation I would have liked that to be its own page but because of the assets I made the nav bar was too squished when I added too much to it so I added it to the info page itself. I will do some reworking in the future to make that more organized. 


*Improvements to be made:*

**Character and Character Creation**

  I would like creation to be more developed, maybe making it it's own page and giving the user more 
  options. I researched some flutter packages for that purpose (https://pfp.walkscape.app/#/https://pfp.walkscape.app/#/) but haven't decided if thats the route I want to go yet. I would also like to give the characters badges/ acheivements or maybe items they can add to their hero later on but that would require a re-design of the quest system and additional elements - the idea bieng that it would be more engaging if it was more gamified and personalizable. For the assets I would also like to improve the protrait images. I went with a simple style because those were easier to make in illustrator. 

  For the character leveling I would eventually love to attach some sounds to the lvl up notification and quest completion and develop the animations. I will look into more third party stuff that I can bring
  in to imrove the UI and look of things too. I would have liked to implement and editing feature for character info so the user could change thier original choice but ran out of time. 

  **Quests**

  I would also like to take the quest page and model further, maybe adding categories that the user can choose from. I had the idea of having main/ side quest lists to start to help the user sort task importance but to keep it simple went with one list. Ideally it would be cool to assign different xp to 
  the users character based on the kind of quest they are making. I had the idea of making 'Encounter'
  quests that are appear under certain conditions. Maybe with class/stats and level that are fun tasks
  a user can do for an xp bonus and have thier own little story as descriptions.

  For quest creation I would like to add a library of short descriptions that could possibly be attached to a category component later on that the user can select from that cover basic tasks like drinking more water/ excersizing etc. I'd also like the user to be able to assign icons to the quest when it's created so each one is more visually distinct on the home page for easier recognition/completion. 

  **Assets**

  I'll definetley be taking another stab at the icons and assets for the game for sure. I would like the 
  art to be less simple and have started expirementing with creating animations. I'd love to bring a higher level of realism to the images if possible and add more assets with the development of additional functionalities. 

  **Storage**

  I would definatley like to implement a more robust storage system for the character and quest information. This would let me do more with the objects and store the assets as well. 

  Note on assets: ** All character images and icons were created by me and the imagery from the pages in the app came from a paid lisence to which no attributions are required.**  


**Resources**

*Docs:*

https://docs.flutter.dev/data-and-backend/state-mgmt/simple
https://docs.flutter.dev/cookbook/persistence/key-value
https://docs.flutter.dev/cookbook/persistence/reading-writing-files
https://docs.flutter.dev/ui/adaptive-responsive/best-practices
https://docs.flutter.dev/cookbook/testing/widget/introduction
https://docs.questera.ai/
https://medium.com/%40tigerasks/building-a-widget-2cd5d44ca324
https://docs.flutter.dev/deployment/android
https://api.flutter.dev/flutter/material/Icons-class.html

*Repos:*

https://github.com/fluttergems/awesome-open-source-flutter-apps


Background Assets: 

Sourced from a paid licensce to Vecteezy - no attribution required.

Additional Competencies: Animation and Local Storage

**

3rd Party Packages *may use or not*:

animated_toggle_switch 0.8.4
- $ flutter pub add animated_toggle_switch
- dependencies:
  animated_toggle_switch: ^0.8.4

popupcard
   $ flutter pub add popup_card
   dependencies:
  popup_card: ^0.1.0
import 'package:popup_card/popup_card.dart';


   $ flutter pub add slider_button
   dependencies:
  slider_button: ^2.1.0
  import 'package:slider_button/slider_button.dart';

   $ flutter pub add awaitable_button
   dependencies:
  awaitable_button: ^1.3.0
  import 'package:awaitable_button/awaitable_button.dart';

   $ flutter pub add crystal_navigation_bar
   dependencies:
  crystal_navigation_bar: ^1.0.4
  import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';


 $ flutter pub add top_snackbar_flutter
 dependencies:
top_snackbar_flutter: ^3.2.0
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/safe_area_values.dart';
import 'package:top_snackbar_flutter/tap_bounce_container.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';


Hs:2,4,5,2,3,1,2,3,4,3,6,5,2,4,3,2,3,3

TODO's:

- val for fields *
- add copy w/s*
- add del swipe *
- re-organiz state*
- clean and lsoe redundant*
- save/load so hero persists *
- improve quest creation screen (needs validation + maybe icons?)*
- fix navigation issue after creating a quest (T_T black screen)*
- clean up hardcoded placeholders*
- make sure new quests save to shared prefs + reload on app start*
- replace fake sample quest data with real user-created quests only -- need to keep placeholder?-- NO*

- update hero profile card  *
- get stat assignment working *
- updated stats on assign - save  *
- no add points if no points*
- fix nav bar issue (index)*

- integrate stat panel and style *
- skip info if hero  *
- get swipe to complete / delete working on quest list* 
- show xp gained when quest completed (maybe popup?) -- too much*
- redesign xp bar to match glow style -- status *
- fix overflow on stat panel (scrollable)*

- cleanup layout*
- fix delete styling*
- quest page lvl err*
- fix dismissible*
- get edit working/pass quest data *

- duplicating save for edits?? ** check*
- need to update shared prefs/edit  *
- test out quest flow / xp gain*
- xp on completed quests?*

- filtering should be prov*
- selected quest should be prov  *
- create should read from prv*
- edit button index - nav*

- quest item color change*
- build filter? QP/QL*
- prov filter*
- lvl polish *
- cond hero navigation on start  *
- ndk error*
- what can be cleaned?
- tests*

