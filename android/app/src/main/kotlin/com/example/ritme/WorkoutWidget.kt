package com.example.ritme

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/** 2x2 Android Home Screen Widget for Lunera's HRT-aware Movement Coach. */
class WorkoutWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val lang = appLang(widgetData)
        val id = lang == "id"
        val hidden = widgetData.getString("widget_hidden", "0") == "1"

        val badge = widgetData.getString("wrk_badge", null) ?: ""
        val title = widgetData.getString("wrk_title", null) ?: ""
        val sub = widgetData.getString("wrk_sub", null) ?: ""
        val mood = widgetData.getString("wrk_mood", "greet") ?: "greet"
        val resting = widgetData.getString("wrk_resting", "0") == "1"

        val mascotRes = when (mood) {
            "care", "rest", "gentle" -> R.drawable.coach_care
            "cheer", "ready", "stretch" -> R.drawable.coach_cheer
            "celebrate", "proud" -> R.drawable.coach_celebrate
            else -> R.drawable.coach_greet
        }

        val startLabel = if (id) "Mulai" else "Start"
        val restLabel = if (resting) (if (id) "Lanjut" else "Resume") else (if (id) "Istirahat" else "Rest")

        for (wid in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_workout)

            if (hidden) {
                v.setViewVisibility(R.id.coach_img, View.GONE)
                v.setViewVisibility(R.id.badge, View.GONE)
                v.setViewVisibility(R.id.actions_row, View.GONE)
                v.setTextViewText(R.id.title, "Lunera")
                v.setTextViewText(R.id.subtitle, if (id) "Ketuk untuk membuka" else "Tap to open")
                v.setOnClickPendingIntent(R.id.root, launchIntent(context))
            } else {
                v.setViewVisibility(R.id.coach_img, View.VISIBLE)
                v.setImageViewResource(R.id.coach_img, mascotRes)

                if (badge.isNotEmpty()) {
                    v.setViewVisibility(R.id.badge, View.VISIBLE)
                    v.setTextViewText(R.id.badge, badge)
                } else {
                    v.setViewVisibility(R.id.badge, View.GONE)
                }

                v.setTextViewText(
                    R.id.title,
                    if (title.isNotEmpty()) title else (if (id) "Pelatih Gerak" else "Movement Coach"),
                )
                v.setTextViewText(
                    R.id.subtitle,
                    if (sub.isNotEmpty()) sub else (if (id) "Siap kapan pun kamu mau" else "Ready whenever you are"),
                )

                v.setViewVisibility(R.id.actions_row, View.VISIBLE)
                v.setTextViewText(R.id.btn_start, startLabel)
                v.setTextViewText(R.id.btn_rest, restLabel)

                v.setOnClickPendingIntent(
                    R.id.root,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("lunera://workout/coach"),
                    ),
                )
                v.setOnClickPendingIntent(
                    R.id.btn_start,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("lunera://workout/start"),
                    ),
                )
                v.setOnClickPendingIntent(
                    R.id.btn_rest,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("lunera://workout/rest"),
                    ),
                )
            }

            appWidgetManager.updateAppWidget(wid, v)
        }
    }
}
