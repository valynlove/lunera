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

/** Lama terapi dalam satu satuan terbesar: tahun, bulan, minggu, atau hari. */
fun durationText(startIso: String): String {
    val today = LocalDate.now()
    val start = LocalDate.parse(startIso.take(10))
    if (!start.isBefore(today)) return "0 hari"
    val p = Period.between(start, today)
    return when {
        p.years >= 1 -> "${p.years} tahun"
        p.months >= 1 -> "${p.months} bulan"
        else -> {
            val d = ChronoUnit.DAYS.between(start, today).toInt()
            if (d >= 7) "${d / 7} minggu" else "$d hari"
        }
    }
}

/** Kapan jadwal tiba, dihitung saat widget digambar supaya selalu segar. */
fun whenText(atMs: Long): String {
    val at = Instant.ofEpochMilli(atMs).atZone(ZoneId.systemDefault()).toLocalDateTime()
    val days = ChronoUnit.DAYS.between(LocalDate.now(), at.toLocalDate()).toInt()
    val hm = "%02d:%02d".format(at.hour, at.minute)
    return when {
        days < 0 -> "Terlambat ${-days} hari"
        days == 0 -> "Hari ini, $hm"
        days == 1 -> "Besok, $hm"
        else -> "$days hari lagi"
    }
}
