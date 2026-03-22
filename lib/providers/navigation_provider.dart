import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationProvider extends ChangeNotifier {
  String _selectedNavItem = AppConstants.navToday;
  String? _selectedListId;
  String? _selectedTaskId;
  bool _isSearchOpen = false;
  String _searchQuery = '';
  bool _isDetailPanelOpen = false;
  bool _isQuickAddOpen = false;

  final Set<String> _selectedTaskIds = {};
  bool _isSelectionMode = false;

  bool _isPlanningMode = false;
  final List<String> _mitTaskIds = [];
  String? _lastPlanningDate;
  Timer? _searchDebounce;

  // Today view filters
  bool _filterMITs = false;
  bool _filterHighPriority = false;
  bool _filterOverdue = false;

  // Phase 3 — filter bar state
  Priority? _filterPriority;
  String? _filterListId;
  String? _filterDateRange; // 'today' | 'week' | 'overdue' | null

  String get selectedNavItem => _selectedNavItem;
  String? get selectedListId => _selectedListId;
  String? get selectedTaskId => _selectedTaskId;
  bool get isSearchOpen => _isSearchOpen;
  String get searchQuery => _searchQuery;
  bool get isDetailPanelOpen => _isDetailPanelOpen;
  bool get isDetailOpen => _isDetailPanelOpen;
  bool get isQuickAddOpen => _isQuickAddOpen;

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedTaskIds => Set.unmodifiable(_selectedTaskIds);
  int get selectedCount => _selectedTaskIds.length;
  bool isTaskSelected(String id) => _selectedTaskIds.contains(id);

  bool get isPlanningMode => _isPlanningMode;
  List<String> get mitTaskIds => List.unmodifiable(_mitTaskIds);
  bool isMIT(String taskId) => _mitTaskIds.contains(taskId);

  bool get filterMITs => _filterMITs;
  bool get filterHighPriority => _filterHighPriority;
  bool get filterOverdue => _filterOverdue;

  Priority? get filterPriority => _filterPriority;
  String? get filterListId => _filterListId;
  String? get filterDateRange => _filterDateRange;

  void toggleFilterMITs() {
    _filterMITs = !_filterMITs;
    notifyListeners();
  }

  void toggleFilterHighPriority() {
    _filterHighPriority = !_filterHighPriority;
    notifyListeners();
  }

  void toggleFilterOverdue() {
    _filterOverdue = !_filterOverdue;
    notifyListeners();
  }

  void clearFilters() {
    _filterMITs = false;
    _filterHighPriority = false;
    _filterOverdue = false;
    _filterPriority = null;
    _filterListId = null;
    _filterDateRange = null;
    notifyListeners();
  }

  void setFilterPriority(Priority? p) {
    _filterPriority = p;
    notifyListeners();
  }

  void setFilterListId(String? id) {
    _filterListId = id;
    notifyListeners();
  }

  void setFilterDateRange(String? range) {
    _filterDateRange = range;
    notifyListeners();
  }

  void selectNav(String item) {
    _selectedNavItem = item;
    _selectedListId = null;
    _selectedTaskId = null;
    _isDetailPanelOpen = false;
    _isSelectionMode = false;
    _selectedTaskIds.clear();

    // Force list view for sections that don't benefit from other layouts
    if (item == 'trash' || item == 'completed') {
      _sectionLayouts[item] = TaskViewLayout.list;
    }

    notifyListeners();
  }

  void selectList(String listId) {
    _selectedNavItem = 'list_$listId';
    _selectedListId = listId;
    _selectedTaskId = null;
    _isDetailPanelOpen = false;
    clearSelection();
    notifyListeners();
  }

  void selectTask(String? taskId) {
    _selectedTaskId = taskId;
    _isDetailPanelOpen = taskId != null;
    notifyListeners();
  }

  void toggleSearch() {
    _isSearchOpen = !_isSearchOpen;
    if (!_isSearchOpen) _searchQuery = '';
    notifyListeners();
  }

  void openSearch() {
    _isSearchOpen = true;
    notifyListeners();
  }

  void closeSearch() {
    _isSearchOpen = false;
    _searchQuery = '';
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      notifyListeners();
    });
  }

  void closeDetailPanel() {
    _selectedTaskId = null;
    _isDetailPanelOpen = false;
    notifyListeners();
  }

  void closeDetail() {
    _selectedTaskId = null;
    _isDetailPanelOpen = false;
    notifyListeners();
  }

  void openQuickAdd() {
    _isQuickAddOpen = true;
    notifyListeners();
  }

  void closeQuickAdd() {
    _isQuickAddOpen = false;
    notifyListeners();
  }

  void enterSelectionMode(String firstId) {
    _isSelectionMode = true;
    _selectedTaskIds.add(firstId);
    notifyListeners();
  }

  void toggleTaskSelection(String id) {
    if (_selectedTaskIds.contains(id)) {
      _selectedTaskIds.remove(id);
      if (_selectedTaskIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedTaskIds.add(id);
    }
    notifyListeners();
  }

  void selectAllTasks(List<String> ids) {
    _selectedTaskIds.addAll(ids);
    notifyListeners();
  }

  void clearSelection() {
    _selectedTaskIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  void enterPlanningMode() {
    _isPlanningMode = true;
    notifyListeners();
  }

  void exitPlanningMode() {
    _isPlanningMode = false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _lastPlanningDate = today;
    _savePlanningDate(today);
    notifyListeners();
  }

  void toggleMIT(String taskId) {
    if (_mitTaskIds.contains(taskId)) {
      _mitTaskIds.remove(taskId);
    } else if (_mitTaskIds.length < 5) {
      _mitTaskIds.add(taskId);
    }
    notifyListeners();
  }

  void clearMITs() {
    _mitTaskIds.clear();
    notifyListeners();
  }

  bool get shouldShowPlanningPrompt {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return _lastPlanningDate != today && DateTime.now().hour < 14;
    // Only prompt before 2PM
  }

  Future<void> _saveSections() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _sectionLayouts.map((k, v) => MapEntry(k, v.index));
    await prefs.setString('section_layouts', jsonEncode(data));
  }

  Future<void> _loadSections() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('section_layouts');
    if (json != null) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      data.forEach((k, v) {
        _sectionLayouts[k] = TaskViewLayout.values[v as int];
      });
    }
  }

  Future<void> _savePlanningDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_planning_date', date);
  }

  Future<void> loadPlanningState() async {
    final prefs = await SharedPreferences.getInstance();
    _lastPlanningDate = prefs.getString('last_planning_date');
    await _loadSections();
    notifyListeners();
  }

  String get pageTitle {
    switch (_selectedNavItem) {
      case AppConstants.navToday:
        return 'Today';
      case AppConstants.navUpcoming:
        return 'Upcoming';
      case AppConstants.navAll:
        return 'All Tasks';
      case AppConstants.navCompleted:
        return 'Completed';
      case AppConstants.navTrash:
        return 'Trash';
      case AppConstants.navHighPriority:
        return 'High Priority';
      case AppConstants.navScheduled:
        return 'Scheduled';
      case AppConstants.navFlagged:
        return 'Flagged';
      case AppConstants.navCalendar:
        return 'Calendar';
      case AppConstants.navInsights:
        return 'Insights';
      case AppConstants.navSettings:
        return 'Settings';
      case AppConstants.navStore:
        return 'Sticker Store';
      default:
        return _selectedNavItem;
    }
  }

  // Per-section layout memory
  // Key: navItem string (e.g. 'today', 'upcoming', 'list_<id>')
  // Value: the layout chosen for that section
  final Map<String, TaskViewLayout> _sectionLayouts = {};

  // Returns the layout for the current nav section.
  // Falls back to TaskViewLayout.list if section has no saved layout.
  TaskViewLayout layoutForCurrentSection(TaskViewLayout globalDefault) {
    return _sectionLayouts[_selectedNavItem] ?? globalDefault;
  }

  void setLayoutForCurrentSection(TaskViewLayout layout) {
    _sectionLayouts[_selectedNavItem] = layout;
    _saveSections();
    notifyListeners();
  }

  NavigationProvider() {
    loadPlanningState();
  }
}
