extension DoubleFormatting on num {
  String get formatNumber {
    if (this >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(1)}B';
    } else if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(1)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}K';
    } else {
      if (this % 10 == 0) {
        return toStringAsFixed(0);
      } else {
        return toStringAsFixed(1);
      }
    }
  }

  String formatNumWithPos({int pos = 2}) {
    if (this >= 1000000000) {
      return '${(this / 1000000000).toStringAsFixed(pos)}B';
    } else if (this >= 1000000) {
      return '${(this / 1000000).toStringAsFixed(pos)}M';
    } else if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(pos)}K';
    } else {
      if (this % 10 == 0) {
        return toStringAsFixed(0);
      } else {
        return toStringAsFixed(pos);
      }
    }
  }

  String get ordinal {
    if (this % 100 >= 11 && this % 100 <= 13) return "${this}th";
    switch (this % 10) {
      case 1:
        return "${this}st";
      case 2:
        return "${this}nd";
      case 3:
        return "${this}rd";
      default:
        return "${this}th";
    }
  }

  String get formatSongTimestamp {
    final int minutes = (this / 60).floor();
    final int remainingSeconds = (this % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}