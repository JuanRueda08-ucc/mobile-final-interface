package com.juanrueda.monitoring_engine

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

/*
 * Prueba unitaria Kotlin de la plantilla oficial (VIG-003). El plugin no incluye app de
 * ejemplo: se ejecuta desde el proyecto Gradle de la app, en `android/`:
 *   ./gradlew :monitoring_engine:testDebugUnitTest
 */

internal class MonitoringEnginePluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = MonitoringEnginePlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }
}
