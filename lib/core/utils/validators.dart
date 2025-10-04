import '../constants/strings.dart';

String? requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.fieldRequired;
  }
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return AppStrings.fieldRequired;
  }
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(value.trim())) {
    return AppStrings.invalidEmail;
  }
  return null;
}

String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return AppStrings.fieldRequired;
  }
  return null;
}

String? confirmPasswordValidator(String? value, String password) {
  if (value == null || value.isEmpty) {
    return AppStrings.fieldRequired;
  }
  if (value != password) {
    return AppStrings.passwordsDoNotMatch;
  }
  return null;
}
