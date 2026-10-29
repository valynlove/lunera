package com.example.ritme

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/** Widget grafik level hormon. Gambar grafiknya dibuat oleh aplikasi (Flutter) lalu dibaca dari file. */
class LevelWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val hidden = widgetData.getString("widget_hidden", "0") == "1"
        val title = widgetData.getString("lvl_title", "") ?: ""
        val value = widgetData.getString("lvl_value", "") ?: ""
        val note = widgetData.getString("lvl_note", "") ?: ""
        val path = widgetData.getString("lvl_image", null)
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_level)
            v.setTextViewText(R.id.title, if (hidden || title.isEmpty()) "Lunera" else title)
            v.setTextViewText(R.id.value, if (hidden) "" else value)
            v.setTextViewText(R.id.note, if (hidden) "Detail disembunyikan" else note.ifEmpty { "Catat dosis atau hasil lab untuk melihat grafik" })
            val bmp = if (!hidden && !path.isNullOrEmpty() && File(path).exists()) BitmapFactory.decodeFile(path) else null
            if (bmp != null) {
                v.setImageViewBitmap(R.id.chart, bmp)
                v.setViewVisibility(R.id.chart, View.VISIBLE)
            } else {
                v.setViewVisibility(R.id.chart, View.GONE)
            }
            v.setOnClickPendingIntent(R.id.root, launchIntent(context))
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}
