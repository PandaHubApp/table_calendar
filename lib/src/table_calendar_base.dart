// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:simple_gesture_detector/simple_gesture_detector.dart';
import 'package:table_calendar/src/widgets/calendar_header.dart';
import 'package:table_calendar/table_calendar.dart';

import 'shared/utils.dart';
import 'widgets/calendar_core.dart';

class TableCalendarBase extends StatefulWidget {
  final List<DateTime> timeSlots;
  final List<DateTime> weather14Days;
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final DayBuilder? dowBuilder;
  final DayBuilder? weekNumberBuilder;
  final FocusedDayBuilder dayBuilder;
  final double? dowHeight;
  final double rowHeight;
  final bool sixWeekMonthsEnforced;
  final bool dowVisible;
  final bool weekNumbersVisible;
  final Decoration? dowDecoration;
  final Decoration? rowDecoration;
  final TableBorder? tableBorder;
  final EdgeInsets? tablePadding;
  final Duration formatAnimationDuration;
  final Curve formatAnimationCurve;
  final bool pageAnimationEnabled;
  final Duration pageAnimationDuration;
  final Curve pageAnimationCurve;
  final StartingDayOfWeek startingDayOfWeek;
  final AvailableGestures availableGestures;
  final SimpleSwipeConfig simpleSwipeConfig;
  final Map<CalendarFormat, String> availableCalendarFormats;
  final SwipeCallback? onVerticalSwipe;
  final void Function(DateTime focusedDay)? onPageChanged;
  final void Function(PageController pageController)? onCalendarCreated;

  TableCalendarBase({
    Key? key,
    required this.timeSlots,
    required this.weather14Days,
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    this.calendarFormat = CalendarFormat.month,
    this.dowBuilder,
    required this.dayBuilder,
    this.dowHeight,
    required this.rowHeight,
    this.sixWeekMonthsEnforced = false,
    this.dowVisible = true,
    this.weekNumberBuilder,
    this.weekNumbersVisible = false,
    this.dowDecoration,
    this.rowDecoration,
    this.tableBorder,
    this.tablePadding,
    this.formatAnimationDuration = const Duration(milliseconds: 200),
    this.formatAnimationCurve = Curves.linear,
    this.pageAnimationEnabled = true,
    this.pageAnimationDuration = const Duration(milliseconds: 300),
    this.pageAnimationCurve = Curves.easeOut,
    this.startingDayOfWeek = StartingDayOfWeek.sunday,
    this.availableGestures = AvailableGestures.all,
    this.simpleSwipeConfig = const SimpleSwipeConfig(
      verticalThreshold: 25.0,
      swipeDetectionBehavior: SwipeDetectionBehavior.continuousDistinct,
    ),
    this.availableCalendarFormats = const {
      CalendarFormat.month: 'Month',
      CalendarFormat.twoWeeks: '2 weeks',
      CalendarFormat.week: 'Week',
    },
    this.onVerticalSwipe,
    this.onPageChanged,
    this.onCalendarCreated,
  })  : assert(!dowVisible || (dowHeight != null && dowBuilder != null)),
        assert(isSameDay(focusedDay, firstDay) || focusedDay.isAfter(firstDay)),
        assert(isSameDay(focusedDay, lastDay) || focusedDay.isBefore(lastDay)),
        super(key: key);

  @override
  _TableCalendarBaseState createState() => _TableCalendarBaseState();
}

class _TableCalendarBaseState extends State<TableCalendarBase> {
  late final ValueNotifier<double> _pageHeight;

  // late final ValueNotifier<DateTime> _focusedDayNotifier;
  late final PageController _pageController;
  late ValueNotifier<DateTime> _focusedDay;
  late int _previousIndex;
  late bool _pageCallbackDisabled;

