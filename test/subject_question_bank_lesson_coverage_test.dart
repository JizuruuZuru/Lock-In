import 'package:flutter_test/flutter_test.dart';
import 'package:benchmark/data/subject_question_bank.dart';

void main() {
  final englishLessons = <String, Set<String>>{
    'Nouns and Pronouns': {
      'Nouns',
      'Plural Nouns',
      'Possessive Nouns',
      'Pronouns'
    },
    'Verbs and Tenses': {
      'Verbs',
      'Simple Present Tense',
      'Simple Past Tense',
      'Simple Future Tense'
    },
    'Adjectives and Adverbs': {
      'Adjectives',
      'Comparative Adjectives',
      'Adverbs'
    },
    'Determiners and Prepositions': {'Determiners', 'Prepositions'},
    'Conjunctions and Interjections': {'Conjunctions', 'Interjections'},
    'Sentence Structure': {'Sentence Structure', 'Compound Sentences'},
    'Subject-Verb Agreement': {
      'Subject-Verb Agreement',
      'Direct and Indirect Objects'
    },
    'Punctuation and Capitalization': {
      'Capitalization',
      'Punctuation',
      'Commas'
    },
    'Questions and Speech': {
      'Questions',
      'Tag Questions',
      'Active and Passive Voice',
      'Reported Speech',
    },
    'Comprehension': {
      'Comprehension',
      'Main Idea',
      'Details',
      'Sequencing',
      'Cause and Effect',
      'Fact and Opinion',
      'Inference',
      'Context Clues',
    },
    'Word Study': {
      'Word Study',
      'Synonyms',
      'Antonyms',
      'Homophones',
      'Compound Words',
      'Contractions',
    },
    'Phonics': {'Phonics', 'Spelling', 'Letter Sounds'},
  };

  final scienceLessons = <String, Set<String>>{
    'Investigating and Classifying': {
      'Scientific Method',
      'Classifying Living and Nonliving',
      'Observation Tools',
    },
    'Life Science and Plants': {
      'Plant Parts',
      'Plant Needs',
      'Plant Life Cycles',
      'Pollination',
    },
    'Humans and Animals': {
      'Animal Classification',
      'Animal Life Cycles',
      'Habitats',
      'Adaptations',
      'Five Senses',
      'Skeletal System',
      'Organ Systems',
      'Health',
    },
    'Materials and Chemistry': {
      'States of Matter',
      'Material Properties',
      'Mixtures'
    },
    'Physics and Forces': {
      'Forces',
      'Motion',
      'Simple Machines',
      'Magnets',
      'Friction',
      'Energy',
      'Light',
      'Sound',
      'Heat',
      'Electricity',
      'Circuits',
    },
    'Earth and Space': {
      'Solar System',
      'Sun',
      'Moon',
      'Planets',
      'Rocks and Soil',
      'Minerals',
      'Landforms',
      'Weather',
      'Climate',
      'Water Cycle',
      'Seasons',
    },
  };

  group('every English lesson has at least 60 questions', () {
    englishLessons.forEach((name, topics) {
      test(name, () {
        final count = SubjectQuestionBank.questionCountFor(
          SubjectQuizType.english,
          topics: topics,
        );
        expect(count, greaterThanOrEqualTo(60),
            reason: '$name only has $count questions');
      });
    });
  });

  group('every individual Science topic has at least 60 questions', () {
    final allScienceTopics = scienceLessons.values.expand((topics) => topics);
    for (final topic in allScienceTopics) {
      test(topic, () {
        final count = SubjectQuestionBank.questionCountFor(
          SubjectQuizType.science,
          topics: {topic},
        );
        expect(count, greaterThanOrEqualTo(60),
            reason: '$topic only has $count questions');
      });
    }
  });

  group('every Science lesson has at least 60 questions', () {
    scienceLessons.forEach((name, topics) {
      test(name, () {
        final count = SubjectQuestionBank.questionCountFor(
          SubjectQuizType.science,
          topics: topics,
        );
        expect(count, greaterThanOrEqualTo(60),
            reason: '$name only has $count questions');
      });
    });
  });
}
