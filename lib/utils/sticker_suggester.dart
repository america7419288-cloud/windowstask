/// Automatically suggests a sticker ID based on keywords in a task title.
///
/// Returns the sticker ID of the best-matching category, or `null` if
/// no keyword matches. Categories are checked in priority order so that
/// more specific matches (e.g. "physics") win over generic ones.
class StickerSuggester {
  StickerSuggester._(); // non-instantiable

  /// Maps a task [title] to a sticker ID from [StickerRegistry].
  /// Returns `null` when no keyword matches.
  static String? suggest(String title) {
    final words = title.toLowerCase().split(RegExp(r'\s+'));
    for (final entry in _rules) {
      for (final word in words) {
        if (entry.keywords.contains(word)) return entry.stickerId;
      }
    }
    return null;
  }

  // ─── Keyword → Sticker rules (checked in order) ───────────────────────────

  static const _rules = <_Rule>[
    // Study / Academic
    _Rule({
      'physics', 'maths', 'math', 'chemistry', 'biology', 'science',
      'study', 'exam', 'test', 'homework', 'assignment', 'lecture',
      'class', 'school', 'college', 'university', 'revision', 'notes',
      'essay', 'research', 'thesis', 'quiz',
    }, 'bear_productive'),

    // Work / Professional
    _Rule({
      'work', 'meeting', 'office', 'email', 'report', 'presentation',
      'deadline', 'project', 'client', 'interview', 'resume',
    }, 'bear_work'),

    // Fitness / Health
    _Rule({
      'gym', 'run', 'workout', 'exercise', 'jog', 'yoga', 'swim',
      'sport', 'walk', 'stretch', 'pushup', 'plank', 'diet',
      'health', 'fitness',
    }, 'misc_funny'),

    // Self Care
    _Rule({
      'meditate', 'journal', 'sleep', 'relax', 'skincare', 'therapy',
      'rest', 'nap', 'bath',
    }, 'bear_care'),

    // Shopping / Errands
    _Rule({
      'buy', 'shop', 'grocery', 'market', 'order', 'pickup',
      'deliver', 'pay', 'bill',
    }, 'bear_greed'),

    // Social
    _Rule({
      'call', 'meet', 'party', 'birthday', 'dinner', 'lunch',
      'date', 'hangout', 'friend', 'family', 'visit',
    }, 'bear_happy'),

    // Creative
    _Rule({
      'draw', 'paint', 'design', 'write', 'music', 'sing', 'play',
      'dance', 'create', 'craft', 'photo', 'video', 'edit',
    }, 'peach_dance'),

    // Cleaning / Home
    _Rule({
      'clean', 'wash', 'laundry', 'cook', 'organize', 'tidy',
      'declutter', 'vacuum', 'dishes', 'iron',
    }, 'bear_bath'),

    // Reading
    _Rule({
      'read', 'book', 'novel', 'article', 'chapter', 'library',
      'magazine',
    }, 'bear_basic'),

    // Travel
    _Rule({
      'travel', 'trip', 'flight', 'hotel', 'pack', 'ticket',
      'passport', 'drive', 'commute',
    }, 'duck_enjoy'),
  ];
}

class _Rule {
  final Set<String> keywords;
  final String stickerId;
  const _Rule(this.keywords, this.stickerId);
}