  @override
  void initState() {
    super.initState();
    _focusedDay = ValueNotifier(widget.focusedDay);

    final rowCount = _getRowCount(widget.calendarFormat, _focusedDay.value);
    final activeRowCount = _getRowCountWithAvailableSlots(
        widget.calendarFormat, _focusedDay.value);
    _pageHeight = ValueNotifier(_getPageHeight(rowCount, activeRowCount));
    // _focusedDayNotifier = ValueNotifier(widget.focusedDay);
    print(_pageHeight);

    final initialPage = _calculateFocusedPage(
        widget.calendarFormat, widget.firstDay, _focusedDay.value);

    _pageController = PageController(initialPage: initialPage);
    widget.onCalendarCreated?.call(_pageController);

    _previousIndex = initialPage;
    _pageCallbackDisabled = false;
  }

  @override
  void didUpdateWidget(TableCalendarBase oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_focusedDay.value != widget.focusedDay ||
        widget.calendarFormat != oldWidget.calendarFormat ||
        widget.startingDayOfWeek != oldWidget.startingDayOfWeek) {
      final shouldAnimate = _focusedDay.value != widget.focusedDay;

      _focusedDay.value = widget.focusedDay;
      _updatePage(shouldAnimate: shouldAnimate);
    }

    if (widget.rowHeight != oldWidget.rowHeight ||
        widget.dowHeight != oldWidget.dowHeight ||
        widget.dowVisible != oldWidget.dowVisible ||
        widget.sixWeekMonthsEnforced != oldWidget.sixWeekMonthsEnforced) {
      final rowCount = _getRowCount(widget.calendarFormat, _focusedDay.value);
      final activeRowCount = _getRowCountWithAvailableSlots(
          widget.calendarFormat, _focusedDay.value);
      _pageHeight.value = _getPageHeight(rowCount, activeRowCount);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageHeight.dispose();
    super.dispose();
  }

  bool get _canScrollHorizontally =>
      widget.availableGestures == AvailableGestures.all ||
      widget.availableGestures == AvailableGestures.horizontalSwipe;

  bool get _canScrollVertically =>
      widget.availableGestures == AvailableGestures.all ||
      widget.availableGestures == AvailableGestures.verticalSwipe;

  void _updatePage({bool shouldAnimate = false}) {
    final currentIndex = _calculateFocusedPage(
        widget.calendarFormat, widget.firstDay, _focusedDay.value);

    final endIndex = _calculateFocusedPage(
        widget.calendarFormat, widget.firstDay, widget.lastDay);

    if (currentIndex != _previousIndex ||
        currentIndex == 0 ||
        currentIndex == endIndex) {
      _pageCallbackDisabled = true;
    }

    if (shouldAnimate && widget.pageAnimationEnabled) {
      if ((currentIndex - _previousIndex).abs() > 1) {
        final jumpIndex =
            currentIndex > _previousIndex ? currentIndex - 1 : currentIndex + 1;

        _pageController.jumpToPage(jumpIndex);
      }

      _pageController.animateToPage(
        currentIndex,
        duration: widget.pageAnimationDuration,
        curve: widget.pageAnimationCurve,
      );
    } else {
      _pageController.jumpToPage(currentIndex);
    }

    _previousIndex = currentIndex;
    final rowCount = _getRowCount(widget.calendarFormat, _focusedDay.value);
    final activeRowCount = _getRowCountWithAvailableSlots(
        widget.calendarFormat, _focusedDay.value);
    _pageHeight.value = _getPageHeight(rowCount, activeRowCount);

    _pageCallbackDisabled = false;
  }

  void _onLeftChevronTap() {
    _pageController.previousPage(
      duration: widget.pageAnimationDuration,
      curve: widget.pageAnimationCurve,
    );
  }

