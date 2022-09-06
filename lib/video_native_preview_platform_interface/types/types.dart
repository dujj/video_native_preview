export 'creation_params.dart';

class CreationParams {
  /// Constructs an instance to use when creating a new
  /// [VideoNativePreviewPlatformController].
  ///
  /// The `autoMediaPlaybackPolicy` parameter must not be null.
  CreationParams({
    required this.initialUrl,
  });

  /// The initialUrl to load in the video preview.
  final String initialUrl;

  @override
  String toString() {
    return 'CreationParams(initialUrl: $initialUrl)';
  }

  Map<String, dynamic> toJson() {
    return {'initialUrl': initialUrl};
  }
}
