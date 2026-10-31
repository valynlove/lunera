package com.example.ritme

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.time.Instant
import java.time.LocalDate
import java.time.Period
import java.time.ZoneId
import java.time.temporal.ChronoUnit

/** Ketuk widget membuka aplikasi. */
fun launchIntent(context: Context): PendingIntent {
    val i = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
    return PendingIntent.getActivity(context, 0, i, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
}

/** Bahasa aplikasi, dikirim dari Flutter ("en" atau "id"). */
fun appLang(widgetData: android.content.SharedPreferences): String = widgetData.getString("lang", "en") ?: "en"

private fun unit(n: Int, lang: String, one: String, many: String, id: String): String =
    "$n " + if (lang == "id") id else if (n == 1) one else many

/** Lama terapi dalam satu satuan terbesar: tahun, bulan, minggu, atau hari. */
fun durationText(startIso: String, lang: String): String {
    val today = LocalDate.now()
    val start = LocalDate.parse(startIso.take(10))
    if (!start.isBefore(today)) return unit(0, lang, "day", "days", "hari")
    val p = Period.between(start, today)
    return when {
        p.years >= 1 -> unit(p.years, lang, "year", "years", "tahun")
        p.months >= 1 -> unit(p.months, lang, "month", "months", "bulan")
        else -> {
            val d = ChronoUnit.DAYS.between(start, today).toInt()
            if (d >= 7) unit(d / 7, lang, "week", "weeks", "minggu") else unit(d, lang, "day", "days", "hari")
        }
    }
}

/** Kapan jadwal tiba, dihitung saat widget digambar supaya selalu segar. */
fun whenText(atMs: Long, lang: String): String {
    val id = lang == "id"
    val at = Instant.ofEpochMilli(atMs).atZone(ZoneId.systemDefault()).toLocalDateTime()
    val days = ChronoUnit.DAYS.between(LocalDate.now(), at.toLocalDate()).toInt()
    val hm = "%02d:%02d".format(at.hour, at.minute)
    return when {
        days < 0 -> if (id) "Terlambat ${-days} hari" else "${-days} ${if (days == -1) "day" else "days"} overdue"
        days == 0 -> (if (id) "Hari ini" else "Today") + ", $hm"
        days == 1 -> (if (id) "Besok" else "Tomorrow") + ", $hm"
        else -> if (id) "$days hari lagi" else "in $days days"
    }
}
