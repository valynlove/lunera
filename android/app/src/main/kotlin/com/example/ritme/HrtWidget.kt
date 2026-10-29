package com.example.ritme

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget "lama terapi": mis. "Menjalani terapi 1 tahun" dan "49 dosis tercatat". */
class HrtWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val hidden = widgetData.getString("widget_hidden", "0") == "1"
        val first = widgetData.getString("hrt_first_date", null)
        val count = widgetData.getString("hrt_count", null)?.toIntOrNull()
        val title: String
        val sub: String
        if (hidden) {
            title = "Lunera"
            sub = "Ketuk untuk membuka"
        } else if (first.isNullOrEmpty()) {
            title = "Belum ada catatan"
            sub = "Catat dosis pertamamu"
        } else {
            title = "Menjalani terapi " + durationText(first)
            sub = if (count != null) "$count dosis tercatat" else ""
        }
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_hrt)
            v.setTextViewText(R.id.title, title)
            v.setTextViewText(R.id.subtitle, sub)
            v.setOnClickPendingIntent(R.id.root, launchIntent(context))
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}
