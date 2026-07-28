part of '../../subject_question_bank.dart';

const List<_LeveledQuestion> _englishQuestionsAndSpeechQuestions = [
  // --- Questions (17) ---
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the question word that asks about a place.',
      prompt: '___ is the ball?',
      correctAnswer: 'Where',
      choices: ['What', 'Who', 'When'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question.',
      prompt: '___ is your name?',
      correctAnswer: 'What',
      choices: ['Where', 'How many', 'Why not'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question word.',
      prompt: '___ is your name?',
      correctAnswer: 'What',
      choices: ['Run', 'Blue', 'Happy'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the sentence that is a question.',
      prompt: 'Which sentence is a question?',
      correctAnswer: 'Do you like dogs?',
      choices: ['I like dogs.', 'Dogs are nice.', 'My dog runs fast.'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct punctuation mark.',
      prompt: 'A question ends with a ___',
      correctAnswer: 'question mark (?)',
      choices: ['period (.)', 'comma (,)', 'exclamation mark (!)'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question word.',
      prompt: '___ is that girl standing by the door?',
      correctAnswer: 'Who',
      choices: ['What', 'Where', 'When'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question.',
      prompt: 'Turn this into a question: \'She likes cats.\'',
      correctAnswer: 'Does she like cats?',
      choices: ['Is she like cats?', 'She likes cats?', 'Do she likes cats?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question word.',
      prompt: '___ do you live?',
      correctAnswer: 'Where',
      choices: ['Who', 'Why', 'What'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question.',
      prompt: 'Turn this into a question: \'They are playing outside.\'',
      correctAnswer: 'Are they playing outside?',
      choices: [
        'Do they playing outside?',
        'Is they playing outside?',
        'They are playing outside?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question word.',
      prompt: '___ are you crying?',
      correctAnswer: 'Why',
      choices: ['Who', 'How', 'What'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question.',
      prompt: 'Turn this into a question: \'He has finished his homework.\'',
      correctAnswer: 'Has he finished his homework?',
      choices: [
        'Does he have finished his homework?',
        'Is he finished his homework?',
        'He has finished his homework?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question word.',
      prompt: '___ books do you have?',
      correctAnswer: 'How many',
      choices: ['How much', 'How long', 'How often'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question.',
      prompt: 'Turn this into a question: \'The train leaves at noon.\'',
      correctAnswer: 'When does the train leave?',
      choices: [
        'When the train leaves?',
        'When is the train leaves?',
        'When does the train leaves?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question word.',
      prompt: '___ does this box weigh?',
      correctAnswer: 'How much',
      choices: ['How many', 'How long', 'How far'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question.',
      prompt: 'This pen belongs to Maria. Ask about the owner.',
      correctAnswer: 'Whose pen is this?',
      choices: [
        'Who pen is this?',
        'Which pen is Maria?',
        'Who\'s pen this is?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct indirect question.',
      prompt: 'Can you tell me ___ the museum opens?',
      correctAnswer: 'when',
      choices: ['when does', 'what time does', 'when is'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Questions',
      instruction: 'Choose the correct question.',
      prompt:
          'The boys were playing soccer at the park. Ask about the location.',
      correctAnswer: 'Where were the boys playing soccer?',
      choices: [
        'Where was the boys playing soccer?',
        'Where did the boys were playing soccer?',
        'Where the boys were playing soccer?'
      ],
    ),
  ),
  // --- Tag Questions (280) ---
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'You like ice cream, ___?',
      correctAnswer: "don't you",
      choices: ['do you', 'aren\'t you', 'isn\'t it'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'She is happy, ___?',
      correctAnswer: "isn't she",
      choices: ["is she", "doesn't she", "wasn't he"],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'It is sunny today, ___?',
      correctAnswer: 'isn\'t it',
      choices: ['is it', 'isn\'t he', 'aren\'t it'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'You like pizza, ___?',
      correctAnswer: 'don\'t you',
      choices: ['do you', 'doesn\'t you', 'don\'t he'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'She is your sister, ___?',
      correctAnswer: 'isn\'t she',
      choices: ['is she', 'isn\'t her', 'aren\'t she'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'They can swim, ___?',
      correctAnswer: 'can\'t they',
      choices: ['can they', 'couldn\'t they', 'can\'t them'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'He doesn\'t like carrots, ___?',
      correctAnswer: 'does he',
      choices: ['doesn\'t he', 'does she', 'did he'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'We are late, ___?',
      correctAnswer: 'aren\'t we',
      choices: ['are we', 'isn\'t we', 'aren\'t us'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The dog is hungry, ___?',
      correctAnswer: 'isn\'t it',
      choices: ['is it', 'isn\'t he', 'aren\'t it'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'You haven\'t seen my keys, ___?',
      correctAnswer: 'have you',
      choices: ['haven\'t you', 'has you', 'have she'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Your parents will come to the show, ___?',
      correctAnswer: 'won\'t they',
      choices: ['will they', 'wouldn\'t they', 'won\'t them'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'She was singing loudly, ___?',
      correctAnswer: 'wasn\'t she',
      choices: ['was she', 'weren\'t she', 'isn\'t she'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The students didn\'t finish the test, ___?',
      correctAnswer: 'did they',
      choices: ['didn\'t they', 'do they', 'weren\'t they'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Let\'s go to the park, ___?',
      correctAnswer: 'shall we',
      choices: ['will we', 'shall you', 'won\'t we'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Nobody called me, ___?',
      correctAnswer: 'did they',
      choices: ['didn\'t they', 'did he', 'does they'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'You would help me, ___?',
      correctAnswer: 'wouldn\'t you',
      choices: ['would you', 'won\'t you', 'didn\'t you'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'There isn\'t any milk left, ___?',
      correctAnswer: 'is there',
      choices: ['isn\'t there', 'are there', 'was there'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'He is tall, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Tom is short, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Jake is happy, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Carlos is sad, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Liam is hungry, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Diego is thirsty, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Ravi is tired, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Noah is sleepy, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ethan is smart, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Marcus is kind, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'She is funny, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Maria is brave, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Emma is strong, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Priya is fast, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Sofia is slow, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Anna is quiet, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Grace is loud, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Layla is friendly, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Chloe is careful, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Nina is clean, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'It is new, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'The cat is old, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The dog is big, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'The book is small, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The weather is young, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'The movie is ready, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'This box is late, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'That car is early, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The house is bright, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Your bag is heavy, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Her phone is light, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'His pencil is short, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The garden is famous, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'The bridge is popular, ___?',
      correctAnswer: 'isn\'t it?',
      choices: ['is it?', 'doesn\'t it?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'You are healthy, ___?',
      correctAnswer: 'aren\'t you?',
      choices: ['are you?', 'don\'t you?', 'aren\'t we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'We are excited, ___?',
      correctAnswer: 'aren\'t we?',
      choices: ['are we?', 'don\'t we?', 'aren\'t they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'They are bored, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'The boys are polite, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The girls are curious, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Your parents are gentle, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The students are calm, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'The twins are wild, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The dogs are silly, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Those shoes are serious, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Tom and Jake are clever, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Maria and Emma are lazy, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The teachers are active, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'The children are helpful, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'My cousins are cheerful, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'The players are patient, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'don\'t they?', 'aren\'t you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'He is talented, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Tom is creative, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Jake is colorful, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Carlos is delicious, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Liam is fresh, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Diego is warm, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ravi is cold, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Noah is hot, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Ethan is dark, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Marcus is dirty, ___?',
      correctAnswer: 'isn\'t he?',
      choices: ['is he?', 'doesn\'t he?', 'isn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'She is wide, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Maria is narrow, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Emma is thick, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Priya is thin, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Sofia is sharp, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Anna is soft, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Grace is hard, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Pick the tag that correctly completes the sentence.',
      prompt: 'Layla is empty, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Chloe is full, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Nina is modern, ___?',
      correctAnswer: 'isn\'t she?',
      choices: ['is she?', 'doesn\'t she?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'He isn\'t tired, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Tom isn\'t happy, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Jake isn\'t ready, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Carlos isn\'t busy, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Liam isn\'t careful, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Diego isn\'t honest, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Ravi isn\'t polite, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Noah isn\'t nervous, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ethan isn\'t excited, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Marcus isn\'t proud, ___?',
      correctAnswer: 'is he?',
      choices: ['isn\'t he?', 'does he?', 'is she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'She isn\'t shy, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Maria isn\'t generous, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Emma isn\'t clumsy, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Priya isn\'t selfish, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Sofia isn\'t talkative, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Anna isn\'t stubborn, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Grace isn\'t cautious, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Layla isn\'t confident, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Chloe isn\'t cheerful, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Nina isn\'t grumpy, ___?',
      correctAnswer: 'is she?',
      choices: ['isn\'t she?', 'does she?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'It isn\'t hopeful, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'The cat isn\'t thoughtful, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'The dog isn\'t reliable, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The book isn\'t punctual, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The weather isn\'t organized, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'The movie isn\'t messy, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'This box isn\'t forgetful, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'That car isn\'t patient, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The house isn\'t graceful, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Your bag isn\'t heavy, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Her phone isn\'t new, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'His pencil isn\'t sharp, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The garden isn\'t pessimistic, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'The bridge isn\'t sociable, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'is he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'You aren\'t energetic, ___?',
      correctAnswer: 'are you?',
      choices: ['aren\'t you?', 'do you?', 'are we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Noah doesn\'t like pizza, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'does she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ethan doesn\'t play soccer, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'does she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Marcus doesn\'t watch cartoons, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'does she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'She doesn\'t read comics, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Maria doesn\'t eat vegetables, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Emma doesn\'t drink milk, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Priya doesn\'t do homework, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Sofia doesn\'t watch movies, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Anna doesn\'t play video games, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Grace doesn\'t ride bikes, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Layla doesn\'t swim in the pool, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Chloe doesn\'t study English, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Nina doesn\'t clean her room, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'It doesn\'t brush its teeth, ___?',
      correctAnswer: 'does it?',
      choices: ['doesn\'t it?', 'is it?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'The cat doesn\'t walk to school, ___?',
      correctAnswer: 'does it?',
      choices: ['doesn\'t it?', 'is it?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'The dog doesn\'t listen to music, ___?',
      correctAnswer: 'does it?',
      choices: ['doesn\'t it?', 'is it?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The puppy doesn\'t draw pictures, ___?',
      correctAnswer: 'does it?',
      choices: ['doesn\'t it?', 'is it?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The kitten doesn\'t sing songs, ___?',
      correctAnswer: 'does it?',
      choices: ['doesn\'t it?', 'is it?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'You don\'t dance well, ___?',
      correctAnswer: 'do you?',
      choices: ['don\'t you?', 'are you?', 'do we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'We don\'t cook dinner, ___?',
      correctAnswer: 'do we?',
      choices: ['don\'t we?', 'are we?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'They don\'t wash the dishes, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The boys don\'t feed the dog, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'The girls don\'t water the plants, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Your parents don\'t paint the wall, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The students don\'t write letters, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The twins don\'t play chess, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Tom and Jake don\'t collect stamps, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Maria and Emma don\'t bake cookies, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'The teachers don\'t run fast, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'The children don\'t jump high, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'My cousins don\'t climb trees, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'The players don\'t tell jokes, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'do you?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'He doesn\'t share toys, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'does she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Tom doesn\'t play the guitar, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'does she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tag question.',
      prompt: 'Jake doesn\'t speak French, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'does she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'He can swim across the lake, ___?',
      correctAnswer: 'can\'t he?',
      choices: ['can he?', 'won\'t he?', 'can\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Tom will help his brother, ___?',
      correctAnswer: 'won\'t he?',
      choices: ['will he?', 'shouldn\'t he?', 'won\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Jake should arrive on time, ___?',
      correctAnswer: 'shouldn\'t he?',
      choices: ['should he?', 'mustn\'t he?', 'shouldn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Carlos must finish the homework, ___?',
      correctAnswer: 'mustn\'t he?',
      choices: ['must he?', 'couldn\'t he?', 'mustn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Liam could win the race, ___?',
      correctAnswer: 'couldn\'t he?',
      choices: ['could he?', 'wouldn\'t he?', 'couldn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Diego would understand the lesson, ___?',
      correctAnswer: 'wouldn\'t he?',
      choices: ['would he?', 'can\'t he?', 'wouldn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Ravi can remember the password, ___?',
      correctAnswer: 'can\'t he?',
      choices: ['can he?', 'won\'t he?', 'can\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Noah will pass the test, ___?',
      correctAnswer: 'won\'t he?',
      choices: ['will he?', 'shouldn\'t he?', 'won\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ethan should join the choir, ___?',
      correctAnswer: 'shouldn\'t he?',
      choices: ['should he?', 'mustn\'t he?', 'shouldn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Marcus must fix the computer, ___?',
      correctAnswer: 'mustn\'t he?',
      choices: ['must he?', 'couldn\'t he?', 'mustn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'She could bring an umbrella, ___?',
      correctAnswer: 'couldn\'t she?',
      choices: ['could she?', 'wouldn\'t she?', 'couldn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Carlos can\'t come to the party, ___?',
      correctAnswer: 'can he?',
      choices: ['can\'t he?', 'should he?', 'can she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Liam won\'t leave early, ___?',
      correctAnswer: 'will he?',
      choices: ['won\'t he?', 'must he?', 'will she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Diego shouldn\'t win the match, ___?',
      correctAnswer: 'should he?',
      choices: ['shouldn\'t he?', 'could he?', 'should she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Ravi mustn\'t understand this, ___?',
      correctAnswer: 'must he?',
      choices: ['mustn\'t he?', 'would he?', 'must she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Noah couldn\'t pass the exam, ___?',
      correctAnswer: 'could he?',
      choices: ['couldn\'t he?', 'may he?', 'could she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ethan wouldn\'t join us today, ___?',
      correctAnswer: 'would he?',
      choices: ['wouldn\'t he?', 'might he?', 'would she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Marcus may not apologize to her, ___?',
      correctAnswer: 'may he?',
      choices: ['may not he?', 'can he?', 'may she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'She might not cooperate with the team, ___?',
      correctAnswer: 'might she?',
      choices: ['might not she?', 'will she?', 'might he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Maria can\'t forget the plan, ___?',
      correctAnswer: 'can she?',
      choices: ['can\'t she?', 'should she?', 'can he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Emma won\'t share the snacks, ___?',
      correctAnswer: 'will she?',
      choices: ['won\'t she?', 'must she?', 'will he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Priya shouldn\'t wait for the bus, ___?',
      correctAnswer: 'should she?',
      choices: ['shouldn\'t she?', 'could she?', 'should he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'He was late, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Tom was tired, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Jake was happy, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Carlos was at home, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Liam was in the park, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Diego was ready, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ravi was sick, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Noah was busy, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Ethan was surprised, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Marcus was nervous, ___?',
      correctAnswer: 'wasn\'t he?',
      choices: ['was he?', 'didn\'t he?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Diego wasn\'t ready, ___?',
      correctAnswer: 'was he?',
      choices: ['wasn\'t he?', 'did he?', 'was she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Ravi wasn\'t home, ___?',
      correctAnswer: 'was he?',
      choices: ['wasn\'t he?', 'did he?', 'was she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Noah wasn\'t calm, ___?',
      correctAnswer: 'was he?',
      choices: ['wasn\'t he?', 'did he?', 'was she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Ethan wasn\'t careful, ___?',
      correctAnswer: 'was he?',
      choices: ['wasn\'t he?', 'did he?', 'was she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Marcus wasn\'t polite, ___?',
      correctAnswer: 'was he?',
      choices: ['wasn\'t he?', 'did he?', 'was she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'She wasn\'t quiet, ___?',
      correctAnswer: 'was she?',
      choices: ['wasn\'t she?', 'did she?', 'was he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Maria wasn\'t early, ___?',
      correctAnswer: 'was she?',
      choices: ['wasn\'t she?', 'did she?', 'was he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Emma wasn\'t warm, ___?',
      correctAnswer: 'was she?',
      choices: ['wasn\'t she?', 'did she?', 'was he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Priya wasn\'t comfortable, ___?',
      correctAnswer: 'was she?',
      choices: ['wasn\'t she?', 'did she?', 'was he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Sofia wasn\'t satisfied, ___?',
      correctAnswer: 'was she?',
      choices: ['wasn\'t she?', 'did she?', 'was he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Marcus went home early, ___?',
      correctAnswer: 'didn\'t he?',
      choices: ['did he?', 'doesn\'t he?', 'didn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'She called her friend, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Maria finished the project, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Emma cooked dinner, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Priya cleaned the room, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Sofia visited the museum, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Anna watched the show, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Grace studied for the test, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Layla wrote a letter, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Chloe bought a gift, ___?',
      correctAnswer: 'didn\'t she?',
      choices: ['did she?', 'doesn\'t she?', 'didn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Jake didn\'t call, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Carlos didn\'t finish the homework, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Liam didn\'t arrive on time, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Diego didn\'t cook dinner, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Ravi didn\'t clean the room, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Noah didn\'t visit the museum, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the tag that correctly completes the sentence.',
      prompt: 'Ethan didn\'t watch the show, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Marcus didn\'t study for the test, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'She didn\'t write the letter, ___?',
      correctAnswer: 'did she?',
      choices: ['didn\'t she?', 'does she?', 'did he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the sentence with the correct tag.',
      prompt: 'Maria didn\'t buy the gift, ___?',
      correctAnswer: 'did she?',
      choices: ['didn\'t she?', 'does she?', 'did he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'I am late, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'I am right, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'I am wrong, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'I am smart, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'I am tired, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'I am ready, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'I am lucky, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'I am careful, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'I am honest, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'I am correct, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'I am funny, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'I am brave, ___?',
      correctAnswer: 'aren\'t I?',
      choices: ['am I?', 'isn\'t I?', 'are I?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'He never arrives late, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'She never eats meat, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'They never listen carefully, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'are they?', 'does he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'We never complain about school, ___?',
      correctAnswer: 'do we?',
      choices: ['don\'t we?', 'are we?', 'does she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'It never rains here in summer, ___?',
      correctAnswer: 'does it?',
      choices: ['doesn\'t it?', 'is it?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'She never called back, ___?',
      correctAnswer: 'did she?',
      choices: ['didn\'t she?', 'does she?', 'did they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'He never finished the race, ___?',
      correctAnswer: 'did he?',
      choices: ['didn\'t he?', 'does he?', 'did they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Nobody knows the answer, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'does he?', 'are they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Nobody called the teacher, ___?',
      correctAnswer: 'did they?',
      choices: ['didn\'t they?', 'does he?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Nobody is home right now, ___?',
      correctAnswer: 'are they?',
      choices: ['aren\'t they?', 'is he?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Nobody was there on time, ___?',
      correctAnswer: 'were they?',
      choices: ['weren\'t they?', 'was he?', 'are they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'No one knows the secret, ___?',
      correctAnswer: 'do they?',
      choices: ['don\'t they?', 'does she?', 'are they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'No one is watching the game, ___?',
      correctAnswer: 'are they?',
      choices: ['aren\'t they?', 'is it?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'No one came to the party, ___?',
      correctAnswer: 'did they?',
      choices: ['didn\'t they?', 'does he?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'No one was ready for the trip, ___?',
      correctAnswer: 'were they?',
      choices: ['weren\'t they?', 'was she?', 'are they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Nothing happened yesterday, ___?',
      correctAnswer: 'did it?',
      choices: ['didn\'t it?', 'does it?', 'did they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Nothing is wrong with the car, ___?',
      correctAnswer: 'is it?',
      choices: ['isn\'t it?', 'does it?', 'are they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Nothing matters to him now, ___?',
      correctAnswer: 'does it?',
      choices: ['doesn\'t it?', 'is it?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'He hardly ever smiles, ___?',
      correctAnswer: 'does he?',
      choices: ['doesn\'t he?', 'is he?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'She hardly ever complains, ___?',
      correctAnswer: 'does she?',
      choices: ['doesn\'t she?', 'is she?', 'do they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Close the door, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Open the window, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'do you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Pass the salt, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'can you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Turn off the light, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Bring your book tomorrow, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'do you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Sit down, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Wait here for a minute, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'do you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Clean your room, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Hurry up, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'do you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Be quiet during the movie, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Don\'t be late, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Don\'t shout in the library, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'do you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Don\'t touch that vase, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Don\'t forget your lunch, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'do you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Don\'t run in the hallway, ___?',
      correctAnswer: 'will you?',
      choices: ['won\'t you?', 'are you?', 'shall we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Let\'s go to the park, ___?',
      correctAnswer: 'shall we?',
      choices: ['will we?', 'aren\'t we?', 'won\'t we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Let\'s start the game, ___?',
      correctAnswer: 'shall we?',
      choices: ['will we?', 'aren\'t we?', 'won\'t we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Let\'s clean up the classroom, ___?',
      correctAnswer: 'shall we?',
      choices: ['will we?', 'aren\'t we?', 'won\'t we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Let\'s sing a song together, ___?',
      correctAnswer: 'shall we?',
      choices: ['will we?', 'aren\'t we?', 'won\'t we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Let\'s take a short break, ___?',
      correctAnswer: 'shall we?',
      choices: ['will we?', 'aren\'t we?', 'won\'t we?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Someone left the door open, ___?',
      correctAnswer: 'didn\'t they?',
      choices: ['did they?', 'doesn\'t he?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Somebody called you yesterday, ___?',
      correctAnswer: 'didn\'t they?',
      choices: ['did they?', 'doesn\'t she?', 'wasn\'t she?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Everyone enjoyed the trip, ___?',
      correctAnswer: 'didn\'t they?',
      choices: ['did they?', 'doesn\'t he?', 'weren\'t they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Everybody finished the test, ___?',
      correctAnswer: 'didn\'t they?',
      choices: ['did they?', 'doesn\'t she?', 'aren\'t they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Someone is watching us, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'isn\'t he?', 'doesn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Complete the tricky tag question.',
      prompt: 'Somebody is waiting outside, ___?',
      correctAnswer: 'aren\'t they?',
      choices: ['are they?', 'isn\'t she?', 'don\'t they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Select the correct tag for this sentence.',
      prompt: 'Everyone was happy at the party, ___?',
      correctAnswer: 'weren\'t they?',
      choices: ['were they?', 'wasn\'t he?', 'aren\'t they?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Fill in the blank with the correct tag question.',
      prompt: 'Everybody knows the rules, ___?',
      correctAnswer: 'don\'t they?',
      choices: ['do they?', 'doesn\'t he?', 'isn\'t he?'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Tag Questions',
      instruction: 'Choose the correct tag question.',
      prompt: 'Someone forgot the tickets, ___?',
      correctAnswer: 'didn\'t they?',
      choices: ['did they?', 'doesn\'t she?', 'wasn\'t he?'],
    ),
  ),
  // --- Active and Passive Voice (280) ---
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence shows the subject doing the action?',
      correctAnswer: 'The dog chased the ball.',
      choices: [
        'The ball was chased by the dog.',
        'The ball is round.',
        'Chasing is fun for dogs.',
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence shows the action happening to the subject?',
      correctAnswer: 'The cake was baked by Mom.',
      choices: [
        'Mom baked the cake.',
        'Mom likes to bake.',
        'The cake tastes sweet.',
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt: 'Change to passive voice: \'The cat chased the mouse.\'',
      correctAnswer: 'The mouse was chased by the cat.',
      choices: [
        'The mouse chased the cat.',
        'The mouse is chasing the cat.',
        'The mouse chases the cat by the cat.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt: 'Change to passive voice: \'Tom painted the fence.\'',
      correctAnswer: 'The fence was painted by Tom.',
      choices: [
        'The fence painted Tom.',
        'Tom was painted the fence.',
        'The fence paints Tom.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive sentence.',
      prompt:
          'Which sentence about the letter is written in the passive voice?',
      correctAnswer: 'The letter was written by Sara.',
      choices: [
        'Sara wrote the letter.',
        'Sara is writing the letter.',
        'Sara will write the letter.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt: 'Change to passive voice: \'The teacher reads the story.\'',
      correctAnswer: 'The story is read by the teacher.',
      choices: [
        'The story reads the teacher.',
        'The teacher was read the story.',
        'The story was reading by the teacher.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active sentence.',
      prompt: 'Which sentence about the ball is written in the active voice?',
      correctAnswer: 'The boy kicked the ball.',
      choices: [
        'The ball was kicked by the boy.',
        'The ball is kicked by the boy.',
        'The ball kicked by the boy.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt: 'Change to passive voice: \'Ants build ant hills.\'',
      correctAnswer: 'Ant hills are built by ants.',
      choices: [
        'Ant hills build ants.',
        'Ants are built by ant hills.',
        'Ant hills built by ants.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive sentence.',
      prompt: 'Which sentence about the cake is written in the passive voice?',
      correctAnswer: 'The cake was baked by Mom.',
      choices: [
        'Mom baked the cake.',
        'Mom bakes the cake.',
        'Mom is baking the cake.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt:
          'Change to passive voice: \'The workers built the bridge in 1990.\'',
      correctAnswer: 'The bridge was built by the workers in 1990.',
      choices: [
        'The bridge built the workers in 1990.',
        'The bridge is built by the workers in 1990.',
        'The workers were built the bridge in 1990.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt: 'Change to passive voice: \'The dog will chase the ball.\'',
      correctAnswer: 'The ball will be chased by the dog.',
      choices: [
        'The ball will chase the dog.',
        'The ball is chased by the dog.',
        'The ball would be chased by the dog.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive sentence.',
      prompt:
          'Which sentence about the window is written in the passive voice?',
      correctAnswer: 'The window was broken by the storm.',
      choices: [
        'The storm broke the window.',
        'The storm was breaking the window.',
        'The storm breaks the window.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt: 'Change to passive voice: \'The chef is cooking dinner.\'',
      correctAnswer: 'Dinner is being cooked by the chef.',
      choices: [
        'Dinner was being cooked by the chef.',
        'The chef is being cooked dinner.',
        'Dinner is cooked by the chef.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt: 'Change to passive voice: \'Someone stole my bicycle.\'',
      correctAnswer: 'My bicycle was stolen.',
      choices: [
        'My bicycle stole someone.',
        'My bicycle is stolen.',
        'Someone was stolen my bicycle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive sentence.',
      prompt:
          'Which sentence about the homework is written in the passive voice?',
      correctAnswer: 'The homework must be finished by tonight.',
      choices: [
        'We must finish the homework by tonight.',
        'The homework must finish tonight.',
        'We must be finished the homework tonight.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive sentence.',
      prompt:
          'Change to passive voice: \'The artist has painted a beautiful mural.\'',
      correctAnswer: 'A beautiful mural has been painted by the artist.',
      choices: [
        'A beautiful mural has painted the artist.',
        'The artist has been painted a beautiful mural.',
        'A beautiful mural was painted the artist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active sentence.',
      prompt: 'Which sentence about the books is written in the active voice?',
      correctAnswer: 'The librarian organized the books.',
      choices: [
        'The books were organized by the librarian.',
        'The books are organized by the librarian.',
        'The books organized by the librarian.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The singer published the fence."',
      correctAnswer: 'Active voice',
      choices: [
        'Neither active nor passive',
        'Both active and passive',
        'Passive voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The photographer completed the wall."',
      correctAnswer: 'Active voice',
      choices: [
        'Neither active nor passive',
        'Both active and passive',
        'Passive voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The doctor chased the car."',
      correctAnswer: 'Active voice',
      choices: [
        'Both active and passive',
        'Neither active nor passive',
        'Passive voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The coach locked the window."',
      correctAnswer: 'Active voice',
      choices: [
        'Both active and passive',
        'Neither active nor passive',
        'Passive voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The cat told the bicycle."',
      correctAnswer: 'Active voice',
      choices: [
        'Both active and passive',
        'Neither active nor passive',
        'Passive voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The painter finished the flag."',
      correctAnswer: 'Active voice',
      choices: [
        'Both active and passive',
        'Neither active nor passive',
        'Passive voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The dog sent the sculpture."',
      correctAnswer: 'Active voice',
      choices: [
        'Passive voice',
        'Neither active nor passive',
        'Both active and passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The librarian fed the tent."',
      correctAnswer: 'Active voice',
      choices: [
        'Passive voice',
        'Neither active nor passive',
        'Both active and passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The nurse opened the fence."',
      correctAnswer: 'Active voice',
      choices: [
        'Both active and passive',
        'Passive voice',
        'Neither active nor passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The farmer delivered the picture."',
      correctAnswer: 'Active voice',
      choices: [
        'Both active and passive',
        'Neither active nor passive',
        'Passive voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The song was examined by the dancer."',
      correctAnswer: 'Passive voice',
      choices: [
        'Active voice',
        'Both active and passive',
        'Neither active nor passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The project was prepared by the painter."',
      correctAnswer: 'Passive voice',
      choices: [
        'Neither active nor passive',
        'Both active and passive',
        'Active voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The sweater was watched by the electrician."',
      correctAnswer: 'Passive voice',
      choices: [
        'Active voice',
        'Neither active nor passive',
        'Both active and passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The boat was broken by the teacher."',
      correctAnswer: 'Passive voice',
      choices: [
        'Neither active nor passive',
        'Both active and passive',
        'Active voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The machine was broken by the baker."',
      correctAnswer: 'Passive voice',
      choices: [
        'Both active and passive',
        'Active voice',
        'Neither active nor passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The flag was stolen by the engineer."',
      correctAnswer: 'Passive voice',
      choices: [
        'Active voice',
        'Neither active nor passive',
        'Both active and passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The ball was painted by the gardener."',
      correctAnswer: 'Passive voice',
      choices: [
        'Neither active nor passive',
        'Active voice',
        'Both active and passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The window was examined by the photographer."',
      correctAnswer: 'Passive voice',
      choices: [
        'Active voice',
        'Both active and passive',
        'Neither active nor passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The trophy was opened by the mechanic."',
      correctAnswer: 'Passive voice',
      choices: [
        'Both active and passive',
        'Neither active nor passive',
        'Active voice'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Identify the voice of the sentence.',
      prompt:
          'Is this sentence written in the active voice or the passive voice?\n"The sweater was taught by the painter."',
      correctAnswer: 'Passive voice',
      choices: [
        'Active voice',
        'Both active and passive',
        'Neither active nor passive'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about sweater is written in the active voice?',
      correctAnswer: 'The coach watched the sweater.',
      choices: [
        'The report was taken by the electrician.',
        'The invitation was stolen by the chef.',
        'The wall was read by the tailor.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about necklace is written in the active voice?',
      correctAnswer: 'The dancer wore the necklace.',
      choices: [
        'The report was explained by the mechanic.',
        'The costume was chased by the chef.',
        'The painting was sold by the plumber.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about trophy is written in the active voice?',
      correctAnswer: 'The dog locked the trophy.',
      choices: [
        'The banner was worn by the librarian.',
        'The email was completed by the singer.',
        'The fence was donated by the cat.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about sculpture is written in the active voice?',
      correctAnswer: 'The author collected the sculpture.',
      choices: [
        'The trophy was thrown by the nurse.',
        'The statue was opened by the librarian.',
        'The tent was signed by the girl.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about machine is written in the active voice?',
      correctAnswer: 'The electrician washed the machine.',
      choices: [
        'The email was published by the painter.',
        'The book was designed by the mechanic.',
        'The car was eaten by the waiter.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about sandwich is written in the active voice?',
      correctAnswer: 'The singer watched the sandwich.',
      choices: [
        'The cake was fed by the electrician.',
        'The robot was printed by the artist.',
        'The sweater was watched by the baker.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about recipe is written in the active voice?',
      correctAnswer: 'The girl recorded the recipe.',
      choices: [
        'The wall was recorded by the pilot.',
        'The roof was prepared by the author.',
        'The car was chased by the chef.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the active voice.',
      prompt: 'Which sentence about basket is written in the active voice?',
      correctAnswer: 'The author donated the basket.',
      choices: [
        'The basket was chased by the cat.',
        'The car was delivered by the teacher.',
        'The email was caught by the mechanic.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about flag is written in the passive voice?',
      correctAnswer: 'The flag was found by the plumber.',
      choices: [
        'The baker baked the trophy.',
        'The teacher opened the ball.',
        'The teacher sold the flag.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about wall is written in the passive voice?',
      correctAnswer: 'The wall was donated by the boy.',
      choices: [
        'The engineer collected the puzzle.',
        'The journalist fed the puzzle.',
        'The electrician caught the banner.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about window is written in the passive voice?',
      correctAnswer: 'The window was worn by the painter.',
      choices: [
        'The coach sent the trophy.',
        'The doctor fed the painting.',
        'The plumber brought the machine.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about robot is written in the passive voice?',
      correctAnswer: 'The robot was kept by the author.',
      choices: [
        'The dancer caught the basket.',
        'The gardener fixed the painting.',
        'The cat kicked the roof.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about email is written in the passive voice?',
      correctAnswer: 'The email was kicked by the mechanic.',
      choices: [
        'The scientist found the basket.',
        'The farmer kept the castle.',
        'The electrician brought the tent.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about cake is written in the passive voice?',
      correctAnswer: 'The cake was worn by the mechanic.',
      choices: [
        'The dog threw the house.',
        'The singer examined the cake.',
        'The electrician chased the email.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about roof is written in the passive voice?',
      correctAnswer: 'The roof was grown by the cat.',
      choices: [
        'The tailor chased the sweater.',
        'The girl broke the necklace.',
        'The artist read the necklace.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt:
          'Which sentence about invitation is written in the passive voice?',
      correctAnswer: 'The invitation was drawn by the nurse.',
      choices: [
        'The photographer finished the boat.',
        'The painter ate the necklace.',
        'The chef baked the wall.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The gardener completed the sandwich."',
      correctAnswer: 'The sandwich was completed by the gardener.',
      choices: [
        'The gardener was completed by the sandwich.',
        'The sandwich is completed by the gardener.',
        'The sandwich completed by the gardener.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The scientist organized the project."',
      correctAnswer: 'The project was organized by the scientist.',
      choices: [
        'The scientist was organized by the project.',
        'The project is organized by the scientist.',
        'The project organized by the scientist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The dog printed the bicycle."',
      correctAnswer: 'The bicycle was printed by the dog.',
      choices: [
        'The dog was printed by the bicycle.',
        'The bicycle is printed by the dog.',
        'The bicycle printed by the dog.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The dentist recorded the robot."',
      correctAnswer: 'The robot was recorded by the dentist.',
      choices: [
        'The dentist was recorded by the robot.',
        'The robot is recorded by the dentist.',
        'The robot recorded by the dentist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The gardener cleaned the flag."',
      correctAnswer: 'The flag was cleaned by the gardener.',
      choices: [
        'The gardener was cleaned by the flag.',
        'The flag is cleaned by the gardener.',
        'The flag cleaned by the gardener.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The plumber caught the car."',
      correctAnswer: 'The car was caught by the plumber.',
      choices: [
        'The plumber was caught by the car.',
        'The car is caught by the plumber.',
        'The car caught by the plumber.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The gardener baked the mural."',
      correctAnswer: 'The mural was baked by the gardener.',
      choices: [
        'The gardener was baked by the mural.',
        'The mural is baked by the gardener.',
        'The mural baked by the gardener.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The dog chose the bicycle."',
      correctAnswer: 'The bicycle was chosen by the dog.',
      choices: [
        'The dog was chosen by the bicycle.',
        'The bicycle is chosen by the dog.',
        'The bicycle chose by the dog.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The singer decorated the bicycle."',
      correctAnswer: 'The bicycle was decorated by the singer.',
      choices: [
        'The singer was decorated by the bicycle.',
        'The bicycle is decorated by the singer.',
        'The bicycle decorated by the singer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The girl brought the letter."',
      correctAnswer: 'The letter was brought by the girl.',
      choices: [
        'The girl was brought by the letter.',
        'The letter is brought by the girl.',
        'The letter brought by the girl.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The mechanic donated the bicycle."',
      correctAnswer: 'The bicycle was donated by the mechanic.',
      choices: [
        'The mechanic was donated by the bicycle.',
        'The bicycle is donated by the mechanic.',
        'The bicycle donated by the mechanic.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The plumber wrote the sculpture."',
      correctAnswer: 'The sculpture was written by the plumber.',
      choices: [
        'The plumber was written by the sculpture.',
        'The sculpture is written by the plumber.',
        'The sculpture wrote by the plumber.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The journalist kept the picture."',
      correctAnswer: 'The picture was kept by the journalist.',
      choices: [
        'The journalist was kept by the picture.',
        'The picture is kept by the journalist.',
        'The picture kept by the journalist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The electrician kicked the bicycle."',
      correctAnswer: 'The bicycle was kicked by the electrician.',
      choices: [
        'The electrician was kicked by the bicycle.',
        'The bicycle is kicked by the electrician.',
        'The bicycle kicked by the electrician.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The dentist grew the car."',
      correctAnswer: 'The car was grown by the dentist.',
      choices: [
        'The dentist was grown by the car.',
        'The car is grown by the dentist.',
        'The car grew by the dentist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The chef broke the banner."',
      correctAnswer: 'The banner was broken by the chef.',
      choices: [
        'The chef was broken by the banner.',
        'The banner is broken by the chef.',
        'The banner broke by the chef.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The journalist collected the painting."',
      correctAnswer: 'The painting was collected by the journalist.',
      choices: [
        'The journalist was collected by the painting.',
        'The painting is collected by the journalist.',
        'The painting collected by the journalist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The ball was finished by the waiter."',
      correctAnswer: 'The waiter finished the ball.',
      choices: [
        'The ball finished the waiter.',
        'The waiter finishes the ball.',
        'The waiter is finished by the ball.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The report was eaten by the gardener."',
      correctAnswer: 'The gardener ate the report.',
      choices: [
        'The report ate the gardener.',
        'The gardener eats the report.',
        'The gardener is eaten by the report.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The book was chosen by the chef."',
      correctAnswer: 'The chef chose the book.',
      choices: [
        'The book chose the chef.',
        'The chef chooses the book.',
        'The chef is chosen by the book.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The necklace was cleaned by the dancer."',
      correctAnswer: 'The dancer cleaned the necklace.',
      choices: [
        'The necklace cleaned the dancer.',
        'The dancer cleans the necklace.',
        'The dancer is cleaned by the necklace.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The tent was washed by the boy."',
      correctAnswer: 'The boy washed the tent.',
      choices: [
        'The tent washed the boy.',
        'The boy washes the tent.',
        'The boy is washed by the tent.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The window was carried by the librarian."',
      correctAnswer: 'The librarian carried the window.',
      choices: [
        'The window carried the librarian.',
        'The librarian carries the window.',
        'The librarian is carried by the window.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The cake was organized by the cat."',
      correctAnswer: 'The cat organized the cake.',
      choices: [
        'The cake organized the cat.',
        'The cat organizes the cake.',
        'The cat is organized by the cake.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The poem was kicked by the doctor."',
      correctAnswer: 'The doctor kicked the poem.',
      choices: [
        'The poem kicked the doctor.',
        'The doctor kicks the poem.',
        'The doctor is kicked by the poem.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The castle was discovered by the girl."',
      correctAnswer: 'The girl discovered the castle.',
      choices: [
        'The castle discovered the girl.',
        'The girl discovers the castle.',
        'The girl is discovered by the castle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The mural was printed by the dancer."',
      correctAnswer: 'The dancer printed the mural.',
      choices: [
        'The mural printed the dancer.',
        'The dancer prints the mural.',
        'The dancer is printed by the mural.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The boat was delivered by the nurse."',
      correctAnswer: 'The nurse delivered the boat.',
      choices: [
        'The boat delivered the nurse.',
        'The nurse delivers the boat.',
        'The nurse is delivered by the boat.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The flag was printed by the artist."',
      correctAnswer: 'The artist printed the flag.',
      choices: [
        'The flag printed the artist.',
        'The artist prints the flag.',
        'The artist is printed by the flag.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The boat was fed by the boy."',
      correctAnswer: 'The boy fed the boat.',
      choices: [
        'The boat fed the boy.',
        'The boy feeds the boat.',
        'The boy is fed by the boat.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The report was donated by the electrician."',
      correctAnswer: 'The electrician donated the report.',
      choices: [
        'The report donated the electrician.',
        'The electrician donates the report.',
        'The electrician is donated by the report.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The machine was washed by the journalist."',
      correctAnswer: 'The journalist washed the machine.',
      choices: [
        'The machine washed the journalist.',
        'The journalist washes the machine.',
        'The journalist is washed by the machine.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The machine was explained by the coach."',
      correctAnswer: 'The coach explained the machine.',
      choices: [
        'The machine explained the coach.',
        'The coach explains the machine.',
        'The coach is explained by the machine.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 1,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The robot was hidden by the electrician."',
      correctAnswer: 'The electrician hid the robot.',
      choices: [
        'The robot hid the electrician.',
        'The electrician hides the robot.',
        'The electrician is hidden by the robot.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The singer prepares the recipe.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The recipe',
      choices: ['The singer', 'The cake', 'Prepared'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The author organized the trophy.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The trophy',
      choices: ['The report', 'The author', 'Organized'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The waiter keeps the puzzle.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The puzzle',
      choices: ['Kept', 'The window', 'The waiter'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The gardener made the cake.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The cake',
      choices: ['The gardener', 'The ball', 'Made'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The pilot feeds the costume.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The costume',
      choices: ['The pilot', 'The ball', 'Fed'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The coach examined the letter.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The letter',
      choices: ['The house', 'The coach', 'Examined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The nurse decorates the kite.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The kite',
      choices: ['The nurse', 'Decorated', 'The banner'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The scientist hides the recipe.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The recipe',
      choices: ['The ball', 'Hid', 'The scientist'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The chef carries the cake.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The cake',
      choices: ['The chef', 'Carried', 'The book'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The electrician opens the project.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The project',
      choices: ['The electrician', 'The tent', 'Opened'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The author explained the necklace.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The necklace',
      choices: ['The author', 'Explained', 'The letter'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The scientist keeps the recipe.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The recipe',
      choices: ['The bridge', 'Kept', 'The scientist'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The cat opened the song.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The song',
      choices: ['The ball', 'Opened', 'The cat'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The journalist throws the costume.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The costume',
      choices: ['The journalist', 'Threw', 'The boat'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The dancer locks the puzzle.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The puzzle',
      choices: ['Locked', 'The book', 'The dancer'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The engineer broke the invitation.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The invitation',
      choices: ['The engineer', 'Broke', 'The poem'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The nurse washes the project.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The project',
      choices: ['The nurse', 'The roof', 'Washed'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Identify the word that becomes the subject in the passive voice sentence.',
      prompt:
          'In the sentence "The journalist builds the window.", which part will become the subject when the sentence is rewritten in the passive voice?',
      correctAnswer: 'The window',
      choices: ['The journalist', 'Built', 'The email'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The chef kicked the recipe."',
      correctAnswer: 'The recipe was kicked by the chef.',
      choices: [
        'The recipe is kicked by the chef.',
        'The recipe was kicked.',
        'The chef was kicked by the recipe.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The artist fed the painting."',
      correctAnswer: 'The painting was fed by the artist.',
      choices: [
        'The painting is fed by the artist.',
        'The painting was fed.',
        'The artist was fed by the painting.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The baker decorated the email."',
      correctAnswer: 'The email was decorated by the baker.',
      choices: [
        'The email is decorated by the baker.',
        'The email was decorated.',
        'The baker was decorated by the email.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The singer chased the mural."',
      correctAnswer: 'The mural was chased by the singer.',
      choices: [
        'The mural is chased by the singer.',
        'The mural was chased.',
        'The singer was chased by the mural.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The electrician stole the roof."',
      correctAnswer: 'The roof was stolen by the electrician.',
      choices: [
        'The roof is stolen by the electrician.',
        'The roof was stolen.',
        'The electrician was stolen by the roof.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The pilot makes the machine."',
      correctAnswer: 'The machine is made by the pilot.',
      choices: [
        'The machine was made by the pilot.',
        'The machine is made.',
        'The pilot is made by the machine.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The chef examines the book."',
      correctAnswer: 'The book is examined by the chef.',
      choices: [
        'The book was examined by the chef.',
        'The book is examined.',
        'The chef is examined by the book.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The nurse locked the puzzle."',
      correctAnswer: 'The puzzle was locked by the nurse.',
      choices: [
        'The puzzle is locked by the nurse.',
        'The puzzle was locked.',
        'The nurse was locked by the puzzle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The dancer sold the picture."',
      correctAnswer: 'The picture was sold by the dancer.',
      choices: [
        'The picture is sold by the dancer.',
        'The picture was sold.',
        'The dancer was sold by the picture.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The coach chased the poem."',
      correctAnswer: 'The poem was chased by the coach.',
      choices: [
        'The poem is chased by the coach.',
        'The poem was chased.',
        'The coach was chased by the poem.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The journalist keeps the email."',
      correctAnswer: 'The email is kept by the journalist.',
      choices: [
        'The email was kept by the journalist.',
        'The email is kept.',
        'The journalist is kept by the email.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The cat locks the book."',
      correctAnswer: 'The book is locked by the cat.',
      choices: [
        'The book was locked by the cat.',
        'The book is locked.',
        'The cat is locked by the book.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The teacher breaks the necklace."',
      correctAnswer: 'The necklace is broken by the teacher.',
      choices: [
        'The necklace was broken by the teacher.',
        'The necklace is broken.',
        'The teacher is broken by the necklace.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The dancer wrote the cake."',
      correctAnswer: 'The cake was written by the dancer.',
      choices: [
        'The cake is written by the dancer.',
        'The cake was written.',
        'The dancer was written by the cake.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The nurse printed the trophy."',
      correctAnswer: 'The trophy was printed by the nurse.',
      choices: [
        'The trophy is printed by the nurse.',
        'The trophy was printed.',
        'The nurse was printed by the trophy.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The dentist teaches the sandwich."',
      correctAnswer: 'The sandwich is taught by the dentist.',
      choices: [
        'The sandwich was taught by the dentist.',
        'The sandwich is taught.',
        'The dentist is taught by the sandwich.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The mechanic bakes the email."',
      correctAnswer: 'The email is baked by the mechanic.',
      choices: [
        'The email was baked by the mechanic.',
        'The email is baked.',
        'The mechanic is baked by the email.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the passive voice.',
      prompt:
          'Rewrite this sentence in the passive voice: "The gardener chases the project."',
      correctAnswer: 'The project is chased by the gardener.',
      choices: [
        'The project was chased by the gardener.',
        'The project is chased.',
        'The gardener is chased by the project.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The mural is baked by the plumber."',
      correctAnswer: 'The plumber bakes the mural.',
      choices: [
        'The plumber baked the mural.',
        'The mural bakes the plumber.',
        'The plumber bake the mural.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The garden is caught by the tailor."',
      correctAnswer: 'The tailor catches the garden.',
      choices: [
        'The tailor caught the garden.',
        'The garden catches the tailor.',
        'The tailor catch the garden.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The wall is broken by the nurse."',
      correctAnswer: 'The nurse breaks the wall.',
      choices: [
        'The nurse broke the wall.',
        'The wall breaks the nurse.',
        'The nurse break the wall.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The book was eaten by the dancer."',
      correctAnswer: 'The dancer ate the book.',
      choices: [
        'The dancer eats the book.',
        'The book ate the dancer.',
        'The dancer eaten the book.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The sandwich is donated by the dentist."',
      correctAnswer: 'The dentist donates the sandwich.',
      choices: [
        'The dentist donated the sandwich.',
        'The sandwich donates the dentist.',
        'The dentist donate the sandwich.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The garden is caught by the photographer."',
      correctAnswer: 'The photographer catches the garden.',
      choices: [
        'The photographer caught the garden.',
        'The garden catches the photographer.',
        'The photographer catch the garden.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The statue is sent by the scientist."',
      correctAnswer: 'The scientist sends the statue.',
      choices: [
        'The scientist sent the statue.',
        'The statue sends the scientist.',
        'The scientist send the statue.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The tent is written by the electrician."',
      correctAnswer: 'The electrician writes the tent.',
      choices: [
        'The electrician wrote the tent.',
        'The tent writes the electrician.',
        'The electrician write the tent.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The sculpture was eaten by the scientist."',
      correctAnswer: 'The scientist ate the sculpture.',
      choices: [
        'The scientist eats the sculpture.',
        'The sculpture ate the scientist.',
        'The scientist eaten the sculpture.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The roof is examined by the singer."',
      correctAnswer: 'The singer examines the roof.',
      choices: [
        'The singer examined the roof.',
        'The roof examines the singer.',
        'The singer examine the roof.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The wall is delivered by the electrician."',
      correctAnswer: 'The electrician delivers the wall.',
      choices: [
        'The electrician delivered the wall.',
        'The wall delivers the electrician.',
        'The electrician deliver the wall.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The painting is grown by the dentist."',
      correctAnswer: 'The dentist grows the painting.',
      choices: [
        'The dentist grew the painting.',
        'The painting grows the dentist.',
        'The dentist grow the painting.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The wall was stolen by the dancer."',
      correctAnswer: 'The dancer stole the wall.',
      choices: [
        'The dancer steals the wall.',
        'The wall stole the dancer.',
        'The dancer stolen the wall.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The roof was stolen by the tailor."',
      correctAnswer: 'The tailor stole the roof.',
      choices: [
        'The tailor steals the roof.',
        'The roof stole the tailor.',
        'The tailor stolen the roof.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The song is baked by the plumber."',
      correctAnswer: 'The plumber bakes the song.',
      choices: [
        'The plumber baked the song.',
        'The song bakes the plumber.',
        'The plumber bake the song.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The boat is eaten by the baker."',
      correctAnswer: 'The baker eats the boat.',
      choices: [
        'The baker ate the boat.',
        'The boat eats the baker.',
        'The baker eat the boat.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The banner is donated by the engineer."',
      correctAnswer: 'The engineer donates the banner.',
      choices: [
        'The engineer donated the banner.',
        'The banner donates the engineer.',
        'The engineer donate the banner.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Rewrite the sentence in the active voice.',
      prompt:
          'Rewrite this sentence in the active voice: "The song is fixed by the painter."',
      correctAnswer: 'The painter fixes the song.',
      choices: [
        'The painter fixed the song.',
        'The song fixes the painter.',
        'The painter fix the song.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The book ___ by the dog. (Use the correct passive form of "sign".)',
      correctAnswer: 'is signed',
      choices: ['signed', 'was sign', 'is signing'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The boat ___ by the author. (Use the correct passive form of "prepare".)',
      correctAnswer: 'is prepared',
      choices: ['prepared', 'was prepare', 'is preparing'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The puzzle ___ by the mechanic. (Use the correct passive form of "deliver".)',
      correctAnswer: 'was delivered',
      choices: ['delivered', 'was deliver', 'is delivering'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The banner ___ by the cat. (Use the correct passive form of "publish".)',
      correctAnswer: 'is published',
      choices: ['published', 'was publish', 'is publishing'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The email ___ by the manager. (Use the correct passive form of "break".)',
      correctAnswer: 'is broken',
      choices: ['broke', 'was break', 'is breaking'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The machine ___ by the waiter. (Use the correct passive form of "prepare".)',
      correctAnswer: 'was prepared',
      choices: ['prepared', 'was prepare', 'is preparing'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The necklace ___ by the nurse. (Use the correct passive form of "send".)',
      correctAnswer: 'is sent',
      choices: ['sent', 'was send', 'is sending'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The banner ___ by the dancer. (Use the correct passive form of "feed".)',
      correctAnswer: 'was fed',
      choices: ['fed', 'was feed', 'is feeding'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The garden ___ by the pilot. (Use the correct passive form of "wear".)',
      correctAnswer: 'is worn',
      choices: ['wore', 'was wear', 'is wearing'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The letter ___ by the girl. (Use the correct passive form of "sell".)',
      correctAnswer: 'is sold',
      choices: ['sold', 'was sell', 'is selling'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The email ___ by the girl. (Use the correct passive form of "donate".)',
      correctAnswer: 'was donated',
      choices: ['donated', 'was donate', 'is donating'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The sandwich ___ by the teacher. (Use the correct passive form of "eat".)',
      correctAnswer: 'is eaten',
      choices: ['ate', 'was eat', 'is eating'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The robot ___ by the chef. (Use the correct passive form of "watch".)',
      correctAnswer: 'is watched',
      choices: ['watched', 'was watch', 'is watching'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The sweater ___ by the dancer. (Use the correct passive form of "teach".)',
      correctAnswer: 'is taught',
      choices: ['taught', 'was teach', 'is teaching'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The letter ___ by the tailor. (Use the correct passive form of "clean".)',
      correctAnswer: 'is cleaned',
      choices: ['cleaned', 'was clean', 'is cleaning'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 2,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct verb form to complete the sentence.',
      prompt:
          'The letter ___ by the mechanic. (Use the correct passive form of "explain".)',
      correctAnswer: 'was explained',
      choices: ['explained', 'was explain', 'is explaining'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The photographer has grown the basket."',
      correctAnswer: 'The basket has been grown by the photographer.',
      choices: [
        'The basket has grown been by the photographer.',
        'The basket was grown by the photographer.',
        'The basket has grown by the photographer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The chef has fixed the sandwich."',
      correctAnswer: 'The sandwich has been fixed by the chef.',
      choices: [
        'The sandwich has fixed been by the chef.',
        'The sandwich was fixed by the chef.',
        'The sandwich has fixed by the chef.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The tailor has cleaned the window."',
      correctAnswer: 'The window has been cleaned by the tailor.',
      choices: [
        'The window has cleaned been by the tailor.',
        'The window was cleaned by the tailor.',
        'The window has cleaned by the tailor.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The teacher has cleaned the roof."',
      correctAnswer: 'The roof has been cleaned by the teacher.',
      choices: [
        'The roof has cleaned been by the teacher.',
        'The roof was cleaned by the teacher.',
        'The roof has cleaned by the teacher.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The electrician has collected the machine."',
      correctAnswer: 'The machine has been collected by the electrician.',
      choices: [
        'The machine has collected been by the electrician.',
        'The machine was collected by the electrician.',
        'The machine has collected by the electrician.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The dog has examined the roof."',
      correctAnswer: 'The roof has been examined by the dog.',
      choices: [
        'The roof has examined been by the dog.',
        'The roof was examined by the dog.',
        'The roof has examined by the dog.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The plumber has printed the book."',
      correctAnswer: 'The book has been printed by the plumber.',
      choices: [
        'The book has printed been by the plumber.',
        'The book was printed by the plumber.',
        'The book has printed by the plumber.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The librarian has watched the cake."',
      correctAnswer: 'The cake has been watched by the librarian.',
      choices: [
        'The cake has watched been by the librarian.',
        'The cake was watched by the librarian.',
        'The cake has watched by the librarian.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The girl has made the castle."',
      correctAnswer: 'The castle has been made by the girl.',
      choices: [
        'The castle has made been by the girl.',
        'The castle was made by the girl.',
        'The castle has made by the girl.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The journalist has cleaned the necklace."',
      correctAnswer: 'The necklace has been cleaned by the journalist.',
      choices: [
        'The necklace has cleaned been by the journalist.',
        'The necklace was cleaned by the journalist.',
        'The necklace has cleaned by the journalist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The farmer has painted the costume."',
      correctAnswer: 'The costume has been painted by the farmer.',
      choices: [
        'The costume has painted been by the farmer.',
        'The costume was painted by the farmer.',
        'The costume has painted by the farmer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The farmer has painted the report."',
      correctAnswer: 'The report has been painted by the farmer.',
      choices: [
        'The report has painted been by the farmer.',
        'The report was painted by the farmer.',
        'The report has painted by the farmer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The tailor has organized the statue."',
      correctAnswer: 'The statue has been organized by the tailor.',
      choices: [
        'The statue has organized been by the tailor.',
        'The statue was organized by the tailor.',
        'The statue has organized by the tailor.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The tailor has taught the robot."',
      correctAnswer: 'The robot has been taught by the tailor.',
      choices: [
        'The robot has taught been by the tailor.',
        'The robot was taught by the tailor.',
        'The robot has taught by the tailor.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The girl has washed the fence."',
      correctAnswer: 'The fence has been washed by the girl.',
      choices: [
        'The fence has washed been by the girl.',
        'The fence was washed by the girl.',
        'The fence has washed by the girl.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the passive voice version of the sentence.',
      prompt:
          'Choose the passive voice version of: "The pilot has stolen the trophy."',
      correctAnswer: 'The trophy has been stolen by the pilot.',
      choices: [
        'The trophy has stolen been by the pilot.',
        'The trophy was stolen by the pilot.',
        'The trophy has stolen by the pilot.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The report had been grown by the dog."',
      correctAnswer: 'The dog had grown the report.',
      choices: [
        'The dog has grown the report.',
        'The dog had grew the report.',
        'The dog had been grown the report.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The puzzle had been grown by the manager."',
      correctAnswer: 'The manager had grown the puzzle.',
      choices: [
        'The manager has grown the puzzle.',
        'The manager had grew the puzzle.',
        'The manager had been grown the puzzle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The puzzle had been taken by the singer."',
      correctAnswer: 'The singer had taken the puzzle.',
      choices: [
        'The singer has taken the puzzle.',
        'The singer had took the puzzle.',
        'The singer had been taken the puzzle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The mural had been worn by the manager."',
      correctAnswer: 'The manager had worn the mural.',
      choices: [
        'The manager has worn the mural.',
        'The manager had wore the mural.',
        'The manager had been worn the mural.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The window had been written by the dancer."',
      correctAnswer: 'The dancer had written the window.',
      choices: [
        'The dancer has written the window.',
        'The dancer had wrote the window.',
        'The dancer had been written the window.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The banner had been written by the waiter."',
      correctAnswer: 'The waiter had written the banner.',
      choices: [
        'The waiter has written the banner.',
        'The waiter had wrote the banner.',
        'The waiter had been written the banner.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The bicycle had been taken by the artist."',
      correctAnswer: 'The artist had taken the bicycle.',
      choices: [
        'The artist has taken the bicycle.',
        'The artist had took the bicycle.',
        'The artist had been taken the bicycle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The email had been eaten by the chef."',
      correctAnswer: 'The chef had eaten the email.',
      choices: [
        'The chef has eaten the email.',
        'The chef had ate the email.',
        'The chef had been eaten the email.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The poem had been drawn by the cat."',
      correctAnswer: 'The cat had drawn the poem.',
      choices: [
        'The cat has drawn the poem.',
        'The cat had drew the poem.',
        'The cat had been drawn the poem.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The basket had been taken by the mechanic."',
      correctAnswer: 'The mechanic had taken the basket.',
      choices: [
        'The mechanic has taken the basket.',
        'The mechanic had took the basket.',
        'The mechanic had been taken the basket.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The song had been written by the coach."',
      correctAnswer: 'The coach had written the song.',
      choices: [
        'The coach has written the song.',
        'The coach had wrote the song.',
        'The coach had been written the song.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The necklace had been thrown by the doctor."',
      correctAnswer: 'The doctor had thrown the necklace.',
      choices: [
        'The doctor has thrown the necklace.',
        'The doctor had threw the necklace.',
        'The doctor had been thrown the necklace.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The cake had been hidden by the plumber."',
      correctAnswer: 'The plumber had hidden the cake.',
      choices: [
        'The plumber has hidden the cake.',
        'The plumber had hid the cake.',
        'The plumber had been hidden the cake.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The robot had been eaten by the librarian."',
      correctAnswer: 'The librarian had eaten the robot.',
      choices: [
        'The librarian has eaten the robot.',
        'The librarian had ate the robot.',
        'The librarian had been eaten the robot.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the active voice version of the sentence.',
      prompt:
          'Choose the active voice version of: "The car had been worn by the baker."',
      correctAnswer: 'The baker had worn the car.',
      choices: [
        'The baker has worn the car.',
        'The baker had wore the car.',
        'The baker had been worn the car.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the librarian draw the poem?"',
      correctAnswer: 'Was The poem drawn by the librarian?',
      choices: [
        'Did The poem drawn by the librarian?',
        'Was The poem drew by the librarian?',
        'Was The librarian drawn by the poem?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the electrician break the garden?"',
      correctAnswer: 'Was The garden broken by the electrician?',
      choices: [
        'Did The garden broken by the electrician?',
        'Was The garden broke by the electrician?',
        'Was The electrician broken by the garden?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the girl wear the bridge?"',
      correctAnswer: 'Was The bridge worn by the girl?',
      choices: [
        'Did The bridge worn by the girl?',
        'Was The bridge wore by the girl?',
        'Was The girl worn by the bridge?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the baker draw the sandwich?"',
      correctAnswer: 'Was The sandwich drawn by the baker?',
      choices: [
        'Did The sandwich drawn by the baker?',
        'Was The sandwich drew by the baker?',
        'Was The baker drawn by the sandwich?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the manager grow the roof?"',
      correctAnswer: 'Was The roof grown by the manager?',
      choices: [
        'Did The roof grown by the manager?',
        'Was The roof grew by the manager?',
        'Was The manager grown by the roof?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the doctor write the boat?"',
      correctAnswer: 'Was The boat written by the doctor?',
      choices: [
        'Did The boat written by the doctor?',
        'Was The boat wrote by the doctor?',
        'Was The doctor written by the boat?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the cat break the bridge?"',
      correctAnswer: 'Was The bridge broken by the cat?',
      choices: [
        'Did The bridge broken by the cat?',
        'Was The bridge broke by the cat?',
        'Was The cat broken by the bridge?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the plumber write the cake?"',
      correctAnswer: 'Was The cake written by the plumber?',
      choices: [
        'Did The cake written by the plumber?',
        'Was The cake wrote by the plumber?',
        'Was The plumber written by the cake?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the singer steal the invitation?"',
      correctAnswer: 'Was The invitation stolen by the singer?',
      choices: [
        'Did The invitation stolen by the singer?',
        'Was The invitation stole by the singer?',
        'Was The singer stolen by the invitation?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the gardener hide the painting?"',
      correctAnswer: 'Was The painting hidden by the gardener?',
      choices: [
        'Did The painting hidden by the gardener?',
        'Was The painting hid by the gardener?',
        'Was The gardener hidden by the painting?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the tailor take the picture?"',
      correctAnswer: 'Was The picture taken by the tailor?',
      choices: [
        'Did The picture taken by the tailor?',
        'Was The picture took by the tailor?',
        'Was The tailor taken by the picture?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the chef wear the robot?"',
      correctAnswer: 'Was The robot worn by the chef?',
      choices: [
        'Did The robot worn by the chef?',
        'Was The robot wore by the chef?',
        'Was The chef worn by the robot?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the cat choose the car?"',
      correctAnswer: 'Was The car chosen by the cat?',
      choices: [
        'Did The car chosen by the cat?',
        'Was The car chose by the cat?',
        'Was The cat chosen by the car?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the girl grow the bicycle?"',
      correctAnswer: 'Was The bicycle grown by the girl?',
      choices: [
        'Did The bicycle grown by the girl?',
        'Was The bicycle grew by the girl?',
        'Was The girl grown by the bicycle?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the tailor hide the report?"',
      correctAnswer: 'Was The report hidden by the tailor?',
      choices: [
        'Did The report hidden by the tailor?',
        'Was The report hid by the tailor?',
        'Was The tailor hidden by the report?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice question.',
      prompt:
          'Which is the correct passive voice question for: "Did the electrician grow the banner?"',
      correctAnswer: 'Was The banner grown by the electrician?',
      choices: [
        'Did The banner grown by the electrician?',
        'Was The banner grew by the electrician?',
        'Was The electrician grown by the banner?'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The singer did not wear the costume."',
      correctAnswer: 'The costume was not worn by the singer.',
      choices: [
        'The costume did not worn by the singer.',
        'The costume was not wore by the singer.',
        'The costume not was worn by the singer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The engineer did not grow the statue."',
      correctAnswer: 'The statue was not grown by the engineer.',
      choices: [
        'The statue did not grown by the engineer.',
        'The statue was not grew by the engineer.',
        'The statue not was grown by the engineer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The coach did not eat the flag."',
      correctAnswer: 'The flag was not eaten by the coach.',
      choices: [
        'The flag did not eaten by the coach.',
        'The flag was not ate by the coach.',
        'The flag not was eaten by the coach.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The dentist did not wear the tent."',
      correctAnswer: 'The tent was not worn by the dentist.',
      choices: [
        'The tent did not worn by the dentist.',
        'The tent was not wore by the dentist.',
        'The tent not was worn by the dentist.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The dog did not steal the sculpture."',
      correctAnswer: 'The sculpture was not stolen by the dog.',
      choices: [
        'The sculpture did not stolen by the dog.',
        'The sculpture was not stole by the dog.',
        'The sculpture not was stolen by the dog.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The dog did not draw the mural."',
      correctAnswer: 'The mural was not drawn by the dog.',
      choices: [
        'The mural did not drawn by the dog.',
        'The mural was not drew by the dog.',
        'The mural not was drawn by the dog.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The tailor did not choose the castle."',
      correctAnswer: 'The castle was not chosen by the tailor.',
      choices: [
        'The castle did not chosen by the tailor.',
        'The castle was not chose by the tailor.',
        'The castle not was chosen by the tailor.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The librarian did not steal the castle."',
      correctAnswer: 'The castle was not stolen by the librarian.',
      choices: [
        'The castle did not stolen by the librarian.',
        'The castle was not stole by the librarian.',
        'The castle not was stolen by the librarian.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The nurse did not hide the robot."',
      correctAnswer: 'The robot was not hidden by the nurse.',
      choices: [
        'The robot did not hidden by the nurse.',
        'The robot was not hid by the nurse.',
        'The robot not was hidden by the nurse.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The photographer did not throw the painting."',
      correctAnswer: 'The painting was not thrown by the photographer.',
      choices: [
        'The painting did not thrown by the photographer.',
        'The painting was not threw by the photographer.',
        'The painting not was thrown by the photographer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The tailor did not grow the picture."',
      correctAnswer: 'The picture was not grown by the tailor.',
      choices: [
        'The picture did not grown by the tailor.',
        'The picture was not grew by the tailor.',
        'The picture not was grown by the tailor.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The teacher did not throw the invitation."',
      correctAnswer: 'The invitation was not thrown by the teacher.',
      choices: [
        'The invitation did not thrown by the teacher.',
        'The invitation was not threw by the teacher.',
        'The invitation not was thrown by the teacher.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The baker did not take the cake."',
      correctAnswer: 'The cake was not taken by the baker.',
      choices: [
        'The cake did not taken by the baker.',
        'The cake was not took by the baker.',
        'The cake not was taken by the baker.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The singer did not eat the tent."',
      correctAnswer: 'The tent was not eaten by the singer.',
      choices: [
        'The tent did not eaten by the singer.',
        'The tent was not ate by the singer.',
        'The tent not was eaten by the singer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The dancer did not eat the car."',
      correctAnswer: 'The car was not eaten by the dancer.',
      choices: [
        'The car did not eaten by the dancer.',
        'The car was not ate by the dancer.',
        'The car not was eaten by the dancer.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice sentence.',
      prompt:
          'Which is the correct passive voice sentence for: "The author did not grow the trophy."',
      correctAnswer: 'The trophy was not grown by the author.',
      choices: [
        'The trophy did not grown by the author.',
        'The trophy was not grew by the author.',
        'The trophy not was grown by the author.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The dog should teach the tent."',
      correctAnswer: 'The tent should be taught by the dog.',
      choices: [
        'The tent should taught by the dog.',
        'The tent should been taught by the dog.',
        'The dog should be taught by the tent.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The engineer should choose the roof."',
      correctAnswer: 'The roof should be chosen by the engineer.',
      choices: [
        'The roof should chosen by the engineer.',
        'The roof should been chosen by the engineer.',
        'The engineer should be chosen by the roof.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The teacher should donate the banner."',
      correctAnswer: 'The banner should be donated by the teacher.',
      choices: [
        'The banner should donated by the teacher.',
        'The banner should been donated by the teacher.',
        'The teacher should be donated by the banner.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The painter should draw the castle."',
      correctAnswer: 'The castle should be drawn by the painter.',
      choices: [
        'The castle should drawn by the painter.',
        'The castle should been drawn by the painter.',
        'The painter should be drawn by the castle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The doctor should sell the bridge."',
      correctAnswer: 'The bridge should be sold by the doctor.',
      choices: [
        'The bridge should sold by the doctor.',
        'The bridge should been sold by the doctor.',
        'The doctor should be sold by the bridge.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The cat should sign the window."',
      correctAnswer: 'The window should be signed by the cat.',
      choices: [
        'The window should signed by the cat.',
        'The window should been signed by the cat.',
        'The cat should be signed by the window.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The doctor should chase the book."',
      correctAnswer: 'The book should be chased by the doctor.',
      choices: [
        'The book should chased by the doctor.',
        'The book should been chased by the doctor.',
        'The doctor should be chased by the book.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The doctor should design the mural."',
      correctAnswer: 'The mural should be designed by the doctor.',
      choices: [
        'The mural should designed by the doctor.',
        'The mural should been designed by the doctor.',
        'The doctor should be designed by the mural.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The nurse must have broken the puzzle."',
      correctAnswer: 'The puzzle must have been broken by the nurse.',
      choices: [
        'The puzzle must be broken by the nurse.',
        'The puzzle must have broken by the nurse.',
        'The nurse must have been broken by the puzzle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The teacher must have chosen the boat."',
      correctAnswer: 'The boat must have been chosen by the teacher.',
      choices: [
        'The boat must be chosen by the teacher.',
        'The boat must have chosen by the teacher.',
        'The teacher must have been chosen by the boat.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The journalist must have grown the garden."',
      correctAnswer: 'The garden must have been grown by the journalist.',
      choices: [
        'The garden must be grown by the journalist.',
        'The garden must have grown by the journalist.',
        'The journalist must have been grown by the garden.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The chef must have broken the letter."',
      correctAnswer: 'The letter must have been broken by the chef.',
      choices: [
        'The letter must be broken by the chef.',
        'The letter must have broken by the chef.',
        'The chef must have been broken by the letter.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The tailor must have taken the cake."',
      correctAnswer: 'The cake must have been taken by the tailor.',
      choices: [
        'The cake must be taken by the tailor.',
        'The cake must have taken by the tailor.',
        'The tailor must have been taken by the cake.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The scientist must have thrown the invitation."',
      correctAnswer: 'The invitation must have been thrown by the scientist.',
      choices: [
        'The invitation must be thrown by the scientist.',
        'The invitation must have thrown by the scientist.',
        'The scientist must have been thrown by the invitation.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The scientist must have drawn the window."',
      correctAnswer: 'The window must have been drawn by the scientist.',
      choices: [
        'The window must be drawn by the scientist.',
        'The window must have drawn by the scientist.',
        'The scientist must have been drawn by the window.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the correct passive voice version of the sentence.',
      prompt:
          'Choose the correct passive voice version of: "The photographer must have written the roof."',
      correctAnswer: 'The roof must have been written by the photographer.',
      choices: [
        'The roof must be written by the photographer.',
        'The roof must have written by the photographer.',
        'The photographer must have been written by the roof.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about boat is written in the passive voice?',
      correctAnswer: 'The boat was caught.',
      choices: [
        'The librarian delivered the invitation.',
        'The tailor was famous.',
        'The manager reads the cake.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about house is written in the passive voice?',
      correctAnswer: 'The house was baked.',
      choices: [
        'The engineer explained the project.',
        'The manager was nervous.',
        'The doctor fixes the robot.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about garden is written in the passive voice?',
      correctAnswer: 'The garden was built.',
      choices: [
        'The electrician threw the invitation.',
        'The gardener was sad.',
        'The journalist tells the email.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about letter is written in the passive voice?',
      correctAnswer: 'The letter was told.',
      choices: [
        'The doctor wrote the garden.',
        'The chef was tired.',
        'The plumber delivers the painting.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about fence is written in the passive voice?',
      correctAnswer: 'The fence was washed.',
      choices: [
        'The tailor opened the roof.',
        'The journalist was sick.',
        'The scientist brings the ball.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about bridge is written in the passive voice?',
      correctAnswer: 'The bridge was broken.',
      choices: [
        'The girl made the bicycle.',
        'The mechanic was patient.',
        'The baker records the roof.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about banner is written in the passive voice?',
      correctAnswer: 'The banner was delivered.',
      choices: [
        'The doctor published the book.',
        'The gardener was careful.',
        'The cat sells the ball.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about book is written in the passive voice?',
      correctAnswer: 'The book was fixed.',
      choices: [
        'The mechanic finished the car.',
        'The artist was shy.',
        'The farmer keeps the mural.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about bicycle is written in the passive voice?',
      correctAnswer: 'The bicycle was kicked.',
      choices: [
        'The chef examined the basket.',
        'The mechanic was tall.',
        'The engineer bakes the invitation.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about kite is written in the passive voice?',
      correctAnswer: 'The kite was built.',
      choices: [
        'The painter found the bridge.',
        'The coach was proud.',
        'The farmer hides the project.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about mural is written in the passive voice?',
      correctAnswer: 'The mural was brought.',
      choices: [
        'The dancer discovered the cake.',
        'The scientist was excited.',
        'The chef finishes the machine.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about castle is written in the passive voice?',
      correctAnswer: 'The castle was hidden.',
      choices: [
        'The artist broke the project.',
        'The tailor was popular.',
        'The singer organizes the bicycle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about car is written in the passive voice?',
      correctAnswer: 'The car was printed.',
      choices: [
        'The dentist prepared the invitation.',
        'The engineer was hungry.',
        'The manager locks the costume.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about song is written in the passive voice?',
      correctAnswer: 'The song was chosen.',
      choices: [
        'The singer decorated the banner.',
        'The baker was tired.',
        'The singer decorates the wall.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about report is written in the passive voice?',
      correctAnswer: 'The report was broken.',
      choices: [
        'The tailor threw the roof.',
        'The dentist was tall.',
        'The dancer wears the castle.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction: 'Choose the sentence written in the passive voice.',
      prompt: 'Which sentence about statue is written in the passive voice?',
      correctAnswer: 'The statue was designed.',
      choices: [
        'The engineer printed the tent.',
        'The farmer was bored.',
        'The dancer designs the cake.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The costume was sold by the boy."',
      correctAnswer: 'Passive voice',
      choices: [
        'Not passive voice (just an adjective)',
        'Active voice',
        'Cannot be determined'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The basket was stolen by the farmer."',
      correctAnswer: 'Passive voice',
      choices: [
        'Not passive voice (just an adjective)',
        'Active voice',
        'Cannot be determined'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The gardener was tired."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The boat was organized by the boy."',
      correctAnswer: 'Passive voice',
      choices: [
        'Not passive voice (just an adjective)',
        'Active voice',
        'Cannot be determined'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The engineer was curious."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The singer was short."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The manager was generous."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The plumber was famous."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The email was told by the scientist."',
      correctAnswer: 'Passive voice',
      choices: [
        'Not passive voice (just an adjective)',
        'Active voice',
        'Cannot be determined'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The cake was chased by the cat."',
      correctAnswer: 'Passive voice',
      choices: [
        'Not passive voice (just an adjective)',
        'Active voice',
        'Cannot be determined'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The dentist was kind."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The dog was brave."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The boy was popular."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The girl was famous."',
      correctAnswer: 'Not passive voice (just an adjective)',
      choices: ['Passive voice', 'Active voice', 'Cannot be determined'],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The painting was locked."',
      correctAnswer: 'Passive voice',
      choices: [
        'Not passive voice (just an adjective)',
        'Active voice',
        'Cannot be determined'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Decide whether the sentence is passive voice or just an adjective.',
      prompt:
          'Is this sentence an example of the passive voice, or does it simply use \'was\' with an adjective (not passive)?\n"The garden was thrown."',
      correctAnswer: 'Passive voice',
      choices: [
        'Not passive voice (just an adjective)',
        'Active voice',
        'Cannot be determined'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "The crew took the kite."',
      correctAnswer: 'The kite was taken.',
      choices: [
        'The kite was taken by the crew.',
        'The kite took.',
        'The kite is taken.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "Officials brought the machine."',
      correctAnswer: 'The machine was brought.',
      choices: [
        'The machine was brought by officials.',
        'The machine brought.',
        'The machine is brought.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "People finished the picture."',
      correctAnswer: 'The picture was finished.',
      choices: [
        'The picture was finished by people.',
        'The picture finished.',
        'The picture is finished.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "Volunteers broke the tent."',
      correctAnswer: 'The tent was broken.',
      choices: [
        'The tent was broken by volunteers.',
        'The tent broke.',
        'The tent is broken.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "The government published the cake."',
      correctAnswer: 'The cake was published.',
      choices: [
        'The cake was published by the government.',
        'The cake published.',
        'The cake is published.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "Volunteers donated the ball."',
      correctAnswer: 'The ball was donated.',
      choices: [
        'The ball was donated by volunteers.',
        'The ball donated.',
        'The ball is donated.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "The company prepared the costume."',
      correctAnswer: 'The costume was prepared.',
      choices: [
        'The costume was prepared by the company.',
        'The costume prepared.',
        'The costume is prepared.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "The crew stole the house."',
      correctAnswer: 'The house was stolen.',
      choices: [
        'The house was stolen by the crew.',
        'The house stole.',
        'The house is stolen.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "The staff grew the invitation."',
      correctAnswer: 'The invitation was grown.',
      choices: [
        'The invitation was grown by the staff.',
        'The invitation grew.',
        'The invitation is grown.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "Someone taught the tent."',
      correctAnswer: 'The tent was taught.',
      choices: [
        'The tent was taught by someone.',
        'The tent taught.',
        'The tent is taught.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "People ate the machine."',
      correctAnswer: 'The machine was eaten.',
      choices: [
        'The machine was eaten by people.',
        'The machine ate.',
        'The machine is eaten.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Active and Passive Voice',
      instruction:
          'Rewrite the sentence in the passive voice without naming the doer.',
      prompt:
          'Rewrite this sentence in the passive voice. Leave out the doer of the action since it is not important: "People brought the roof."',
      correctAnswer: 'The roof was brought.',
      choices: [
        'The roof was brought by people.',
        'The roof brought.',
        'The roof is brought.'
      ],
    ),
  ),
  // --- Reported Speech (17) ---
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: "Tom said, 'I am tired.'",
      correctAnswer: 'Tom said he was tired.',
      choices: [
        'Tom said I am tired.',
        'Tom says he is tired.',
        'Tom said tired he was.',
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: "Mia said, 'I like cats.'",
      correctAnswer: 'Mia said she liked cats.',
      choices: [
        'Mia said I like cats.',
        'Mia says she like cats.',
        'Mia said cats she liked.',
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'Ana said, \'I am happy.\'',
      correctAnswer: 'Ana said that she was happy.',
      choices: [
        'Ana said that she is happy.',
        'Ana said that I was happy.',
        'Ana said she is happy today.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'Tom said, \'I like ice cream.\'',
      correctAnswer: 'Tom said that he liked ice cream.',
      choices: [
        'Tom said that he likes ice cream.',
        'Tom said that I liked ice cream.',
        'Tom said he like ice cream.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'She said, \'I am tired.\'',
      correctAnswer: 'She said that she was tired.',
      choices: [
        'She said that she is tired.',
        'She said that I was tired.',
        'She said she be tired.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'He said, \'I have a red bike.\'',
      correctAnswer: 'He said that he had a red bike.',
      choices: [
        'He said that he has a red bike.',
        'He said that I had a red bike.',
        'He said he have a red bike.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'They said, \'We are playing outside.\'',
      correctAnswer: 'They said that they were playing outside.',
      choices: [
        'They said that they are playing outside.',
        'They said that we were playing outside.',
        'They said they play outside.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'Mia said, \'I want a puppy.\'',
      correctAnswer: 'Mia said that she wanted a puppy.',
      choices: [
        'Mia said that she wants a puppy.',
        'Mia said that I wanted a puppy.',
        'Mia said she want a puppy.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'The boy said, \'I can swim fast.\'',
      correctAnswer: 'The boy said that he could swim fast.',
      choices: [
        'The boy said that he can swim fast.',
        'The boy said that I could swim fast.',
        'The boy said he could swims fast.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 3,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'My friend said, \'I am reading a book.\'',
      correctAnswer: 'My friend said that she was reading a book.',
      choices: [
        'My friend said that she is reading a book.',
        'My friend said that I was reading a book.',
        'My friend said she read a book.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'Dad said, \'I will call you tomorrow.\'',
      correctAnswer: 'Dad said that he would call me the next day.',
      choices: [
        'Dad said that he will call me tomorrow.',
        'Dad said that he would call you tomorrow.',
        'Dad said he will call me the next day.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'The teacher said, \'You must finish your homework today.\'',
      correctAnswer:
          'The teacher said that we had to finish our homework that day.',
      choices: [
        'The teacher said that we must finish our homework today.',
        'The teacher said we had to finish our homework today.',
        'The teacher said that we must finished our homework that day.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'Lily said, \'I saw a movie yesterday.\'',
      correctAnswer: 'Lily said that she had seen a movie the day before.',
      choices: [
        'Lily said that she saw a movie yesterday.',
        'Lily said that she had seen a movie yesterday.',
        'Lily said she has seen a movie the day before.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'He asked, \'Are you coming to the party?\'',
      correctAnswer: 'He asked if I was coming to the party.',
      choices: [
        'He asked if I am coming to the party.',
        'He asked that I was coming to the party.',
        'He asked are you coming to the party.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'She said, \'I will finish this here.\'',
      correctAnswer: 'She said that she would finish that there.',
      choices: [
        'She said that she will finish this here.',
        'She said that she would finish this here.',
        'She said she would finished that there.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'The coach said, \'Practice starts at six tomorrow.\'',
      correctAnswer:
          'The coach said that practice started at six the next day.',
      choices: [
        'The coach said that practice starts at six tomorrow.',
        'The coach said practice started at six tomorrow.',
        'The coach said that practice start at six the next day.'
      ],
    ),
  ),
  _LeveledQuestion(
    minLevel: 4,
    question: SubjectQuizQuestion(
      topic: 'Reported Speech',
      instruction: 'Choose the correct reported speech.',
      prompt: 'Ben said, \'I don\'t have my keys.\'',
      correctAnswer: 'Ben said that he didn\'t have his keys.',
      choices: [
        'Ben said that he doesn\'t have his keys.',
        'Ben said that I didn\'t have my keys.',
        'Ben said he not have his keys.'
      ],
    ),
  ),
];
