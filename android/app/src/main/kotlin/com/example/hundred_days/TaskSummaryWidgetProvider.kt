package com.hundred_days.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Base64
import android.widget.RemoteViews
import android.graphics.BitmapFactory

class TaskSummaryWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.task_summary_widget_layout)

            // Retrieve the Base64 encoded image from shared preferences
            val sharedPreferences = context.getSharedPreferences("HomeWidgetData", Context.MODE_PRIVATE)
            val taskSummaryImage = sharedPreferences.getString("task_summary_image", null)

            if (taskSummaryImage != null) {
                try {
                    val decodedImage = Base64.decode(taskSummaryImage, Base64.DEFAULT)
                    val bitmap = BitmapFactory.decodeByteArray(decodedImage, 0, decodedImage.size)

                    // Set the image to the ImageView
                    views.setImageViewBitmap(R.id.task_summary_image, bitmap)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }

            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
