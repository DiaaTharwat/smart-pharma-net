// lib/repositories/chat_ai_repository.dart
import 'package:smart_pharma_net/services/api_service.dart';

class ChatAiRepository {
  final ApiService _apiService;

  ChatAiRepository(this._apiService);

  Future<String> sendMessageToAI(String message) async {
    try {
      print('Sending message to AI: $message');

      final response = await _apiService.publicPost(
        'chat/ai/',
        {'message': message},
      );

      // Check for 'reply' key for successful responses
      if (response != null && response.containsKey('reply')) {
        return response['reply'];
      }
      // Check for 'error' key for known error responses
      else if (response != null && response.containsKey('error')) {
        print('Handled API Error: ${response['error']}');
        return "Sorry, there was an issue with the AI service. Please try again.";
      }
      // Handle other unexpected formats
      else {
        throw Exception('Invalid response format from AI API.');
      }
    } catch (e) {
      print('Error in ChatAiRepository: $e');
      // Return a user-friendly error message
      return "I'm having trouble connecting right now. Please check your connection and try again.";
    }
  }
}
