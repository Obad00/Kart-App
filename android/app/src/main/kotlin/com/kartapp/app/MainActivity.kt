package com.kartapp.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.ContactsContract.CommonDataKinds.Phone
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Sélecteur de contact système pour « Ajouter depuis mes contacts »
 * (invitations d'événements). Aucune permission Contacts : l'application
 * Contacts renvoie le numéro choisi avec un accès temporaire à cette seule
 * ligne (règle Google Play « Contacts Permissions »). Sur Android 17, le
 * système remplace ACTION_PICK par son nouveau sélecteur.
 */
class MainActivity : FlutterActivity() {
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "pickPhone") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (pendingPick != null) {
                result.error("ALREADY_ACTIVE", "Un sélecteur est déjà ouvert.", null)
                return@setMethodCallHandler
            }
            pendingPick = result
            try {
                startActivityForResult(Intent(Intent.ACTION_PICK, Phone.CONTENT_URI), PICK_PHONE)
            } catch (e: ActivityNotFoundException) {
                pendingPick = null
                result.error("NO_PICKER", "Aucune application Contacts sur ce téléphone.", null)
            }
        }
    }

    // FlutterActivity hérite d'Activity (pas de ComponentActivity) : pas
    // d'API Activity Result, d'où startActivityForResult / onActivityResult.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_PHONE) return
        val result = pendingPick ?: return
        pendingPick = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null) // Retour : fin de la sélection.
            return
        }
        try {
            contentResolver.query(
                uri,
                arrayOf(Phone.DISPLAY_NAME, Phone.NUMBER, Phone.TYPE, Phone.LABEL),
                null, null, null,
            )?.use { cursor ->
                if (!cursor.moveToFirst()) {
                    result.success(null)
                    return
                }
                val type = cursor.getInt(2)
                result.success(
                    mapOf(
                        "name" to (cursor.getString(0) ?: ""),
                        "number" to (cursor.getString(1) ?: ""),
                        "label" to label(type, cursor.getString(3)),
                    )
                )
            } ?: result.success(null)
        } catch (e: Exception) {
            result.error("READ_FAILED", "Le contact choisi n'a pas pu être lu.", null)
        }
    }

    private fun label(type: Int, custom: String?): String = when (type) {
        Phone.TYPE_MOBILE -> "Mobile"
        Phone.TYPE_WORK_MOBILE -> "Mobile pro"
        Phone.TYPE_HOME -> "Domicile"
        Phone.TYPE_WORK -> "Travail"
        Phone.TYPE_MAIN -> "Principal"
        Phone.TYPE_CUSTOM -> custom?.takeIf { it.isNotBlank() } ?: "Autre"
        else -> "Autre"
    }

    companion object {
        private const val CHANNEL = "kart/contact_picker"
        private const val PICK_PHONE = 4271
    }
}
