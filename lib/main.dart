import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T> extends State<Dock<T>> with TickerProviderStateMixin {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();

  /// Currently dragged item index
  int? _draggedIndex;

  /// Target index where the dragged item will be placed
  int? _targetIndex;

  /// Currently hovered index
  int? _hoveredIndex;

  /// Animation controller for the reordering animation
  late final AnimationController _reorderController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void dispose() {
    _reorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildDockItems(),
      ),
    );
  }

  List<Widget> _buildDockItems() {
    return List.generate(_items.length, (index) {
      return _buildDockItem(index);
    });
  }

  Widget _buildDockItem(int index) {
    final item = _items[index];
    final isTargeted = _targetIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Draggable<int>(
        data: index,
        feedback: widget.builder(item),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: widget.builder(item),
        ),
        onDragStarted: () {
          setState(() {
            _draggedIndex = index;
          });
        },
        onDragEnd: (_) {
          setState(() {
            if (_targetIndex != null && _draggedIndex != null) {
              final item = _items.removeAt(_draggedIndex!);
              _items.insert(_targetIndex!, item);
              _reorderController.forward(from: 0);
            }
            _draggedIndex = null;
            _targetIndex = null;
          });
        },
        child: DragTarget<int>(
          onWillAccept: (sourceIndex) => sourceIndex != index,
          onAccept: (sourceIndex) {
            setState(() {
              _targetIndex = index;
            });
          },
          builder: (context, candidateData, rejectedData) {
            return TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              tween: Tween(
                begin: 1.0,
                end: _getTargetScale(index),
              ),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: Matrix4.identity()
                      ..translate(
                        0.0,
                        isTargeted ? -8.0 : 0.0,
                      ),
                    child: widget.builder(item),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _getTargetScale(int index) {
    if (_draggedIndex != null) return 1.0;

    if (_hoveredIndex == null) return 1.0;

    final distance = (index - _hoveredIndex!).abs();
    if (distance == 0) return 1.1; // Maximum scale for hovered item
    if (distance == 1) return 1.05; // Slightly scaled for adjacent items
    return 1.0; // Normal scale for other items
  }
}
