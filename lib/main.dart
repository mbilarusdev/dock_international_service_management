import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class AssetsBundle {
  static const String background = 'images/background.jpeg';
}

void main() async => runApp(const DockApp());

/// Dock item configuration
class DockItemConfiguration<T extends Widget> with EquatableMixin {
  /// Title of dock item
  final String title;

  /// Dock item widget
  final T value;

  /// Equals true when item "flying"
  bool isFlying;

  // Equals true when item is reordering
  bool isReordering;

  DockItemConfiguration({required this.value, required this.title})
      : isFlying = false,
        isReordering = false;

  @override
  List<Object?> get props => [value, title];
}

/// Test task application for International Service Management
class DockApp extends StatefulWidget {
  const DockApp({super.key});

  @override
  State<DockApp> createState() => _DockAppState();
}

class _DockAppState extends State<DockApp> {
  /// Notifier of dock with [Icon]-s
  DockNotifier<Icon>? notifier;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blueGrey,
      ),
      home: ScaffoldWithDock<Icon>(
        dock: Dock<Icon>(
          itemDimension: 36.0,
          itemPadding: 36 / 4.5,
          bottomPadding: 8.0,
          items: [
            DockItemConfiguration(
              value: const Icon(Icons.person, color: Colors.white),
              title: 'person',
            ),
            DockItemConfiguration(
              value: const Icon(Icons.message, color: Colors.white),
              title: 'message',
            ),
            DockItemConfiguration(
              value: const Icon(Icons.call, color: Colors.white),
              title: 'call',
            ),
            DockItemConfiguration(
              value: const Icon(Icons.camera, color: Colors.white),
              title: 'camera',
            ),
            DockItemConfiguration(
              value: const Icon(Icons.photo, color: Colors.white),
              title: 'photo',
            ),
          ],
        ),
      ),
    );
  }
}

class ScaffoldWithDock<T extends Widget> extends StatelessWidget {
  final Dock<T> dock;
  const ScaffoldWithDock({super.key, required this.dock});

