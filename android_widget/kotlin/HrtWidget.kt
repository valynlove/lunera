package com.example.ritme

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget "lama terapi": mis. "On therapy for 1 year" dan "49 doses logged" (atau versi Indonesia). */
class HrtWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val lang = appLang(widgetData)
        val id = lang == "id"
        val hidden = widgetData.getString("widget_hidden", "0") == "1"
        val first = widgetData.getString("hrt_first_date", null)
        val count = widgetData.getString("hrt_count", null)?.toIntOrNull()
        val title: String
        val sub: String
        if (hidden) {
            title = "Lunera"
            sub = if (id) "Ketuk untuk membuka" else "Tap to open"
        } else if (first.isNullOrEmpty()) {
            title = if (id) "Belum ada catatan" else "No entries yet"
            sub = if (id) "Catat dosis pertamamu" else "Log your first dose"
        } else {
            title = (if (id) "Menjalani terapi " else "On therapy for ") + durationText(first, lang)
            sub = if (count == null) "" else if (id) "$count dosis tercatat" else "$count ${if (count == 1) "dose" else "doses"} logged"
        }
        for (wid in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_hrt)
            v.setTextViewText(R.id.title, title)
            v.setTextViewText(R.id.subtitle, sub)
            v.setOnClickPendingIntent(R.id.root, launchIntent(context))
            appWidgetManager.updateAppWidget(wid, v)
        }
    }
}
