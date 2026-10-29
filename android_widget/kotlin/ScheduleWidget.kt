package com.example.ritme

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/** Widget jadwal: tiga dosis berikutnya dengan hitungan waktunya. */
class ScheduleWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val hidden = widgetData.getString("widget_hidden", "0") == "1"
        // baris, judul, sub, waktu
        val rows = arrayOf(
            intArrayOf(R.id.row0, R.id.t0, R.id.s0, R.id.w0),
            intArrayOf(R.id.row1, R.id.t1, R.id.s1, R.id.w1),
            intArrayOf(R.id.row2, R.id.t2, R.id.s2, R.id.w2),
        )
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_schedule)
            var shown = 0
            for (i in 0 until 3) {
                val title = widgetData.getString("sch_${i}_title", null)
                val atMs = widgetData.getString("sch_${i}_at", null)?.toLongOrNull()
                if (hidden || title.isNullOrEmpty() || atMs == null) {
                    v.setViewVisibility(rows[i][0], View.GONE)
                    continue
                }
                v.setViewVisibility(rows[i][0], View.VISIBLE)
                v.setTextViewText(rows[i][1], title)
                v.setTextViewText(rows[i][2], widgetData.getString("sch_${i}_sub", "") ?: "")
                v.setTextViewText(rows[i][3], whenText(atMs))
                shown++
            }
            v.setTextViewText(R.id.empty, if (hidden) "Detail disembunyikan" else "Belum ada jadwal")
            v.setViewVisibility(R.id.empty, if (shown == 0) View.VISIBLE else View.GONE)
            v.setOnClickPendingIntent(R.id.root, launchIntent(context))
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}
