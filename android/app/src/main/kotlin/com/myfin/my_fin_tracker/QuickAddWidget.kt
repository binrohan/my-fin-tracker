package com.myfin.my_fin_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: what is left to spend this month and a button that
 * opens quick add. The app writes the text whenever its data changes.
 */
class QuickAddWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget).apply {
                setTextViewText(R.id.widget_title, widgetData.getString("title", "Left to spend"))
                setTextViewText(R.id.widget_amount, widgetData.getString("amount", "Open the app"))
                setTextViewText(R.id.widget_detail, widgetData.getString("detail", ""))
                setOnClickPendingIntent(
                    R.id.widget_add,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("myfin://quickadd")),
                )
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse("myfin://home")),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
