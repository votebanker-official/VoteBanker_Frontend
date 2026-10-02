abstract final class AppBreakpoints {
  static const onboardingMaxWidth = 520.0;
  static const dashboardMaxWidth = 1080.0;
  static const wide = 800.0;
  static const tablet = 720.0;
  static const desktop = 1100.0;

  static bool isWide(double width) => width >= wide;

  static int dashboardColumns(double width) {
    if (width >= desktop) {
      return 3;
    }
    if (width >= tablet) {
      return 2;
    }
    return 1;
  }
}
