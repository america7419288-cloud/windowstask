import '../models/task.dart';
import 'package:fuzzy/fuzzy.dart';

class SearchService {
  static List<Task> search(List<Task> tasks, String query, {
    String? listFilter,
    Priority? priorityFilter,
    String? tagFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    List<Task> results = tasks.where((t) => !t.isDeleted).toList();

    // Apply filters
    if (listFilter != null) {
      results = results.where((t) => t.listId == listFilter).toList();
    }
    if (priorityFilter != null) {
      results = results.where((t) => t.priority == priorityFilter).toList();
    }
    if (tagFilter != null) {
      results = results.where((t) => t.tags.contains(tagFilter)).toList();
    }
    if (dateFrom != null) {
      results = results.where((t) => t.dueDate != null && !t.dueDate!.isBefore(dateFrom)).toList();
    }
    if (dateTo != null) {
      results = results.where((t) => t.dueDate != null && !t.dueDate!.isAfter(dateTo)).toList();
    }

    if (query.trim().isEmpty) return results;

    // Fuzzy search on title + description + tags
    final fuzzy = Fuzzy<Task>(
      results,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'title',
            getter: (t) => t.title,
            weight: 3,
          ),
          WeightedKey(
            name: 'description',
            getter: (t) => t.description,
            weight: 1,
          ),
          WeightedKey(
            name: 'tags',
            getter: (t) => t.tags.join(' '),
            weight: 2,
          ),
        ],
        threshold: 0.4,
        shouldSort: true,
      ),
    );

    return fuzzy.search(query).map((r) => r.item).toList();
  }
}
