import 'dart:math';

enum SubjectLessonSubject { english, science }

class SubjectLessonQuestion {
  final String prompt;
  final List<String> options;
  final String answer;
  final String topic;
  final String explanation;

  const SubjectLessonQuestion({
    required this.prompt,
    required this.options,
    required this.answer,
    required this.topic,
    required this.explanation,
  });

  SubjectLessonQuestion withShuffledOptions() {
    final shuffled = [...options]..shuffle(Random());
    if (!shuffled.contains(answer)) {
      shuffled[0] = answer;
    }
    return SubjectLessonQuestion(
      prompt: prompt,
      options: shuffled,
      answer: answer,
      topic: topic,
      explanation: explanation,
    );
  }
}

class SubjectLessonBank {
  static const List<SubjectLessonQuestion> _englishQuestions = [
    SubjectLessonQuestion(
      prompt: 'Which word is a noun?',
      options: ['run', 'happy', 'cat', 'quickly'],
      answer: 'cat',
      topic: 'Grammar',
      explanation: 'A noun names a person, place, thing, or idea. Cat is a thing.',
    ),
    SubjectLessonQuestion(
      prompt: 'Choose the correct verb: The dog ___ fast.',
      options: ['run', 'runs', 'running', 'runned'],
      answer: 'runs',
      topic: 'Grammar',
      explanation: 'With he, she, or it, we often add -s to the base verb.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which sentence uses correct punctuation?',
      options: ['I like apples.', 'I like apples', 'I like apples!?', 'I like apples..'],
      answer: 'I like apples.',
      topic: 'Grammar',
      explanation: 'A complete sentence ends with a period when it is a statement.',
    ),
    SubjectLessonQuestion(
      prompt: 'What is the simple past form of walk?',
      options: ['walked', 'walking', 'walks', 'walken'],
      answer: 'walked',
      topic: 'Grammar',
      explanation: 'The simple past tense often adds -ed to a base verb.',
    ),
    SubjectLessonQuestion(
      prompt: 'What is the simple future form of play?',
      options: ['played', 'play', 'will play', 'playing'],
      answer: 'will play',
      topic: 'Grammar',
      explanation: 'We use will + the base verb for simple future.',
    ),
    SubjectLessonQuestion(
      prompt: 'What is the main idea of this story? Mia found a red bird in the garden and fed it.',
      options: ['A bird lived in the garden.', 'Mia likes to sing.', 'The garden is cold.', 'The bird was green.'],
      answer: 'A bird lived in the garden.',
      topic: 'Reading',
      explanation: 'The main idea tells us the big point of the story.',
    ),
    SubjectLessonQuestion(
      prompt: 'Choose the detail that fits the story about a rainy day.',
      options: ['The children wore boots.', 'The sky was blue.', 'The flowers were blooming.', 'The sun was hot.'],
      answer: 'The children wore boots.',
      topic: 'Reading',
      explanation: 'A detail is a small piece of information that supports the story.',
    ),
    SubjectLessonQuestion(
      prompt: 'Choose the synonym of big.',
      options: ['huge', 'tiny', 'slow', 'sad'],
      answer: 'huge',
      topic: 'Vocabulary',
      explanation: 'A synonym means a word with a similar meaning.',
    ),
    SubjectLessonQuestion(
      prompt: 'Choose the antonym of happy.',
      options: ['sad', 'bright', 'friendly', 'quick'],
      answer: 'sad',
      topic: 'Vocabulary',
      explanation: 'An antonym is a word with the opposite meaning.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which word is a homophone for blue?',
      options: ['blew', 'glue', 'shoe', 'tree'],
      answer: 'blew',
      topic: 'Vocabulary',
      explanation: 'Homophones sound the same but have different spellings and meanings.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which word begins with the sh sound?',
      options: ['ship', 'cat', 'dog', 'sun'],
      answer: 'ship',
      topic: 'Phonics',
      explanation: 'Ship begins with the /sh/ sound.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which word has the long a sound?',
      options: ['cake', 'dog', 'hat', 'pig'],
      answer: 'cake',
      topic: 'Phonics',
      explanation: 'Cake uses the long a sound in the middle.',
    ),
  ];

