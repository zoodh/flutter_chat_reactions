library flutter_chat_reactions;

import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_reactions/model/menu_item.dart';
import 'package:flutter_chat_reactions/utilities/default_data.dart';

class ReactionsDialogWidget extends StatefulWidget {
  const ReactionsDialogWidget({
    super.key,
    required this.id,
    required this.messageWidget,
    required this.onReactionTap,
    required this.onContextMenuTap,
    required this.messageKey,
    this.menuItems = DefaultData.menuItems,
    this.reactions = DefaultData.reactions,
    this.widgetAlignment = Alignment.centerRight,
    this.menuItemsWidth = 0.45,
    this.buildMenu = false,
    this.buildMessage = false,

  });

  // Id for the hero widget
  final String id;

  //GlobalKey for accurate positioning
  final GlobalKey messageKey;

  // The message widget to be displayed in the dialog
  final Widget messageWidget;

  // The callback function to be called when a reaction is tapped
  final Function(String) onReactionTap;

  // The callback function to be called when a context menu item is tapped
  final Function(MenuItem) onContextMenuTap;

  // The list of menu items to be displayed in the context menu
  final List<MenuItem> menuItems;

  // The list of reactions to be displayed
  final List<String> reactions;

  // The alignment of the widget
  final Alignment widgetAlignment;

  // The width of the menu items
  final double menuItemsWidth;

  //determine of the context menu needs to be built
  final bool buildMenu;
  //determine of messages need to be built
  final bool buildMessage;

  @override
  State<ReactionsDialogWidget> createState() => _ReactionsDialogWidgetState();
}
class _ReactionsDialogWidgetState extends State<ReactionsDialogWidget> {
  bool reactionClicked = false;
  int? clickedReactionIndex;
  int? clickedContextMenuIndex;
  Offset? position;
  Size? size;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        updatePosition();
      }
    });
  }

  void updatePosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? messageContext = widget.messageKey.currentContext;
      final RenderBox? renderBox = messageContext!.findRenderObject() as RenderBox?;
      setState(() {
        position = renderBox!.localToGlobal(Offset.zero);
        size = renderBox.size;
      });

    });
  }
  @override
  Widget build(BuildContext context) {
    if (position == null || size == null) {
      return const SizedBox();
    }

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.black.withOpacity(0.3),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: position!.dy - 50,
          left: position!.dx,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildReactions(context),
                const SizedBox(height: 10),
                if (widget.buildMessage) buildMessage(),
                const SizedBox(height: 10),
                if (widget.buildMenu) buildMenuItems(context),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Positioned buildMenuItems(BuildContext context) {
    final RenderBox renderBox = widget.messageKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;
    final double menuWidth = MediaQuery.of(context).size.width * widget.menuItemsWidth;

    // Ensure it stays within screen bounds
    double left = position.dx;
    if (left + menuWidth > screenSize.width) {
      left = screenSize.width - menuWidth;
    }
    if (left < 0) left = 0;

    double top = position.dy + renderBox.size.height + 10;
    if (top + 150 > screenSize.height) { // 150 is the estimated menu height
      top = position.dy - 150 - 10; // Move it above
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: menuWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var item in widget.menuItems)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            clickedContextMenuIndex = widget.menuItems.indexOf(item);
                          });
                          Future.delayed(const Duration(milliseconds: 500)).whenComplete(() {
                            Navigator.of(context).pop();
                            widget.onContextMenuTap(item);
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                color: item.isDestuctive ? Colors.red : Theme.of(context).textTheme.bodyMedium!.color,
                              ),
                            ),
                            Pulse(
                              infinite: false,
                              duration: const Duration(milliseconds: 500),
                              animate: clickedContextMenuIndex == widget.menuItems.indexOf(item),
                              child: Icon(
                                item.icon,
                                color: item.isDestuctive ? Colors.red : Theme.of(context).textTheme.bodyMedium!.color,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    if (widget.menuItems.last != item)
                      Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }


  Align buildMessage() {
    return Align(
      alignment: widget.widgetAlignment,
      child: Hero(
        tag: widget.id,
        child: widget.messageWidget,
      ),
    );
  }

  Positioned buildReactions(BuildContext context) {
    final RenderBox renderBox = widget.messageKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;

    // Ensure it doesn't exceed the screen width
    double left = position.dx;
    if (left + 200 > screenSize.width) { // 200 is the estimated reaction box width
      left = screenSize.width - 200; // Shift it inside
    }
    if (left < 0) {
      left = 0; // Prevent going off the left side
    }

    // Ensure it doesn't go off the top
    double top = position.dy - 40;
    if (top < 0) {
      top = position.dy + renderBox.size.height + 10; // Move it below the message
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade500,
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var reaction in widget.reactions)
                FadeInLeft(
                  from: (widget.reactions.indexOf(reaction) * 20).toDouble(),
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 200),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        reactionClicked = true;
                        clickedReactionIndex = widget.reactions.indexOf(reaction);
                      });
                      Future.delayed(const Duration(milliseconds: 500)).whenComplete(() {
                        Navigator.of(context).pop();
                        widget.onReactionTap(reaction);
                      });
                    },
                    child: Pulse(
                      infinite: false,
                      duration: const Duration(milliseconds: 500),
                      animate: reactionClicked && clickedReactionIndex == widget.reactions.indexOf(reaction),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4.0, 2.0, 4.0, 2),
                        child: Text(
                          reaction,
                          style: const TextStyle(fontSize: 22),
                        ),
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

}