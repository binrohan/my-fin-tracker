package com.myfin.my_fin_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Month at a glance, 4 cells wide: free to spend and a day's share, how
 * much of the budget is spent, the next bill or slot, and buttons to add
 * an expense or an income.
 */
class MonthGlanceWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        fun open(uri: String) = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.month_glance_widget).apply {
                setTextViewText(R.id.glance_month, widgetData.getString("g_month", "My Fin Tracker"))
                setTextViewText(R.id.glance_amount, widgetData.getString("g_amount", "Open the app"))
                setTextViewText(R.id.glance_perday, widgetData.getString("g_perday", "Free to spend"))
                setTextViewText(R.id.glance_spent, widgetData.getString("g_spent", ""))
                setTextViewText(R.id.glance_next, widgetData.getString("g_next", ""))
                setProgressBar(R.id.glance_bar, 100, widgetData.getInt("g_progress", 0), false)
                setOnClickPendingIntent(R.id.glance_root, open("myfin://home"))
                setOnClickPendingIntent(R.id.glance_expense, open("myfin://quickadd"))
                setOnClickPendingIntent(R.id.glance_income, open("myfin://quickadd?mode=income"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
