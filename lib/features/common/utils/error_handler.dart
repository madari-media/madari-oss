import 'package:pocketbase/pocketbase.dart';

String getErrorMessage(ClientException e) {
  switch (e.statusCode) {
    case 400:
      final data = e.response['data'];

      if (data?['email'] != null) {
        switch (data['email']['code']) {
          case 'validation_invalid_email':
            return 'Please enter a valid email address';
          case 'validation_not_unique':
            return 'This email is already registered';
          default:
            return 'Invalid email';
        }
      }

      if (data?['password'] != null) {
        switch (data['password']['code']) {
          case 'validation_length_out_of_range':
            return 'Password must be at least 6 characters long';
          case 'validation_too_weak':
            return 'Password is too weak. Please include numbers and special characters';
          default:
            return 'Invalid password';
        }
      }

      if (data?['passwordConfirm'] != null) {
        switch (data['passwordConfirm']['code']) {
          case 'validation_values_mismatch':
            return 'Passwords do not match';
          default:
            return 'Password confirmation error';
        }
      }

      if (data?['username'] != null || data?['name'] != null) {
        return 'Please enter a valid name';
      }

      return 'Please check your input and try again';

    case 401:
      return 'Invalid credentials';

    case 403:
      return 'You don\'t have permission to perform this action';

    case 404:
      return 'Resource not found';

    case 429:
      return 'Too many attempts. Please try again later';

    case 500:
      return 'Server error. Please try again later';

    case 503:
      return 'Service temporarily unavailable. Please try again later';

    default:
      final message = e.response['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }

      return 'An error occurred. Please try again';
  }
}
