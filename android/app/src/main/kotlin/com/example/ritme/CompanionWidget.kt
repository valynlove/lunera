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

/** 2x2 interactive Android Home Screen Widget for Lunera's companion mascot. */
class CompanionWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val id = appLang(widgetData) == "id"
        val hidden = widgetData.getString("widget_hidden", "0") == "1"

        val mood = widgetData.getString("cmp_mood", "wave") ?: "wave"
        val speech = widgetData.getString("cmp_speech", null) ?: ""
        val pats = widgetData.getString("cmp_pats", "0")?.toIntOrNull() ?: 0
        val water = widgetData.getString("cmp_water", "0")?.toIntOrNull() ?: 0

        val mascotRes = when (mood) {
            "idle" -> R.drawable.companion_idle
            "happy" -> R.drawable.companion_happy
            "cheer" -> R.drawable.companion_cheer
            "love" -> R.drawable.companion_love
            "wink" -> R.drawable.companion_wink
            "laugh" -> R.drawable.companion_laugh
            "shy" -> R.drawable.companion_shy
            "care" -> R.drawable.companion_care
            "calm" -> R.drawable.companion_calm
            "sleepy" -> R.drawable.companion_sleepy
            "annoyed" -> R.drawable.companion_annoyed
            "shocked" -> R.drawable.companion_shocked
            "ponder" -> R.drawable.companion_ponder
            else -> R.drawable.companion_wave
        }

        val defaultSpeech = if (id) {
            "Hai! Ketuk aku kalau lagi gabut ✨"
        } else {
            "Hey! Tap me whenever you want some company ✨"
        }
        val patLabel = if (id) "Elus" else "Pat"
        val talkLabel = if (id) "Sapa" else "Chat"

        for (wid in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_companion)

            if (hidden) {
                v.setViewVisibility(R.id.companion_pats, View.GONE)
                v.setViewVisibility(R.id.companion_img, View.GONE)
                v.setViewVisibility(R.id.actions_row, View.GONE)
                v.setTextViewText(R.id.companion_name, "Lunera")
                v.setTextViewText(
                    R.id.companion_speech,
                    if (id) "Ketuk untuk membuka" else "Tap to open",
                )
                v.setOnClickPendingIntent(R.id.root, launchIntent(context))
            } else {
                v.setViewVisibility(R.id.companion_pats, View.VISIBLE)
                v.setViewVisibility(R.id.companion_img, View.VISIBLE)
                v.setViewVisibility(R.id.actions_row, View.VISIBLE)

                v.setTextViewText(R.id.companion_name, "Lunera")
                v.setTextViewText(
                    R.id.companion_pats,
                    if (water > 0) "♥ $pats · 💧$water" else "♥ $pats",
                )
                v.setTextViewText(
                    R.id.companion_speech,
                    if (speech.isNotEmpty()) speech else defaultSpeech,
                )
                v.setImageViewResource(R.id.companion_img, mascotRes)
                v.setTextViewText(R.id.btn_pat, patLabel)
                v.setTextViewText(R.id.btn_talk, talkLabel)

                v.setOnClickPendingIntent(
                    R.id.root,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("lunera://companion/open"),
                    ),
                )
                v.setOnClickPendingIntent(
                    R.id.companion_img,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("lunera://companion/poke"),
                    ),
                )
                v.setOnClickPendingIntent(
                    R.id.btn_pat,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("lunera://companion/pat"),
                    ),
                )
                v.setOnClickPendingIntent(
                    R.id.btn_talk,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("lunera://companion/talk"),
                    ),
                )
                v.setOnClickPendingIntent(
                    R.id.companion_pats,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("lunera://companion/water"),
                    ),
                )
            }

            appWidgetManager.updateAppWidget(wid, v)
        }
    }
}