  void _onRightChevronTap() {
    _pageController.nextPage(
      duration: widget.pageAnimationDuration,
      curve: widget.pageAnimationCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            if (true)
              ValueListenableBuilder<DateTime>(
                valueListenable: _focusedDay,
                builder: (context, value, _) {
                  return CalendarHeader(
                    headerTitleBuilder: null,
                    focusedMonth: value,
                    onLeftChevronTap: _onLeftChevronTap,
                    onRightChevronTap: _onRightChevronTap,
                    onHeaderTap: () {},
                    headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        headerPadding: EdgeInsets.zero),
                    availableCalendarFormats: widget.availableCalendarFormats,
                    calendarFormat: widget.calendarFormat,
                    onFormatButtonTap: (_) {},
                    onHeaderLongPress: () {},
                  );
                },
              ),
            SimpleGestureDetector(
              onVerticalSwipe:
                  _canScrollVertically ? widget.onVerticalSwipe : null,
              swipeConfig: widget.simpleSwipeConfig,
              child: ValueListenableBuilder<double>(
                valueListenable: _pageHeight,
                builder: (context, value, child) {
                  final height = constraints.hasBoundedHeight
                      ? constraints.maxHeight
                      : value;

                  return AnimatedSize(
                    duration: widget.formatAnimationDuration,
                    curve: widget.formatAnimationCurve,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: value,
                      child: child,
                    ),
                  );
                },
                child: CalendarCore(
                  weather: widget.weather14Days,
                  timeSlots: widget.timeSlots,
                  constraints: constraints,
                  pageController: _pageController,
                  scrollPhysics: _canScrollHorizontally
                      ? PageScrollPhysics()
                      : NeverScrollableScrollPhysics(),
                  firstDay: widget.firstDay,
                  lastDay: widget.lastDay,
                  startingDayOfWeek: widget.startingDayOfWeek,
                  calendarFormat: widget.calendarFormat,
                  previousIndex: _previousIndex,
                  focusedDay: _focusedDay.value,
                  sixWeekMonthsEnforced: widget.sixWeekMonthsEnforced,
                  dowVisible: widget.dowVisible,
                  dowHeight: widget.dowHeight,
                  rowHeight: widget.rowHeight,
                  weekNumbersVisible: widget.weekNumbersVisible,
                  weekNumberBuilder: widget.weekNumberBuilder,
                  dowDecoration: widget.dowDecoration,
                  rowDecoration: widget.rowDecoration,
                  tableBorder: widget.tableBorder,
                  tablePadding: widget.tablePadding,
                  onPageChanged: (index, focusedMonth) {
                    if (!_pageCallbackDisabled) {
                      if (!isSameDay(_focusedDay.value, focusedMonth)) {
                        _focusedDay.value = focusedMonth;
                      }

                      if (widget.calendarFormat == CalendarFormat.month &&
                          !widget.sixWeekMonthsEnforced &&
                          !constraints.hasBoundedHeight) {
                        final rowCount = _getRowCount(
                          widget.calendarFormat,
                          focusedMonth,
                        );
                        final activeRowCount = _getRowCountWithAvailableSlots(
                          widget.calendarFormat,
                          _focusedDay.value,
                        );
                        _pageHeight.value =
                            _getPageHeight(rowCount, activeRowCount);
                      }

                      _previousIndex = index;
                      widget.onPageChanged?.call(focusedMonth);
                    }

                    _pageCallbackDisabled = false;
                  },
                  dowBuilder: widget.dowBuilder,
                  dayBuilder: widget.dayBuilder,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  double _getPageHeight(int rowCount, int activeRowCount) {
    final tablePaddingHeight = widget.tablePadding?.vertical ?? 0.0;
    final dowHeight = widget.dowVisible ? widget.dowHeight! : 0.0;
    return dowHeight + rowCount * 36 + tablePaddingHeight + activeRowCount * 30;
  }

  int _calculateFocusedPage(
      CalendarFormat format, DateTime startDay, DateTime focusedDay) {
    switch (format) {
      case CalendarFormat.month:
        return _getMonthCount(startDay, focusedDay);
      case CalendarFormat.twoWeeks:
        return _getTwoWeekCount(startDay, focusedDay);
      case CalendarFormat.week:
        return _getWeekCount(startDay, focusedDay);
      default:
        return _getMonthCount(startDay, focusedDay);
    }
  }

  int _getMonthCount(DateTime first, DateTime last) {
    final yearDif = last.year - first.year;
    final monthDif = last.month - first.month;

    return yearDif * 12 + monthDif;
  }

  int _getWeekCount(DateTime first, DateTime last) {
    return last.difference(_firstDayOfWeek(first)).inDays ~/ 7;
  }

  int _getTwoWeekCount(DateTime first, DateTime last) {
    return last.difference(_firstDayOfWeek(first)).inDays ~/ 14;
  }

  int _getRowCount(CalendarFormat format, DateTime focusedDay) {
    if (format == CalendarFormat.twoWeeks) {
      return 2;
    } else if (format == CalendarFormat.week) {
      return 1;
    } else if (widget.sixWeekMonthsEnforced) {
      return 6;
    }

    final first = _firstDayOfMonth(focusedDay);
    final daysBefore = _getDaysBefore(first);
    final firstToDisplay = first.subtract(Duration(days: daysBefore));

    final last = _lastDayOfMonth(focusedDay);
    final daysAfter = _getDaysAfter(last);
    final lastToDisplay = last.add(Duration(days: daysAfter));

    return (lastToDisplay.difference(firstToDisplay).inDays + 1) ~/ 7;
  }

  int _getRowCountWithAvailableSlots(
      CalendarFormat format, DateTime focusedDay) {
    try {
      final first = _firstDayOfMonth(focusedDay);
      final daysBefore = _getDaysBefore(first);
      final firstToDisplay = first.subtract(Duration(days: daysBefore));

      final regularRowCount = _getRowCount(format, focusedDay);

      int rowCount = 0;

      DateTime datePointer = firstToDisplay;
      print('before');
      for (int i = 0; i < regularRowCount; i++) {
        final endOfTheRowDate = datePointer.add(Duration(days: 7));
        for (DateTime date = datePointer;
            date.isBefore(endOfTheRowDate) ||
                date.isAtSameMomentAs(endOfTheRowDate);
            date = date.add(Duration(days: 1))) {
          final hasAvailableSlotOrWeather = widget.weather14Days.length > 0
              ? widget.weather14Days
                  .sublist(1)
                  .any((weatherDay) => _isSameDay(weatherDay, date))
              // check for timeslots availability
              //     &&
              // widget.timeSlots.any((timeSlot) => _isSameDay(timeSlot, date))
              : false;

          if (hasAvailableSlotOrWeather) {
            rowCount++;
            break;
          }
        }
        datePointer = datePointer.add(Duration(days: 7));
      }
      print('after');

      return rowCount;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  int _getDaysBefore(DateTime firstDay) {
    return (firstDay.weekday + 7 - getWeekdayNumber(widget.startingDayOfWeek)) %
        7;
  }

  int _getDaysAfter(DateTime lastDay) {
    int invertedStartingWeekday =
        8 - getWeekdayNumber(widget.startingDayOfWeek);

    int daysAfter = 7 - ((lastDay.weekday + invertedStartingWeekday) % 7);
    if (daysAfter == 7) {
      daysAfter = 0;
    }

    return daysAfter;
  }

  DateTime _firstDayOfWeek(DateTime week) {
    final daysBefore = _getDaysBefore(week);
    return week.subtract(Duration(days: daysBefore));
  }

  DateTime _firstDayOfMonth(DateTime month) {
    return DateTime.utc(month.year, month.month, 1);
  }

  DateTime _lastDayOfMonth(DateTime month) {
    final date = month.month < 12
        ? DateTime.utc(month.year, month.month + 1, 1)
        : DateTime.utc(month.year + 1, 1, 1);
    return date.subtract(const Duration(days: 1));
  }
}