  static const List<SubjectLessonQuestion> _scienceQuestions = [
    SubjectLessonQuestion(
      prompt: 'Which is a living thing?',
      options: ['tree', 'rock', 'chair', 'river'],
      answer: 'tree',
      topic: 'Living Things',
      explanation: 'Living things grow, breathe, and need food and water.',
    ),
    SubjectLessonQuestion(
      prompt: 'Plants need sunlight to make food.',
      options: ['True', 'False', 'Maybe', 'Never'],
      answer: 'True',
      topic: 'Plants',
      explanation: 'Plants use sunlight to make their own food.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which animal can fly?',
      options: ['fish', 'bird', 'frog', 'cow'],
      answer: 'bird',
      topic: 'Animals',
      explanation: 'Birds have wings that help them fly.',
    ),
    SubjectLessonQuestion(
      prompt: 'What do we wear when it is cold?',
      options: ['coat', 'swimsuit', 'flip-flops', 'shorts'],
      answer: 'coat',
      topic: 'Weather',
      explanation: 'A coat helps keep us warm on cold days.',
    ),
    SubjectLessonQuestion(
      prompt: 'The Earth goes around the ___.',
      options: ['Moon', 'Sun', 'Stars', 'Clouds'],
      answer: 'Sun',
      topic: 'Space',
      explanation: 'The Earth orbits the Sun.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which is a solid?',
      options: ['ice', 'water', 'steam', 'rain'],
      answer: 'ice',
      topic: 'Matter',
      explanation: 'Ice is a solid because it keeps its own shape.',
    ),
    SubjectLessonQuestion(
      prompt: 'What do humans use to breathe?',
      options: ['lungs', 'teeth', 'hair', 'skin'],
      answer: 'lungs',
      topic: 'Human Body',
      explanation: 'The lungs help us breathe air.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which object gives us light and heat?',
      options: ['the Sun', 'a rock', 'a shoe', 'a pencil'],
      answer: 'the Sun',
      topic: 'Energy',
      explanation: 'The Sun provides light and heat for Earth.',
    ),
    SubjectLessonQuestion(
      prompt: 'What happens when water freezes?',
      options: ['It becomes ice.', 'It becomes steam.', 'It disappears.', 'It turns into sand.'],
      answer: 'It becomes ice.',
      topic: 'Matter',
      explanation: 'Freezing turns liquid water into a solid called ice.',
    ),
    SubjectLessonQuestion(
      prompt: 'Which tool helps us measure temperature?',
      options: ['thermometer', 'ruler', 'scale', 'compass'],
      answer: 'thermometer',
      topic: 'Weather',
      explanation: 'A thermometer measures how hot or cold something is.',
    ),
  ];

  static List<SubjectLessonQuestion> questionsFor(
    SubjectLessonSubject subject, {
    int count = 8,
    Set<String>? topics,
  }) {
    final pool = _filteredQuestions(subject, topics: topics);
    if (pool.isEmpty) return const [];

    final shuffledPool = [...pool]..shuffle(Random());
    final selected = <SubjectLessonQuestion>[];
    final usedTopics = <String>{};
    final questionsByTopic = <String, List<SubjectLessonQuestion>>{};

    for (final question in shuffledPool) {
      final normalizedTopic = _normalizeTopic(question.topic);
      questionsByTopic.putIfAbsent(normalizedTopic, () => <SubjectLessonQuestion>[])
          .add(question);
    }

    final orderedTopics = questionsByTopic.keys.toList()..shuffle(Random());
    for (final topic in orderedTopics) {
      if (selected.length >= count) break;
      if (usedTopics.contains(topic)) continue;
      final topicQuestions = questionsByTopic[topic]!;
      if (topicQuestions.isNotEmpty) {
        selected.add(topicQuestions.first.withShuffledOptions());
        usedTopics.add(topic);
      }
    }

    for (final question in shuffledPool) {
      if (selected.length >= count) break;
      final normalizedTopic = _normalizeTopic(question.topic);
      if (usedTopics.contains(normalizedTopic)) {
        final alreadySelected = selected.any((candidate) =>
            _normalizeTopic(candidate.topic) == normalizedTopic &&
            candidate.prompt == question.prompt);
        if (!alreadySelected) {
          selected.add(question.withShuffledOptions());
        }
      } else {
        selected.add(question.withShuffledOptions());
      }
    }

    return selected;
  }

  static SubjectLessonQuestion randomQuestion({
    required SubjectLessonSubject subject,
    required Random random,
    Set<String>? topics,
  }) {
    final pool = _filteredQuestions(subject, topics: topics);
    if (pool.isEmpty) {
      throw StateError('No lesson questions available for $subject');
    }
    return pool[random.nextInt(pool.length)].withShuffledOptions();
  }

  static List<SubjectLessonQuestion> _filteredQuestions(
    SubjectLessonSubject subject, {
    Set<String>? topics,
  }) {
    final pool = subject == SubjectLessonSubject.science
        ? _scienceQuestions
        : _englishQuestions;
    if (topics == null || topics.isEmpty) {
      return pool;
    }

    final normalizedTopics = topics.map(_normalizeTopic).toSet();
    final filtered = pool
        .where((question) => normalizedTopics.contains(_normalizeTopic(question.topic)))
        .toList(growable: false);
    return filtered.isEmpty ? pool : filtered;
  }

  static String _normalizeTopic(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
