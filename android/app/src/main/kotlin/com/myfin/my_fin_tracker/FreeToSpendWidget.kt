package com.myfin.my_fin_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget like the quick add one, but showing what is free to
 * spend once the fixed bills still to pay are taken off.
 */
class FreeToSpendWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget).apply {
                setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_background_free)
                setTextViewText(R.id.widget_title, widgetData.getString("free_title", "Free to spend"))
                setTextViewText(R.id.widget_amount, widgetData.getString("free_amount", "Open the app"))
                setTextViewText(R.id.widget_detail, widgetData.getString("free_detail", "after bills"))
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