  @override
  Widget build(BuildContext context) {
    return DockInherited<T>(
      notifier: DockNotifier<T>(),
      child: Builder(
        builder: (context) {
          final notifier = context.dependOnInheritedWidgetOfExactType<DockInherited<T>>()!.notifier!;
          if (notifier.itemDimension == null) {
            notifier
              ..updateItemDimension(dock.itemDimension)
              ..initialDimension = dock.itemDimension;
          }
          return Scaffold(
            body: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage(AssetsBundle.background),
                    ),
                  ),
                ),
                dock,
                Positioned(
                  bottom: 8.0,
                  right: 8.0,
                  child: Container(
                    width: 160,
                    height: 40,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.26),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(children: [
                      Text(
                        '${notifier.itemDimension?.toInt()} px',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          activeColor: Colors.blueGrey,
                          max: 1.5,
                          min: 1,
                          value: notifier.dimensionSliderValue,
                          onChanged: (value) {
                            notifier.updateDimensionSliderValue(value);
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
                notifier.flyingDockItem != null
                    ? FlyingDockItem<T>(
                        item: DockItem(
                          item: notifier.flyingDockItem!,
                          itemDimension: notifier.itemDimension!,
                          itemPadding: notifier.itemPadding!,
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// [DockInherited] Notifier for [Dock]
class DockNotifier<T extends Widget> extends ChangeNotifier {
  /// Initial position on start pan
  Offset? _startPosition;

  /// Position after user triggers pan update
  Offset? _position;

  /// Configuration for flying item
  DockItemConfiguration<T>? _flyingDockItem;

  /// Item dimension
  double? _itemDimension;

  /// Updates item dimension
  void updateItemDimension(double dimension) {
    _itemDimension = dimension;
    _updateItemPadding(dimension / 4.5);
  }

  double _dimensionSliderValue = 1;

  double get dimensionSliderValue => _dimensionSliderValue;

  double? initialDimension;

  void updateDimensionSliderValue(double value) {
    _dimensionSliderValue = value;
    updateItemDimension(value * initialDimension!);
    notifyListeners();
  }

  double? _itemPadding;

  double? get itemPadding => _itemPadding;

  void _updateItemPadding(double value) {
    _itemPadding = value;
  }

  /// Item dimension getter
  double? get itemDimension => _itemDimension;

  /// Position getter
  Offset? get position => _position;

  /// StartPosition getter
  Offset? get startPosition => _startPosition;

  /// Set start position and position
  void changePosition(Offset position) {
    if (_startPosition == null) {
      _startPosition = position;
      _position = _startPosition!;
    } else {
      _position = position;
    }
    notifyListeners();
  }

  /// Resets start position
  void resetStartPosition([Offset? startPosition]) {
    _startPosition = startPosition;
    notifyListeners();
  }

  /// Flying item getter
  DockItemConfiguration<T>? get flyingDockItem => _flyingDockItem;

  /// Select flying item
  void selectFlyingDockItem(DockItemConfiguration<T> flyingDockItem) {
    _flyingDockItem = flyingDockItem;
  }

  /// Clear flying item
  void clearFlyingDockItem() {
    _flyingDockItem = null;
    notifyListeners();
  }
}

/// InheritedWidget for [DockNotifier]
class DockInherited<T extends Widget> extends InheritedNotifier<DockNotifier<T>> {
  const DockInherited({
    super.key,
    required super.notifier,
    required super.child,
  });
}

/// Dock item with animation when position changed
class FlyingDockItem<T extends Widget> extends StatelessWidget {
  // Dock item
  final DockItem<T> item;
  const FlyingDockItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final notifier = context.dependOnInheritedWidgetOfExactType<DockInherited<T>>()!.notifier!;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 50),
      top: notifier.position!.dy,
      left: notifier.position!.dx,
      child: item,
    );
  }
}

/// Item of [Dock] panel
class DockItem<T extends Widget> extends StatefulWidget {
  /// Item configuration
  final DockItemConfiguration<T> item;

  /// Left padding of item
  final double itemPadding;

  /// Item size/dimension
  final double itemDimension;

  const DockItem({
    super.key,
    required this.item,
    this.itemPadding = Dock.defaultItemPadding,
    this.itemDimension = Dock.defaultItemDimension,
  });

  @override
  State<DockItem> createState() => _DockItemState();
}

class _DockItemState<T> extends State<DockItem> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = Colors.primaries[item.hashCode % Colors.primaries.length];

    return Padding(
      padding: EdgeInsets.only(left: widget.itemPadding),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.itemDimension,
        height: widget.itemDimension,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: _beautifullGradient(color),
        ),
        child: Center(
          child: widget.item.value,
        ),
      ),
    );
  }

  /// Creates gradient for item
  LinearGradient _beautifullGradient(Color secondColor) => LinearGradient(
        colors: [Colors.blueGrey, secondColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Bottom panel with reordable items [DockItem]
///
/// When item is panned then created [FlyingDockItem] and
/// its item is controlled by pan gestures and [DockInherited]
/// plus [DockNotifier]
class Dock<T extends Widget> extends StatefulWidget {
  /// Item configurations for build dock items
  final List<DockItemConfiguration<T>> items;

  /// Dimension of an item
  final double itemDimension;

  /// Padding of an item
  final double itemPadding;

  /// Bottom padding of the dock
  final double bottomPadding;

  /// An item padding plus dimension
  final double itemPlusPadding;

  const Dock({
    super.key,
    required this.items,
    this.itemDimension = defaultItemDimension,
    this.itemPadding = defaultItemPadding,
    this.bottomPadding = defaultBottomPadding,
  }) : itemPlusPadding = itemPadding + itemDimension;

  /// Default value of dock item dimension
  static const double defaultItemDimension = 48.0;

  /// Default value of dock item padding
  static const double defaultItemPadding = 12.0;

  /// Default value of dock bottom padding
  static const double defaultBottomPadding = 8.0;

  @override
  State<Dock<T>> createState() => _DockState<T>();

  /// Flying animation duration
  static const Duration flyingDuration = Duration(milliseconds: 500);
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Widget> extends State<Dock<T>> with TickerProviderStateMixin {
  /// Dock items
  late final List<DockItemConfiguration<T>> items;
  // Controller of flying dock item
  late AnimationController _controller;
  // Animation of flying dock item
  late Animation<Offset> _animation;
  // Notifier of dock settings
  DockNotifier<T>? notifier;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    items = widget.items;
  }

  @override
  Widget build(BuildContext context) {
    final itemDimension = notifier!.itemDimension!;
    final itemPadding = notifier!.itemPadding!;
    final itemPlusPadding = itemDimension + itemPadding;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: widget.bottomPadding),
        child: Container(
          padding: EdgeInsets.all(itemPadding).copyWith(left: 0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...items.map(
                (item) => Opacity(
                  key: Key(item.title),
                  opacity: notifier?.flyingDockItem == item ? 0 : 1,
                  child: GestureDetector(
                    onPanDown: (details) {
                      notifier
                        ?..resetStartPosition()
                        ..changePosition(
                          Offset(
                            details.globalPosition.dx - details.localPosition.dx,
                            details.globalPosition.dy - details.localPosition.dy,
                          ),
                        )
                        ..selectFlyingDockItem(item);
                      _controller.stop();
                    },
                    onPanUpdate: (details) async {
                      final deltaX = details.delta.dx;
                      final deltaY = details.delta.dy;

                      notifier!
                          .changePosition(Offset(notifier!.position!.dx + deltaX, notifier!.position!.dy + deltaY));

                      final paddingsWidth = (items.length + 1) * itemPadding;
                      final itemsWidth = (items.length) * itemDimension;
                      final dockWidth = paddingsWidth + itemsWidth;
                      final dockHeight = itemPadding * 2 + itemDimension;

                      final screenSize = MediaQuery.sizeOf(context);
                      final screenWidth = screenSize.width;
                      final screenHeight = screenSize.height;
                      final dockStartDx = (screenWidth - dockWidth) / 2;
                      final dockEndDx = dockStartDx + dockWidth;
                      final leftTopPoint = Offset(dockStartDx, screenHeight - (widget.bottomPadding + dockHeight));

                      final rightBottomPoint = Offset(dockEndDx, screenHeight - widget.bottomPadding);
                      final cursorInDock =
                          Rect.fromPoints(leftTopPoint, rightBottomPoint).contains(details.globalPosition);

                      if (!cursorInDock) {
                        item.isFlying = true;
                      } else {
                        item.isFlying = false;
                        final indexOfItem = items.indexOf(item);
                        if (items.length > 1) {
                          for (double i = 0; i < items.length; i++) {
                            final isLastRectangle = i == items.length - 1;
                            final endPadding = (isLastRectangle ? itemPadding : 0);
                            if (indexOfItem == i) continue;
                            if (Rect.fromPoints(
                              leftTopPoint + Offset(itemPlusPadding * (i), 0),
                              leftTopPoint +
                                  Offset(
                                    itemPlusPadding * (i + 1) + endPadding,
                                    itemPlusPadding,
                                  ),
                            ).contains(details.globalPosition)) {
                              item.isReordering = true;
                              notifier?.resetStartPosition(
                                  notifier!.startPosition! + Offset(itemDimension + itemPadding, 0));
                              items.remove(item);
                              items.insert(i.toInt(), item);
                              return;
                            }
                          }
                        }
                      }
                    },
                    onPanEnd: (details) async {
                      _animateFlying(details.velocity.pixelsPerSecond, MediaQuery.sizeOf(context));
                      item.isFlying = false;
                      // if (!item.isReordering) {
                      await Future.delayed(Dock.flyingDuration);
                      // }
                      item.isReordering = false;
                      notifier?.clearFlyingDockItem();
                    },
                    child: DockItem(
                      item: item,
                      itemDimension: item.isFlying ? 0 : itemDimension,
                      itemPadding: item.isFlying ? 0 : itemPadding,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Animate fly physics
  void _animateFlying(Offset pixelsPerSecond, Size size) {
    _animation = _controller.drive(Tween(begin: notifier!.position, end: notifier!.startPosition));

    final unitsPerSecondX = pixelsPerSecond.dx / size.width;
    final unitsPerSecondY = pixelsPerSecond.dy / size.height;
    final unitsPerSecond = Offset(unitsPerSecondX, unitsPerSecondY);
    final unitVelocity = unitsPerSecond.distance;

    const spring = SpringDescription(mass: 40, stiffness: 1, damping: 1);

    final simulation = SpringSimulation(spring, 0, 1, -unitVelocity);

    _controller.animateWith(simulation);
  }

  @override
  void didChangeDependencies() {
    final bool initial = notifier == null;
    notifier = context.dependOnInheritedWidgetOfExactType<DockInherited<T>>()!.notifier!;

    if (initial) {
      _controller.addListener(() => setState(() => notifier?.changePosition(_animation.value)));
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
