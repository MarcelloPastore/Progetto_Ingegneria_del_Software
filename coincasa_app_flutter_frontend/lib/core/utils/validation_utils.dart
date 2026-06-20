class ValidationUtils {
  ValidationUtils._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static bool isValidEmail(String email) {
    return _emailRegExp.hasMatch(email.trim());
  }

  static bool isValidPassword(String password) {
    return password.length >= 10;
  }

  static bool isValidUsername(String username) {
    return username.length >= 3 && username.length <= 50;
  }

  static bool isValidName(String name) {
    return name.isNotEmpty && name.length <= 100;
  }
}
