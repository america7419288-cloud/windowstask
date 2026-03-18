import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../utils/constants.dart';

class NavigationProvider extends ChangeNotifier {
  String _selectedNavItem = AppConstants.navToday;
  String? _selectedListId;
  String? _selectedTaskId;
  bool _isSearchOpen = false;
  String _searchQuery = '';
  bool _isDetailPanelOpen = false;
  bool _isQuickAddOpen = false;

  String get selectedNavItem => _selectedNavItem;
  String? get selectedListId => _selectedListId;
  String? get selectedTaskId => _selectedTaskId;
  bool get isSearchOpen => _isSearchOpen;
  String get searchQuery => _searchQuery;
  bool get isDetailPanelOpen => _isDetailPanelOpen;
  bool get isQuickAddOpen => _isQuickAddOpen;

  void selectNav(String item) {
    _selectedNavItem = item;
    _selectedListId = null;
    _selectedTaskId = null;
    _isDetailPanelOpen = false;

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
    notifyListeners();
  }

  void closeDetailPanel() {
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
      case AppConstants.navInsights:
        return 'Insights';
      case AppConstants.navSettings:
        return 'Settings';
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
    notifyListeners();
  }
}
