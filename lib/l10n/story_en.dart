import '../story/story.dart';
import 'l10n.dart';

const _e = Spk.essen, _so = Spk.soun, _ts = Spk.tsuru, _ho = Spk.hotaru;
const _re = Spk.rendo, _ma = Spk.masakage, _hi = Spk.hint, _un = Spk.unknown;

const storyEn = StoryText(
  s: {
    'tagline': 'The Shadow Born of Iron',
    'ch1.title': 'Ashes of the Mist',
    'ch2.title': 'Whispers in the Bamboo',
    'ch3.title': 'Petals of Steel',
    'ch4.title': 'The Iron Dragon\'s Keep',
    'c1.o1': 'Return to Kasumi village',
    'c1.o2': 'Drive the Iron Dragon looters out of Kasumi',
    'c1.o3': 'Find Master Sōun by the ruined dojo',
    'c2.o1': 'Find the Iron Dragon war camp in the bamboo forest',
    'c2.o2': 'Silence the camp guard',
    'c2.o3': 'Steal the war orders from the commander\'s table',
    'c3.o1': 'Drive the tax collectors out of Hanamura',
    'c3.o2': 'Speak with Obaa Tsuru at her house',
    'c3.o3': 'Follow Hotaru\'s trail — find her hidden notes',
    'c3.o4': 'Face General Takeshi Rendō at the Sakura Shrine',
    'c4.o1': 'Approach the Iron Dragon Keep',
    'c4.o2': 'Break through the gate guard',
    'c4.o3': 'Free Hotaru from the cage',
    'c4.o4': 'Defeat Lord Tetsuryū Masakage',
    'ending.mercy.title': 'The Gentle Hand',
    'ending.vengeance.title': 'The Shadow\'s Justice',
    'codex.essen.title': 'Essen',
    'codex.essen.text':
        'A shinobi of Kasumi-gakure, twenty-one years old. Found as an infant after the wreck of a foreign ship, wrapped in a cloth stitched with the word "ESSEN" — which Master Sōun gave him as his name. His pale, sea-grey eyes earned him the nickname "little ghost" among the village children. He has spent his life trying to prove that a child of the sea can belong to the mist.',
    'codex.kasumi.title': 'Kasumi-gakure',
    'codex.kasumi.text':
        'The Village Hidden in Mist, home to a small clan of shinobi who sold their skills only to those who protected the weak. Its founders swore the "Oath of Lanterns": never to strike a sleeping village, never to serve a lord who burns fields. It was destroyed in a single night by the Iron Dragon clan.',
    'codex.soun.title': 'Kiriya Sōun',
    'codex.soun.text':
        'Master of Kasumi-gakure and Essen\'s adoptive father. Quiet, patient, fond of cranes and bad poetry. He arrived in the village twenty-one years ago with an infant and no past, and became its greatest teacher. He died before he could confess the truth of who he once was.',
    'codex.masakage.title': 'Tetsuryū Masakage',
    'codex.masakage.text':
        'Daimyō of the Tetsuryū — the Iron Dragon clan. Brilliant, patient and utterly without mercy, he believes the warring states will be won not by courage but by iron and fire. For two decades he has tried to forge the foreign thunder-weapons in secret, and failed.',
    'codex.irondragon.title': 'The Iron Dragon Clan',
    'codex.irondragon.text':
        'A samurai clan that rose from the iron mines of Hōmura. Its warriors wear red-lacquered armor and a black dragon crest. Under Masakage, the clan has bled the province with taxes to feed a hidden forge beneath its Keep.',
    'codex.rendo.title': 'Takeshi Rendō',
    'codex.rendo.text':
        'Masakage\'s general, called "the Unbent Blade." Famous across the province for never striking a fleeing man and never breaking his word. Commands the shrine road with a small band of loyal retainers.',
    'codex.rendo2.title': 'Rendō\'s Shame',
    'codex.rendo2.text':
        'At seventeen, Rendō stood on the Kurogane beach the night the Morgenrot was wrecked, and did nothing as his lord massacred the survivors. He has served Masakage ever since, believing an oath kept is worth more than a conscience obeyed. Essen\'s mercy at the shrine broke that belief.',
    'codex.tsuru.title': 'Obaa Tsuru',
    'codex.tsuru.text':
        'A fisherman\'s widow of Hanamura, now past eighty. She sheltered Sōun and the infant Essen on the night of the wreck and kept the secret for twenty-one years. She claims to be too old to be afraid of samurai. This appears to be true.',
    'codex.wreck.title': 'The Wreck of the Morgenrot',
    'codex.wreck.text':
        'A foreign trading ship from far across the western seas, lost on the Kurogane rocks in a typhoon. Aboard were Heinrich, a master smith from the city of Essen, and his wife Margarethe with their newborn son. Masakage seized Heinrich\'s journal of steel-making, but its final pages were never found — they had been sewn into the infant\'s swaddling cloth.',
    'codex.note1.title': 'Hotaru\'s Note I',
    'codex.note1.text':
        'Written in charcoal on a strip torn from her sleeve: "They are taking me to the Keep. I counted forty riders. Masakage looked at me like a merchant weighing rice."',
    'codex.note2.title': 'Hotaru\'s Note II',
    'codex.note2.text':
        '"Masakage has a forge under the Keep. Men from Hanamura work there in chains, making thunder-weapons. But the barrels crack. He says the last secret is in the foreigner\'s cloth. YOUR cloth."',
    'codex.note3.title': 'Hotaru\'s Note III',
    'codex.note3.text':
        '"This is a trap. Do not come for me. ...But you will come. You always do, little ghost. So come quietly."',
    'codex.hotaru.title': 'Hotaru',
    'codex.hotaru.text':
        'Daughter of Kasumi\'s headman and Essen\'s sworn sister. The finest kunoichi of her generation — fast, sharp-tongued and fearless. She was the first child in the village to call Essen "brother," and broke the nose of the first one who laughed at it.',
    'codex.letter.title': 'Heinrich\'s Letter',
    'codex.letter.text':
        'Folded inside the cloth, beneath the drawings of a crucible furnace, was a letter in a foreign tongue. A Portuguese priest in the capital would one day translate it: "My son — steel is neither good nor evil. It is only the hand that holds it. If you ever read this, be a gentle hand. Your father, Heinrich."',
  },
  p: {
    'ch1.intro': [
      'Hōmura Province, in the age of the warring states.',
      'Twenty-one winters ago, a foreign ship broke apart on the black rocks of the Kurogane coast. The sea gave up only one survivor: an infant wrapped in a cloth stitched with a single foreign word.',
      'ESSEN.',
      'The shinobi of Kasumi-gakure — the Village Hidden in Mist — raised the child as one of their own. They taught him to walk without sound, to breathe without being heard, to become the shadow between two lanterns.',
      'Tonight, Essen returns from a mission in the north. On the wind he smells smoke.',
    ],
    'ch1.outro': [
      'Master Sōun died with the dawn still hours away, his last words unspoken.',
      'Essen buried him beneath the memorial stone where the village children once learned their first knots. He wrapped the old cloth around his wrist — the cloth bearing his name, the only thing the sea had given him.',
      'Somewhere beyond the bamboo, the Iron Dragon was dragging Hotaru toward its keep.',
      'A shinobi does not mourn. A shinobi follows the trail.',
    ],
    'ch2.intro': [
      'Dawn crept over the valley grey and silent, the color of ash.',
      'The tracks of horses and armored men led east, into the great bamboo forest where the Iron Dragon has raised a war camp to choke the roads of Hōmura.',
      'A camp means a commander. A commander means orders. And orders will say where Hotaru has been taken.',
    ],
    'ch2.outro': [
      'The orders bore the seal of the Iron Dragon in blood-red lacquer.',
      '"The kunoichi is to be delivered to the Keep alive. The foreign child will follow her — let him. The forge must be fed by the new moon. General Rendō holds the shrine road."',
      'The foreign child. Essen read the words three times before he understood that they meant him.',
      'And a forge. What forge could need him?',
    ],
    'ch3.intro': [
      'Beyond the river lies Hanamura, the Village of Flowers, where the cherry trees bloom even in years of war.',
      'Old Tsuru lives there — a fisherman\'s widow who, it is whispered, once sheltered a samurai and a crying infant on the night of a great storm.',
      'Further east, on the hill of the Sakura Shrine, General Takeshi Rendō waits. They say his blade has never been drawn in dishonor.',
    ],
    'ch3.outro': [
      'Rendō did not rise until Essen was gone from sight. The cherry petals settled on his armor like snow.',
      'Essen walked south, toward the Keep, carrying a truth heavier than any blade: the master who raised him had once worn the crest of the Iron Dragon, and the sea had not taken his parents.',
      'A man had.',
    ],
    'ch4.intro': [
      'The sun bleeds into the western mountains. Above the southern hills, the Keep of the Iron Dragon stands black against a red sky, its forges breathing smoke from beneath the stone.',
      'At dusk, Hotaru will die.',
      'Essen tightens the cloth around his wrist — his mother\'s stitches, his father\'s secret, his master\'s guilt — and walks toward the gate.',
    ],
    'ch4.outro': [],
    'ending.mercy': [
      'Essen lowered his blade.',
      '"My master spent his life repaying one night of obedience. I will not spend mine repaying one night of rage."',
      'General Rendō arrived at dusk with his retainers — not to fight, but to bind his own lord in chains and deliver him to the Shogun\'s judgment.',
      'That night, beside the cold forge, Essen finally unpicked the stitches of his mother\'s cloth. Inside, folded small as a prayer, was a letter in a language he could not read, and drawings of steel that could crack mountains.',
      'He kept the letter. He burned the drawings.',
      'In spring, Kasumi was rebuilt, and in its square stands a new stone with two names carved side by side: Kiriya Sōun, and Heinrich of Essen.',
      'The shadow had chosen mercy. And the mist remembered.',
    ],
    'ending.vengeance': [
      'The blade fell once, and the Iron Dragon was no more.',
      'The Keep burned for three days. Rendō knelt before the ashes and swore no lord would ever again command his sword.',
      'That night, beside the cold forge, Essen unpicked the stitches of his mother\'s cloth. Inside was a letter in a language he could not read, and drawings of steel that could crack mountains.',
      'He burned them both — and the letter\'s words went into the smoke unknown.',
      'Hotaru rebuilt Kasumi. Essen helped her raise every beam, and then, one misty morning, he was simply gone.',
      'Travelers on the northern roads still speak of a light-eyed shadow who appears when the strong prey upon the weak — and vanishes before thanks can be given.',
      'The shadow had chosen justice. The mist would have to carry the rest.',
    ],
  },
  d: {
    'c1.o1.before': [
      DialogLine(_e, 'That glow over the ridge... it is not the moon. Kasumi is burning.'),
      DialogLine(_hi, 'Drag the left side of the screen to move — push the stick fully to run. Drag the right side to turn the camera around Essen.'),
    ],
    'c1.o1.after': [
      DialogLine(_e, 'The gate of mist... broken. Every house I knew, turned to embers.'),
      DialogLine(_e, 'Iron Dragon crests. Samurai of the Tetsuryū clan — and they are still here, picking through our dead.'),
    ],
    'c1.o2.before': [
      DialogLine(_hi, 'Press CROUCH to move unseen. A spinning yellow gem above a samurai means he is suspicious; a red "!" means you have been found.'),
      DialogLine(_hi, 'Strike an unaware enemy from behind for a SHADOW STRIKE — an instant kill. Throw SHURIKEN from afar. A SMOKE bomb blinds every foe around you.'),
    ],
    'c1.o2.after': [
      DialogLine(_e, 'Not one of them was a match for what this village was. They came in numbers, at night, like thieves.'),
      DialogLine(_un, '...Essen... is that... your step? Light as ever...'),
      DialogLine(_e, 'Master! Master Sōun — by the dojo!'),
    ],
    'c1.o3.after': [
      DialogLine(_e, 'Master, don\'t move. Let me see the wound—'),
      DialogLine(_so, 'Leave it. An old crane knows when the winter is final.'),
      DialogLine(_so, 'They came at dusk. Tetsuryū Masakage himself rode with them. Not for gold, not for land... they came for you, Essen.'),
      DialogLine(_e, 'For me? I am an orphan of the sea. What could the Iron Dragon want with a nameless—'),
      DialogLine(_so, 'You are not nameless. Never say it.'),
      DialogLine(_so, 'Take this cloth from my robe. You were wrapped in it the night the sea brought you. Your mother stitched those letters. "Essen." It is the name of the place your father came from, far across the world.'),
      DialogLine(_so, 'Masakage took Hotaru. She fought like ten of us. He keeps her alive because he knows you will come.'),
      DialogLine(_e, 'Then I will come. And he will learn what a shadow costs.'),
      DialogLine(_so, 'Listen... there is a thing I should have told you long ago. About that night on the beach. About... who I was before the mist...'),
      DialogLine(_so, 'Forgive... me...'),
      DialogLine(_e, 'Master? ...Master Sōun!'),
      DialogLine(_e, '...'),
      DialogLine(_e, 'Rest. I will find her. I swear it on the name you gave back to me.'),
    ],
    'c2.o1.before': [
      DialogLine(_e, 'Bamboo hides a shinobi better than any night. The wind in the stalks will cover my steps.'),
    ],
    'c2.o1.after': [
      DialogLine(_e, 'War curtains, red banners, sentries half-asleep at their posts. Arrogant. They do not believe anyone from Kasumi survived.'),
    ],
    'c2.o3.after': [
      DialogLine(_e, 'A sealed letter... from the Keep itself.'),
      DialogLine(_e, '"The kunoichi is to be delivered alive. The foreign child will follow her — let him."'),
      DialogLine(_e, '"The forge must be fed by the new moon. General Rendō holds the shrine road with his retainers."'),
      DialogLine(_e, 'They are not hunting me. They are herding me. Very well, Masakage. The shadow will walk your road — but not the way you expect.'),
    ],
    'c3.o1.before': [
      DialogLine(_e, 'Samurai in Hanamura, dragging rice sacks from the storehouses. The villagers kneel in the mud and say nothing.'),
    ],
    'c3.o2.after': [
      DialogLine(_ts, 'Those light eyes... the color of the sea in winter. So the little one lived. Come, sit. My knees are older than this village.'),
      DialogLine(_e, 'You know me, grandmother?'),
      DialogLine(_ts, 'I held you before anyone else in this land did. Twenty-one years ago, the foreign ship struck the black rocks. Her name was painted on her side — "Morgenrot." The morning-red.'),
      DialogLine(_ts, 'Many came ashore alive. Sailors. A woman with hair like straw. And a big, gentle man with burned hands — a smith. Heinrich, they called him.'),
      DialogLine(_ts, 'Then the young lord Masakage came down to the beach with his men. He wanted the foreigners\' fire-weapons. He wanted the smith to teach his forges the secret of their steel.'),
      DialogLine(_ts, 'The smith refused. He said his iron would not be used to burn villages. So Masakage took his book of drawings... and ordered everyone on that beach put to the sword.'),
      DialogLine(_e, '...My father. My mother.'),
      DialogLine(_ts, 'Your mother died with you in her arms. One samurai was ordered to finish the child. He stood in the rain a long while. Then he picked you up and ran.'),
      DialogLine(_ts, 'He hid in my hut until the storm passed. He wore the crest of the Iron Dragon on his sleeve, and he wept like a boy.'),
      DialogLine(_ts, 'His name was Kiriya Sōun.'),
      DialogLine(_e, '...My master. He was one of them.'),
      DialogLine(_ts, 'He was. And then he was not. A man is more than the night he is ashamed of, child. Remember that, before you judge.'),
      DialogLine(_ts, 'The girl they took passed through here two days ago, bound on a horse. She dropped something by the road on purpose — I saw her smile when she did it. Follow the road to the shrine.'),
    ],
    'note1': [
      DialogLine(_ho, '"Brother — if anyone would find these, it is you. They are taking me to the Keep. I counted forty riders. Masakage looked at me like a merchant weighing rice."'),
    ],
    'note2': [
      DialogLine(_ho, '"I heard them talk at the river. Masakage has a forge under the Keep. Men from Hanamura work there in chains, making thunder-weapons — the foreign kind, that kill from a hundred paces."'),
      DialogLine(_ho, '"But the barrels crack. They always crack. He says the last secret is in the foreigner\'s cloth. YOUR cloth, Essen."'),
    ],
    'note3': [
      DialogLine(_ho, '"This is a trap. Do not come for me. ...But you will come. You always do, little ghost. So come quietly."'),
    ],
    'c3.o3.after': [
      DialogLine(_e, 'The cloth... Masakage burned Kasumi for a scrap of cloth around my wrist.'),
      DialogLine(_e, 'Then the cloth stays with me. And the shrine road is the only road south.'),
    ],
    'c3.o4.before': [
      DialogLine(_re, 'So. The shadow of Kasumi. You move well — my sentries are still asleep in the grass, I think, with their throats intact. That was a kindness.'),
      DialogLine(_e, 'Step aside, General. I have no quarrel with you.'),
      DialogLine(_re, 'You have no quarrel with me. But I have a lord, and an oath. If you would pass, pass through my blade. Draw.'),
    ],
    'c3.o4.after': [
      DialogLine(_re, 'Enough... I yield. The first time in twenty years.'),
      DialogLine(_re, 'Finish it, if you wish. It would be your right.'),
      DialogLine(_e, 'I am not here to collect the lives of honorable men.'),
      DialogLine(_re, '...Honorable. I was on that beach, boy. Seventeen years old, holding a torch while my lord slaughtered shipwrecked sailors. I did nothing.'),
      DialogLine(_re, 'I watched Kiriya Sōun throw down the order and carry you into the storm. Masakage branded him a traitor. I called him a fool. I was the fool.'),
      DialogLine(_re, 'My oath binds my sword — not my eyes, and not my tongue. Your sister is in a cage in the courtyard of the Keep. Masakage means to execute her at dusk, before your eyes, to make you hand him the cloth.'),
      DialogLine(_re, 'I will not raise my men against you at the north gate. That is all the treason I have in me. Go.'),
    ],
    'c4.o1.after': [
      DialogLine(_e, 'The north gate. Rendō kept his word — only the Keep\'s own guard stands watch. They will have to be enough.'),
    ],
    'c4.o3.after': [
      DialogLine(_ho, 'Took you long enough, little ghost. I left you a trail a blind ox could follow.'),
      DialogLine(_e, 'Your notes were very... encouraging. "Do not come."'),
      DialogLine(_ho, 'And you came anyway. Idiot.'),
      DialogLine(_ho, 'Listen — the Hanamura men are chained in the forge below. I can free them while Masakage is busy with you. He is coming. He has been waiting for this all his life.'),
      DialogLine(_ma, 'Indeed I have.'),
    ],
    'c4.o4.before': [
      DialogLine(_ma, 'The sea\'s little gift. Do you know how long I have searched for that cloth on your wrist? Twenty-one years of cracked barrels and wasted iron.'),
      DialogLine(_e, 'You burned a village of children for it.'),
      DialogLine(_ma, 'I burned a nest of thieves. Your Sōun stole you from me. Give me the cloth, and you may die quickly beside your sister.'),
    ],
    'c4.o4.mid': [
      DialogLine(_ma, 'Hah... you fight like him. Like Sōun. Did he ever tell you what he did on that beach before he grew a conscience?'),
      DialogLine(_ma, 'He cut down three of your father\'s sailors with his own hands. He was my finest blade — until the brat cried.'),
      DialogLine(_e, 'Then he spent twenty-one years paying for it. What have you paid, Masakage?'),
    ],
    'c4.o4.after': [
      DialogLine(_ma, 'Impossible... beaten by a foreign whelp... in my own courtyard...'),
      DialogLine(_ma, 'Go on, then. Take your vengeance. It is the only honest thing left in this world.'),
      DialogLine(_ho, 'Essen! The forge is open — the men are free! ...Brother? What will you do?'),
      DialogLine(_e, '...', choices: ['Spare him — let the Shogun judge him', 'End him — for Kasumi']),
    ],
  },
);
