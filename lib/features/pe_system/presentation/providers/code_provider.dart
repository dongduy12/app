import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/code_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/search_list_entity.dart';
import '../../domain/usecases/manage_codes_usecase.dart';

class CodeProvider with ChangeNotifier {
  final ManageCodesUseCase useCase;

  List<SearchListEntity> _searchLists = [];
  List<CodeEntity> _codeList = [];
  List<String> _foundCodes = [];
  List<String> _orderedFoundCodes = [];
  List<String> _recentlyScannedCodes = [];
  bool _isLoading = false;
  String? _error;

  UserEntity? _user;
  bool _isLoggingIn = false;
  String? _loginError;

  int _selectedIndex = 0;
  int? _selectedSearchListIndex;

  List<SearchListEntity> get searchLists => _searchLists;
  List<CodeEntity> get codeList => _codeList;
  List<String> get foundCodes => _foundCodes;
  List<String> get recentlyScannedCodes => _recentlyScannedCodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserEntity? get user => _user;
  bool get isLoggingIn => _isLoggingIn;
  String? get loginError => _loginError;

  int get selectedIndex => _selectedIndex;
  int? get selectedSearchListIndex => _selectedSearchListIndex;

  int get foundCount => _foundCodes.length;
  int get totalCount => _codeList.length;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  CodeProvider({required this.useCase}) {
    // Không gọi _loadLoginStatus() ngay trong constructor
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _loadLoginStatus();
      _isInitialized = true;
    }
  }

  Future<void> _loadLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _isLoggingIn = true;
      _loginError = null;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));
      if (email == 'test@example.com' && password == 'password') {
        _user = UserEntity.fromJson({'id': 1, 'email': email});
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await fetchSearchList();
        _isLoggingIn = false;
        notifyListeners();
        return true;
      } else {
        _loginError = 'Email hoặc mật khẩu không đúng';
        _isLoggingIn = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loginError = 'Lỗi đăng nhập: $e';
      _isLoggingIn = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _selectedIndex = 0;
    _searchLists = [];
    _codeList = [];
    _foundCodes = [];
    _orderedFoundCodes = [];
    _recentlyScannedCodes = [];
    _selectedSearchListIndex = null;
    _isLoggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    notifyListeners();
  }

  Future<void> fetchSearchList() async {
    if (_searchLists.isNotEmpty) {
      print('Search lists already loaded: $_searchLists');
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _searchLists = await useCase.getSearchList();
      print('Fetched _searchLists: $_searchLists');
      _selectedSearchListIndex = null;
      _recentlyScannedCodes = [];
      print('Set _selectedSearchListIndex: $_selectedSearchListIndex');
      _updateCodeList();
    } catch (e) {
      _error = e.toString();
      print('Fetch error: $_error');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateScannedStatus(int searchListId, String serialNumber, bool isScanned) async {
    try {
      if (_foundCodes.contains(serialNumber)) {
        print('SerialNumber $serialNumber already found, updating position');
        _orderedFoundCodes.remove(serialNumber);
        _recentlyScannedCodes.remove(serialNumber);
        _orderedFoundCodes.insert(0, serialNumber);
        _recentlyScannedCodes.insert(0, serialNumber);

        final existingCode = _codeList.firstWhere(
              (item) => item.serialNumber == serialNumber,
          orElse: () => CodeEntity(
            id: '',
            serialNumber: serialNumber,
            modelName: '',
            shelfCode: '',
            isFound: true,
          ),
        );
        _codeList = [
          existingCode.copyWith(isFound: true, foundOrder: 1),
          ..._codeList
              .where((item) => item.serialNumber != serialNumber)
              .map((item) => item.isFound && _orderedFoundCodes.contains(item.serialNumber)
              ? item.copyWith(foundOrder: _orderedFoundCodes.indexOf(item.serialNumber) + 1)
              : item),
        ];
        notifyListeners();
        return;
      }
      final success = await useCase.updateScannedStatus(searchListId, serialNumber, isScanned);
      if (success) {
        _foundCodes.add(serialNumber);
        _orderedFoundCodes.insert(0, serialNumber);
        _recentlyScannedCodes.insert(0, serialNumber);
        final existingCode = _codeList.firstWhere(
              (item) => item.serialNumber == serialNumber,
          orElse: () => CodeEntity(
            id: '',
            serialNumber: serialNumber,
            modelName: '',
            shelfCode: '',
            isFound: true,
          ),
        );
        _codeList = [
          existingCode.copyWith(isFound: true, foundOrder: 1),
          ..._codeList
              .where((item) => item.serialNumber != serialNumber)
              .map((item) => item.isFound && _orderedFoundCodes.contains(item.serialNumber)
              ? item.copyWith(foundOrder: _orderedFoundCodes.indexOf(item.serialNumber) + 1)
              : item),
        ];
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      print('UpdateScannedStatus error: $_error');
      notifyListeners();
    }
  }

  Future<bool> handleScanCode(String code, int? searchListId) async {
    if (searchListId == null) {
      _error = 'Vui lòng chọn một danh sách trước khi quét!';
      notifyListeners();
      return false;
    }
    code = code.trim();
    await updateScannedStatus(searchListId, code, true);
    return foundCodes.contains(code);
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void setSelectedSearchListIndex(int index) {
    _selectedSearchListIndex = index;
    _recentlyScannedCodes = [];
    print('Selected search list index: $index');
    _updateCodeList();
  }

  void _updateCodeList() {
    if (_selectedSearchListIndex != null && _searchLists.isNotEmpty) {
      _codeList = _searchLists[_selectedSearchListIndex!].items;
      _foundCodes = _codeList
          .where((item) => item.isFound)
          .map((item) => item.serialNumber)
          .toList();
      print('Updated _codeList: $_codeList');
      print('Updated _foundCodes: $_foundCodes');

      _orderedFoundCodes = _foundCodes.toList();
      _codeList = _codeList.map((item) {
        if (_orderedFoundCodes.contains(item.serialNumber)) {
          return item.copyWith(foundOrder: _orderedFoundCodes.indexOf(item.serialNumber) + 1);
        }
        return item;
      }).toList();
    } else {
      _codeList = [];
      _foundCodes = [];
      _orderedFoundCodes = [];
      _recentlyScannedCodes = [];
      print('Cleared _codeList: $_codeList');
    }
    notifyListeners();
  }
}