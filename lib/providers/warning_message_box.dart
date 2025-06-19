import 'package:flutter/material.dart';

enum WarningType {
  noSound,
  microphonePermission,
  networkError,
  saveConfirmation,
}

class WarningMessageBox extends StatelessWidget {
  final WarningType warningType;
  final VoidCallback onClose;
  final VoidCallback onAction;
  final Function() onDismiss;
  final bool isVisible;

  const WarningMessageBox({
    super.key,
    required this.warningType,
    required this.onClose,
    required this.onAction,
    required this.onDismiss,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  onClose();
                  onDismiss();
                },
              ),
            ],
          ),
          Text(
            _getMessage(),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                onAction();
                onDismiss();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _getBackgroundColor(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_getButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (warningType) {
      case WarningType.noSound:
        return Colors.blue;
      case WarningType.microphonePermission:
        return Colors.orange;
      case WarningType.networkError:
        return Colors.red;
      case WarningType.saveConfirmation:
        return Colors.green;
    }
  }

  String _getTitle() {
    switch (warningType) {
      case WarningType.noSound:
        return 'No sound';
      case WarningType.microphonePermission:
        return 'Permission Required';
      case WarningType.networkError:
        return 'Network Error';
      case WarningType.saveConfirmation:
        return 'Save Confirmation';
    }
  }

  String _getMessage() {
    switch (warningType) {
      case WarningType.noSound:
        return 'Please check your microphone to make sure it\'s connected and recording correctly.';
      case WarningType.microphonePermission:
        return 'Microphone access is required to record audio. Please grant permission in settings.';
      case WarningType.networkError:
        return 'Unable to connect to the server. Please check your internet connection.';
      case WarningType.saveConfirmation:
        return 'Do you want to save the current recording before starting a new one?';
    }
  }

  String _getButtonText() {
    switch (warningType) {
      case WarningType.noSound:
        return 'OK';
      case WarningType.microphonePermission:
        return 'Open Settings';
      case WarningType.networkError:
        return 'Retry';
      case WarningType.saveConfirmation:
        return 'Save';
    }
  }

  String _getDismissButtonText() {
    switch (warningType) {
      case WarningType.saveConfirmation:
        return 'Discard';
      case WarningType.noSound:
        return 'Cancel';
      case WarningType.microphonePermission:
        return 'Cancel';
      case WarningType.networkError:
        return 'Cancel';
    }
  }
}