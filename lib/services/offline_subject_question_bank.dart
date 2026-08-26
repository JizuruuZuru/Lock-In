class OfflineSubjectQuestion {
  final String subject;
  final String topic;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;

  const OfflineSubjectQuestion({
    required this.subject,
    required this.topic,
    required this.prompt,
    required this.answer,
    required this.choices,
    required this.explanation,
  });
}

enum OfflineSubject { english, math, science }

class OfflineSubjectQuestionBank {
  static const List<OfflineSubjectQuestion> _englishQuestions = [
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Which word is a noun?', answer: 'cat', choices: ['cat', 'run', 'happy', 'quickly'], explanation: 'A noun names a person, place, thing, or idea.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the correct verb: The dog ___ fast.', answer: 'runs', choices: ['run', 'runs', 'running', 'runned'], explanation: 'We add -s for he, she, or it.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Which sentence uses correct punctuation?', answer: 'I like apples.', choices: ['I like apples.', 'I like apples', 'I like apples!?', 'I like apples..'], explanation: 'A statement ends with a period.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'What is the simple past form of walk?', answer: 'walked', choices: ['walked', 'walking', 'walks', 'walken'], explanation: 'Simple past often adds -ed.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'What is the simple future form of play?', answer: 'will play', choices: ['played', 'play', 'will play', 'playing'], explanation: 'We use will + base verb for future.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Reading', prompt: 'What is the main idea of the story about Mia and a bird?', answer: 'A bird lived in the garden.', choices: ['A bird lived in the garden.', 'Mia likes to sing.', 'The garden is cold.', 'The bird was green.'], explanation: 'The main idea is the big point of the story.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Reading', prompt: 'Choose the detail that fits a rainy day story.', answer: 'The children wore boots.', choices: ['The children wore boots.', 'The sky was blue.', 'The flowers were blooming.', 'The sun was hot.'], explanation: 'A detail is a small supporting fact.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Vocabulary', prompt: 'Choose the synonym of big.', answer: 'huge', choices: ['huge', 'tiny', 'slow', 'sad'], explanation: 'A synonym has a similar meaning.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Vocabulary', prompt: 'Choose the antonym of happy.', answer: 'sad', choices: ['sad', 'bright', 'friendly', 'quick'], explanation: 'An antonym has the opposite meaning.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Vocabulary', prompt: 'Which word is a homophone for blue?', answer: 'blew', choices: ['blew', 'glue', 'shoe', 'tree'], explanation: 'Homophones sound the same but are spelled differently.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Phonics', prompt: 'Which word begins with the sh sound?', answer: 'ship', choices: ['ship', 'cat', 'dog', 'sun'], explanation: 'Ship begins with the /sh/ sound.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Phonics', prompt: 'Which word has the long a sound?', answer: 'cake', choices: ['cake', 'dog', 'hat', 'pig'], explanation: 'Cake uses the long a sound.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the adjective in the sentence: The red kite flew high.', answer: 'red', choices: ['red', 'kite', 'flew', 'high'], explanation: 'An adjective describes a noun.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the pronoun.', answer: 'they', choices: ['desk', 'green', 'they', 'jump'], explanation: 'A pronoun replaces a noun.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the correct article: ___ apple is on the table.', answer: 'An', choices: ['An', 'A', 'The', 'And'], explanation: 'An is used before a vowel sound.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'What is the plural of child?', answer: 'children', choices: ['childs', 'childes', 'childrens', 'children'], explanation: 'Some plurals are irregular.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Reading', prompt: 'Which sentence is a question?', answer: 'Where is the ball?', choices: ['The ball is red.', 'Kick the ball.', 'Where is the ball?', 'That is a big ball!'], explanation: 'A question ends with a question mark.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Vocabulary', prompt: 'Which word means almost the same as quick?', answer: 'fast', choices: ['slow', 'late', 'soft', 'fast'], explanation: 'Fast is a synonym of quick.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the sentence with correct capitalization.', answer: 'The dog ran home.', choices: ['the dog ran home.', 'The dog ran Home.', 'the Dog ran home.', 'The dog ran home.'], explanation: 'The first word and proper nouns should be capitalized.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Reading', prompt: 'Choose the main idea: Bees visit flowers and make honey.', answer: 'Bees are helpful insects.', choices: ['Flowers are always yellow.', 'Honey is never sweet.', 'Bees live in the ocean.', 'Bees are helpful insects.'], explanation: 'The main idea tells the big message.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Phonics', prompt: 'Which word begins with the ch sound?', answer: 'chair', choices: ['chair', 'sun', 'dog', 'ship'], explanation: 'Chair begins with the /ch/ sound.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the verb in the sentence: The bird sings in the tree.', answer: 'sings', choices: ['bird', 'tree', 'sings', 'the'], explanation: 'A verb shows action or state.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Vocabulary', prompt: 'Choose the opposite of empty.', answer: 'full', choices: ['blank', 'open', 'full', 'quiet'], explanation: 'Full is the opposite of empty.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Reading', prompt: 'Choose what happens first: First Mia planted a seed. Then she watered it. Last, it sprouted.', answer: 'Mia planted a seed.', choices: ['The seed sprouted.', 'Mia picked a flower.', 'Mia watered the seed.', 'Mia planted a seed.'], explanation: 'Sequencing tells us the order of events.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the word that completes the sentence: She ___ a book every night.', answer: 'reads', choices: ['read', 'reading', 'reads', 'reader'], explanation: 'With she, we use reads.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Vocabulary', prompt: 'Choose the correctly spelled word.', answer: 'friend', choices: ['freind', 'frend', 'friend', 'friand'], explanation: 'Friend is spelled correctly.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Reading', prompt: 'Choose the effect: It rained all afternoon, so the game was moved inside.', answer: 'The game was moved inside.', choices: ['It rained all afternoon.', 'The sun came out.', 'The field became dry.', 'The game was moved inside.'], explanation: 'The effect is the result of the rain.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the sentence with commas in the correct places.', answer: 'I packed pens, paper, and glue.', choices: ['I packed, pens paper and glue.', 'I packed pens paper, and glue.', 'I packed pens, paper, and glue.', 'I, packed pens paper and glue.'], explanation: 'Commas help separate items in a list.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Phonics', prompt: 'Which word has the long o sound?', answer: 'home', choices: ['cat', 'log', 'home', 'pig'], explanation: 'Home uses the long o sound.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Reading', prompt: 'Choose the fact.', answer: 'A week has seven days.', choices: ['Saturday is the best day.', 'Blue is the prettiest color.', 'Reading is more fun than math.', 'A week has seven days.'], explanation: 'A fact can be proven.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Grammar', prompt: 'Choose the correct sentence.', answer: 'She is my friend.', choices: ['She is my friend.', 'She am my friend.', 'She are my friend.', 'She be my friend.'], explanation: 'Use is with she.'),
    OfflineSubjectQuestion(subject: 'English', topic: 'Vocabulary', prompt: 'Choose the correct meaning of tiny.', answer: 'very small', choices: ['very small', 'very loud', 'very bright', 'very heavy'], explanation: 'Tiny means very small.'),
  ];

  static const List<OfflineSubjectQuestion> _mathQuestions = [
    OfflineSubjectQuestion(subject: 'Math', topic: 'Addition', prompt: '8 + 7 = ?', answer: '15', choices: ['12', '13', '14', '15'], explanation: 'Add the numbers together.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Addition', prompt: '24 + 16 = ?', answer: '40', choices: ['36', '38', '40', '42'], explanation: '24 and 16 make 40.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Subtraction', prompt: '18 - 7 = ?', answer: '11', choices: ['9', '10', '11', '12'], explanation: 'Subtract 7 from 18.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Subtraction', prompt: '30 - 6 = ?', answer: '24', choices: ['22', '23', '24', '25'], explanation: '30 minus 6 equals 24.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Multiplication', prompt: '6 × 4 = ?', answer: '24', choices: ['20', '22', '24', '26'], explanation: 'Multiply 6 by 4.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Multiplication', prompt: '7 × 3 = ?', answer: '21', choices: ['18', '19', '20', '21'], explanation: 'Seven groups of three equals 21.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Division', prompt: '20 ÷ 4 = ?', answer: '5', choices: ['4', '5', '6', '8'], explanation: 'Twenty split into four equal groups is five.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Division', prompt: '32 ÷ 8 = ?', answer: '4', choices: ['3', '4', '5', '6'], explanation: '32 divided by 8 equals 4.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Place Value', prompt: 'What is the value of the 7 in 574?', answer: '70', choices: ['7', '70', '700', '7000'], explanation: 'The 7 is in the tens place.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Place Value', prompt: 'What is 400 + 30 + 2?', answer: '432', choices: ['423', '432', '342', '324'], explanation: 'Add the parts of the number.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Rounding', prompt: 'Round 47 to the nearest ten.', answer: '50', choices: ['40', '45', '50', '60'], explanation: '47 rounds up to the next ten.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Rounding', prompt: 'Round 123 to the nearest hundred.', answer: '100', choices: ['100', '120', '200', '123'], explanation: '123 is closer to 100.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Roman Numerals', prompt: 'What number is VII?', answer: '7', choices: ['5', '6', '7', '8'], explanation: 'V is 5 and I is 1.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Roman Numerals', prompt: 'What number is XII?', answer: '12', choices: ['10', '11', '12', '13'], explanation: 'X is 10 and II is 2.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Measurement', prompt: 'How many centimeters are in 1 meter?', answer: '100', choices: ['10', '100', '1000', '10000'], explanation: 'There are 100 centimeters in 1 meter.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Measurement', prompt: 'How many milliliters are in 1 liter?', answer: '1000', choices: ['10', '100', '1000', '10000'], explanation: 'There are 1000 milliliters in 1 liter.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Fractions', prompt: 'What is 1/2 + 1/2?', answer: '1', choices: ['1/2', '1', '2', '1/4'], explanation: 'Two halves make one whole.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Fractions', prompt: 'What is 3/4 of 8?', answer: '6', choices: ['4', '6', '8', '10'], explanation: 'Three quarters of 8 is 6.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Time', prompt: 'What time is 3:15?', answer: '3:15', choices: ['3:00', '3:15', '3:30', '3:45'], explanation: 'The clock shows quarter past three.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Time', prompt: 'What is 1 hour after 2:30?', answer: '3:30', choices: ['2:30', '3:00', '3:30', '4:00'], explanation: 'Add 60 minutes.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Order of Operations', prompt: 'What is 6 + 2 × 3?', answer: '12', choices: ['8', '12', '16', '18'], explanation: 'Multiply first, then add.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Order of Operations', prompt: 'What is (4 + 2) × 3?', answer: '18', choices: ['12', '14', '16', '18'], explanation: 'Do the parentheses first.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Geometry', prompt: 'How many sides does a triangle have?', answer: '3', choices: ['2', '3', '4', '5'], explanation: 'A triangle has three sides.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Geometry', prompt: 'How many corners does a rectangle have?', answer: '4', choices: ['2', '3', '4', '6'], explanation: 'A rectangle has four corners.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Patterns', prompt: 'What comes next: 2, 4, 6, ___?', answer: '8', choices: ['6', '7', '8', '9'], explanation: 'The pattern adds 2 each time.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Patterns', prompt: 'What comes next: 10, 8, 6, ___?', answer: '4', choices: ['2', '3', '4', '5'], explanation: 'The pattern subtracts 2 each time.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Money', prompt: 'How much is 2 quarters?', answer: '50 cents', choices: ['25 cents', '50 cents', '75 cents', '1 dollar'], explanation: 'Each quarter is 25 cents.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Money', prompt: 'How many pennies make 1 dollar?', answer: '100', choices: ['10', '50', '100', '1000'], explanation: 'One dollar equals 100 pennies.'),
    OfflineSubjectQuestion(subject: 'Math', topic: 'Word Problems', prompt: 'If 3 apples cost 6 dollars, how much does 1 apple cost?', answer: '2 dollars', choices: ['1 dollar', '2 dollars', '3 dollars', '4 dollars'], explanation: 'Divide the total by 3.'),
  ];

  static const List<OfflineSubjectQuestion> _scienceQuestions = [
    OfflineSubjectQuestion(subject: 'Science', topic: 'Living Things', prompt: 'Which is a living thing?', answer: 'tree', choices: ['tree', 'rock', 'chair', 'river'], explanation: 'Living things grow and need food and water.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Living Things', prompt: 'Plants need sunlight to make food.', answer: 'True', choices: ['True', 'False', 'Maybe', 'Never'], explanation: 'Plants use sunlight to make food.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Animals', prompt: 'Which animal can fly?', answer: 'bird', choices: ['fish', 'bird', 'frog', 'cow'], explanation: 'Birds have wings that help them fly.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Weather', prompt: 'What do we wear when it is cold?', answer: 'coat', choices: ['coat', 'swimsuit', 'flip-flops', 'shorts'], explanation: 'A coat helps keep us warm.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Space', prompt: 'The Earth goes around the ___.', answer: 'Sun', choices: ['Moon', 'Sun', 'Stars', 'Clouds'], explanation: 'Earth orbits the Sun.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Matter', prompt: 'Which is a solid?', answer: 'ice', choices: ['ice', 'water', 'steam', 'rain'], explanation: 'Ice keeps its own shape.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Human Body', prompt: 'What do humans use to breathe?', answer: 'lungs', choices: ['lungs', 'teeth', 'hair', 'skin'], explanation: 'The lungs help us breathe.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Energy', prompt: 'Which object gives us light and heat?', answer: 'the Sun', choices: ['the Sun', 'a rock', 'a shoe', 'a pencil'], explanation: 'The Sun gives Earth light and heat.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Matter', prompt: 'What happens when water freezes?', answer: 'It becomes ice.', choices: ['It becomes ice.', 'It becomes steam.', 'It disappears.', 'It turns into sand.'], explanation: 'Freezing turns liquid water into ice.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Weather', prompt: 'Which tool helps us measure temperature?', answer: 'thermometer', choices: ['thermometer', 'ruler', 'scale', 'compass'], explanation: 'A thermometer measures temperature.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Plants', prompt: 'Which part of the plant takes in water from the soil?', answer: 'roots', choices: ['flower', 'fruit', 'roots', 'seed'], explanation: 'Roots absorb water.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Plants', prompt: 'What do plants need to make their own food?', answer: 'sunlight', choices: ['sunlight', 'plastic', 'rocks', 'cars'], explanation: 'Plants use sunlight in photosynthesis.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Animals', prompt: 'Which animal is a mammal?', answer: 'dog', choices: ['frog', 'shark', 'butterfly', 'dog'], explanation: 'Mammals have hair and feed milk to babies.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Habitats', prompt: 'A cactus is best suited for which habitat?', answer: 'desert', choices: ['desert', 'deep ocean', 'rain cloud', 'polar ice'], explanation: 'Cacti live in dry deserts.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Magnets', prompt: 'Which material is attracted by many magnets?', answer: 'iron', choices: ['wood', 'paper', 'iron', 'rubber'], explanation: 'Magnets attract iron.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Weather', prompt: 'Clouds are made mostly of tiny droplets of what?', answer: 'water', choices: ['sand', 'smoke', 'rocks', 'water'], explanation: 'Clouds are made of tiny droplets of water.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Forces', prompt: 'A force is a push or a ___ .', answer: 'pull', choices: ['color', 'shadow', 'pull', 'sound'], explanation: 'A force can push or pull.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Space', prompt: 'About how long is one trip around the Sun?', answer: '1 year', choices: ['1 day', '1 week', '1 hour', '1 year'], explanation: 'Earth takes about a year to orbit the Sun.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Moon', prompt: 'Why can we see the Moon at night?', answer: 'It reflects sunlight.', choices: ['It makes its own fire.', 'It is a cloud.', 'It is a planet.', 'It reflects sunlight.'], explanation: 'The Moon shines because it reflects sunlight.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Water Cycle', prompt: 'When liquid water changes into water vapor, it is called ___ .', answer: 'evaporation', choices: ['freezing', 'melting', 'evaporation', 'pollination'], explanation: 'Evaporation changes liquid water into vapor.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Food Chains', prompt: 'In a food chain, which living thing makes its own food?', answer: 'plant', choices: ['rabbit', 'hawk', 'worm', 'plant'], explanation: 'Plants are producers.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Human Body', prompt: 'What is one job of the skeleton?', answer: 'support the body', choices: ['taste food', 'make sunlight', 'pump air outside', 'support the body'], explanation: 'The skeleton supports the body.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Simple Machines', prompt: 'A ramp is an example of which simple machine?', answer: 'inclined plane', choices: ['pulley', 'wheel and axle', 'inclined plane', 'lever'], explanation: 'A ramp is an inclined plane.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Sound', prompt: 'Sound is caused by ___ .', answer: 'vibrations', choices: ['stillness', 'darkness', 'gravity only', 'vibrations'], explanation: 'Vibrations create sound.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Light', prompt: 'A transparent object lets you ___ .', answer: 'see through it', choices: ['eat it', 'hear through it', 'turn it into soil', 'see through it'], explanation: 'Transparent objects can be seen through.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Electricity', prompt: 'For a bulb to light, a circuit must have a complete ___ .', answer: 'path', choices: ['shadow', 'leaf', 'cloud', 'path'], explanation: 'A complete path allows electricity to flow.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Health', prompt: 'Which habit helps keep your body healthy?', answer: 'washing your hands', choices: ['never sleeping', 'skipping water', 'eating only candy', 'washing your hands'], explanation: 'Good hygiene helps prevent illness.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Human Body', prompt: 'Which organ pumps blood through the body?', answer: 'heart', choices: ['stomach', 'skin', 'heart', 'tooth'], explanation: 'The heart pumps blood.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Energy', prompt: 'Which object gives Earth light and heat?', answer: 'the Sun', choices: ['a pencil', 'a backpack', 'a rock', 'the Sun'], explanation: 'The Sun is our main energy source.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Health', prompt: 'Which habit helps keep your body healthy?', answer: 'washing your hands', choices: ['never sleeping', 'skipping water', 'eating only candy', 'washing your hands'], explanation: 'Good hygiene helps prevent illness.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Plants', prompt: 'Which part of the plant makes seeds?', answer: 'flower', choices: ['flower', 'root', 'leaf', 'stem'], explanation: 'Flowers make seeds in many plants.'),
    OfflineSubjectQuestion(subject: 'Science', topic: 'Weather', prompt: 'What do we call water that falls from clouds?', answer: 'rain', choices: ['rain', 'sunlight', 'wind', 'ice cream'], explanation: 'Rain is water falling from clouds.'),
  ];

  static List<OfflineSubjectQuestion> questionsFor(
    OfflineSubject subject, {
    int count = 32,
    Set<String>? topics,
  }) {
    final pool = switch (subject) {
      OfflineSubject.english => _englishQuestions,
      OfflineSubject.math => _mathQuestions,
      OfflineSubject.science => _scienceQuestions,
    };

    final filtered = topics == null || topics.isEmpty
        ? pool
        : pool.where((question) {
            final normalizedTopic = _normalizeTopic(question.topic);
            return topics.any((topic) => _normalizeTopic(topic) == normalizedTopic);
          }).toList(growable: false);

    final usePool = filtered.isEmpty ? pool : filtered;
    return usePool.take(count).toList(growable: false);
  }

  /// Compiled once rather than rebuilt on every call.
  static final RegExp _whitespaceRun = RegExp(r'\s+');

  static String _normalizeTopic(String value) {
    return value.toLowerCase().replaceAll(_whitespaceRun, ' ').trim();
  }
}
