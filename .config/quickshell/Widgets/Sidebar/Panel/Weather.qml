import QtQuick 
import QtQuick.Layouts
import QtQuick.Controls
import qs.Settings
import "../../../Helpers/Weather.js" as WeatherHelper

Rectangle {
    id: weatherRoot
    width: 440
    height: 180
    color: "transparent"
    anchors.horizontalCenterOffset: -2

    property string city: Settings.settings.weatherCity !== undefined ? Settings.settings.weatherCity : ""
    property var weatherData: null
    property string errorString: ""
    property bool isVisible: false

    Component.onCompleted: {
        if (isVisible) {
            fetchCityWeather()
        }
    }

    function fetchCityWeather() {
        WeatherHelper.fetchCityWeather(city,
            function(result) {
                weatherData = result.weather;
                errorString = "";
            },
            function(err) {
                errorString = err;
            }
        );
    }

    function startWeatherFetch() {
        isVisible = true
        fetchCityWeather()
    }

    function stopWeatherFetch() {
        isVisible = false
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.surface
        radius: 18

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Current weather row
            RowLayout {
                spacing: 12
                Layout.fillWidth: true

                // Weather icon and basic info section
                RowLayout {
                    spacing: 12
                    Layout.preferredWidth: 140

                    // Weather icon
                    Text {
                        id: weatherIcon
                        text: weatherData && weatherData.current_weather ? materialSymbolForCode(weatherData.current_weather.weathercode) : "cloud"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 28
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.accentPrimary
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 2
                        RowLayout {
                            spacing: 4
                            Text {
                                text: city
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: weatherData && weatherData.timezone_abbreviation ? `(${weatherData.timezone_abbreviation})` : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                leftPadding: 2
                            }
                        }
                        Text {
                            text: weatherData && weatherData.current_weather ? ((Settings.settings.useFahrenheit !== undefined ? Settings.settings.useFahrenheit : false) ? `${Math.round(weatherData.current_weather.temperature * 9/5 + 32)}°F` : `${Math.round(weatherData.current_weather.temperature)}°C`) : ((Settings.settings.useFahrenheit !== undefined ? Settings.settings.useFahrenheit : false) ? "--°F" : "--°C")
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                }
                // Spacer to push content to the right
                Item {
                    Layout.fillWidth: true
                }
            }

            // Separator line
            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(Theme.textSecondary.g, Theme.textSecondary.g, Theme.textSecondary.b, 0.12)
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
            }

            // 5-day forecast row
            RowLayout {
                spacing: 12
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                visible: weatherData && weatherData.daily && weatherData.daily.time

                Repeater {
                    model: weatherData && weatherData.daily && weatherData.daily.time ? 5 : 0
                    delegate: ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignHCenter
                        Text {
                            // Day of the week (e.g., Mon)
                            text: Qt.formatDateTime(new Date(weatherData.daily.time[index]), "ddd")
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textSecondary
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            // Material Symbol icon
                            text: materialSymbolForCode(weatherData.daily.weathercode[index])
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Theme.accentPrimary
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            // High/low temp
                            text: weatherData && weatherData.daily ? ((Settings.settings.useFahrenheit !== undefined ? Settings.settings.useFahrenheit : false) ? `${Math.round(weatherData.daily.temperature_2m_max[index] * 9/5 + 32)}° / ${Math.round(weatherData.daily.temperature_2m_min[index] * 9/5 + 32)}°` : `${Math.round(weatherData.daily.temperature_2m_max[index])}° / ${Math.round(weatherData.daily.temperature_2m_min[index])}°`) : ((Settings.settings.useFahrenheit !== undefined ? Settings.settings.useFahrenheit : false) ? "--° / --°" : "--° / --°")
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // Error message
            Text {
                text: errorString
                color: Theme.error
                visible: errorString !== ""
                font.family: Theme.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    // Weather code to Material Symbol ligature mapping
    function materialSymbolForCode(code) {
        if (code === 0) return "sunny"; // Clear
        if (code === 1 || code === 2) return "partly_cloudy_day"; // Mainly clear/partly cloudy
        if (code === 3) return "cloud"; // Overcast
        if (code >= 45 && code <= 48) return "foggy"; // Fog
        if (code >= 51 && code <= 67) return "rainy"; // Drizzle
        if (code >= 71 && code <= 77) return "weather_snowy"; // Snow
        if (code >= 80 && code <= 82) return "rainy"; // Rain showers
        if (code >= 95 && code <= 99) return "thunderstorm"; // Thunderstorm
        return "cloud";
    }
    function weatherDescriptionForCode(code) {
        if (code === 0) return "Clear sky";
        if (code === 1) return "Mainly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 67) return "Drizzle";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Rain showers";
        if (code >= 95 && code <= 99) return "Thunderstorm";
        return "Unknown";
    }
} 