import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Where row [index] starts, guessed from a row that is built and so has a
/// known position: [anchorIndex] at [anchorOffset], with rows [average] tall.
double extrapolatedRowOffset({
  required int index,
  required int anchorIndex,
  required double anchorOffset,
  required double average,
}) => anchorOffset + (index - anchorIndex) * average;

/// Where in the viewport a row's top was, as a fraction, kept inside the part
/// of the screen where a whole row is likely to fit.
double alignmentOf({required double top, required double viewport}) {
  if (viewport <= 0) return 0;
  return (top / viewport).clamp(0.0, 0.6);
}

/// Keeps a list scrolled to a story that is being read somewhere else, so that
/// coming back finds it on screen. It jumps; whatever covers the list hides
/// the movement.
class StoryListPlace {
  final controller = ScrollController();
  final _owner = Object();
  double _alignment = 0.3;
  var _generation = 0;

  static const _attempts = 8;

  GlobalKey keyFor(int id) => GlobalObjectKey((_owner, id));

  void dispose() => controller.dispose();

  /// Notes where the row of [id] sits, so the story that replaces it lands in
  /// the same place.
  void remember(int id) {
    final context = keyFor(id).currentContext;
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !controller.hasClients) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    final position = controller.position;
    final top = viewport.getOffsetToReveal(box, 0).offset - position.pixels;
    _alignment = alignmentOf(top: top, viewport: position.viewportDimension);
  }

  /// Scrolls to row [index] of [count], the story [id].
  void show(int id, {required int index, required int count}) {
    _generation++;
    _aim(id, index, count, _generation, _attempts);
  }

  void _aim(int id, int index, int count, int generation, int attempts) {
    if (generation != _generation || !controller.hasClients) return;
    final position = controller.position;
    final box = keyFor(id).currentContext?.findRenderObject();
    final viewport = box is RenderBox && box.attached
        ? RenderAbstractViewport.maybeOf(box)
        : null;
    if (box is RenderBox && viewport != null) {
      final top = viewport.getOffsetToReveal(box, 0).offset - position.pixels;
      final fits =
          top >= 0 && top + box.size.height <= position.viewportDimension;
      if (fits) return;
      _jump(viewport.getOffsetToReveal(box, _alignment).offset);
      return;
    }
    final guess = _guess(index);
    if (guess == null) return;
    _jump(guess - _alignment * position.viewportDimension);
    if (attempts <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _aim(id, index, count, generation, attempts - 1),
    );
  }

  /// Where row [index] probably starts, measured from the built row nearest
  /// to it. Rows are of uneven height, so this lands near and the next frame,
  /// which builds the rows there, corrects it.
  double? _guess(int index) {
    final sliver = _sliver();
    if (sliver == null) return null;
    RenderBox? anchor;
    var anchorIndex = 0;
    var total = 0.0;
    var built = 0;
    for (
      var row = sliver.firstChild;
      row != null;
      row = sliver.childAfter(row)
    ) {
      final at = sliver.indexOf(row);
      total += row.size.height;
      built++;
      if (anchor == null || (at - index).abs() < (anchorIndex - index).abs()) {
        anchor = row;
        anchorIndex = at;
      }
    }
    final offset = anchor == null ? null : sliver.childScrollOffset(anchor);
    if (anchor == null || offset == null || total <= 0) return null;
    return extrapolatedRowOffset(
      index: index,
      anchorIndex: anchorIndex,
      anchorOffset: offset,
      average: total / built,
    );
  }

  RenderSliverMultiBoxAdaptor? _sliver() {
    RenderSliverMultiBoxAdaptor? found;
    void visit(RenderObject object) {
      if (found != null) return;
      if (object is RenderSliverMultiBoxAdaptor) {
        found = object;
        return;
      }
      object.visitChildren(visit);
    }

    final root = controller.position.context.storageContext.findRenderObject();
    if (root != null) visit(root);
    return found;
  }

  void _jump(double offset) {
    final position = controller.position;
    final target = offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) controller.jumpTo(target);
  }
}
