class CreationParams {
  /// Constructs an instance to use when creating a new
  /// [VideoNativePreviewPlatformController].
  ///
  /// The `autoMediaPlaybackPolicy` parameter must not be null.
  CreationParams({
    required this.initialUrl,
    required this.failedText,
    required this.retryText,
    required this.type,
  });

  /// The initialUrl to load in the video preview.
  final String initialUrl;
  final String failedText;
  final String retryText;
  final String type;

  @override
  String toString() {
    return 'CreationParams(initialUrl: $initialUrl)';
  }

  Map<String, dynamic> toJson() {
    return {
      'initialUrl': initialUrl,
      'failedText': failedText,
      'retryText': retryText,
      'type': type,
    };
  }
}
