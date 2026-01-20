import 'package:flutter/material.dart';
import 'package:realtime_location_tracking/app/theme/AppTextStyles.dart';

class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final VoidCallback? onTapBack;
  final List<Widget>? actions;
  final double height;
  final Color? backgroundColor;
  final bool showBack;
  final bool centerTitle;

  const CommonHeader({
    Key? key,
    this.title,
    this.titleWidget,
    this.onTapBack,
    this.actions,
    this.height = 72.0,
    this.backgroundColor,
    this.showBack = true,
    this.centerTitle = false,
  }) : assert(
         title != null || titleWidget != null,
         'Provide either title or titleWidget',
       ),
       super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = AppTextStyle.titleMediumStyle(
      context,
    ).copyWith(fontWeight: FontWeight.w600);

    return Material(
      color: backgroundColor ?? theme.scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (showBack)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed:
                        onTapBack ?? () => Navigator.of(context).maybePop(),
                  ),
                )
              else
                const SizedBox(width: 48),

              Expanded(
                child: centerTitle
                    ? Center(
                        child: titleWidget ?? Text(title!, style: textStyle),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: titleWidget ?? Text(title!, style: textStyle),
                      ),
              ),

              if (actions != null && actions!.isNotEmpty)
                Row(children: actions!)
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
