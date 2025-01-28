    package com.hundred_days.app

    import android.appwidget.AppWidgetManager
    import android.appwidget.AppWidgetProvider
    import android.content.Context
    import android.content.SharedPreferences
    import android.graphics.BitmapFactory
    import android.widget.RemoteViews
    import java.io.File

    class HeatMapWidgetProvider : AppWidgetProvider() {
        override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            for (appWidgetId in appWidgetIds) {
                // Get the saved image path from shared preferences
                val sharedPreferences: SharedPreferences = context.getSharedPreferences("default", Context.MODE_PRIVATE)
                val imagePath = sharedPreferences.getString("heatmap_image_path", null)
                println("Retrieved image path: $imagePath")
                
                val allPreferences = sharedPreferences.all
                println("All shared preferences: $allPreferences")

                val views = RemoteViews(context.packageName, R.layout.heatmap_widget_layout)

                if (imagePath != null) {
                    try {
                        val file = File(imagePath)
                        if (file.exists()) {
                            val bitmap = BitmapFactory.decodeFile(imagePath)
                            views.setImageViewBitmap(R.id.heatmap_image, bitmap)
                        } else {
                            println("Image file not found at: $imagePath")
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                } else {
                    println("No image path found in shared preferences")
                }

                // Update the widget
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }
