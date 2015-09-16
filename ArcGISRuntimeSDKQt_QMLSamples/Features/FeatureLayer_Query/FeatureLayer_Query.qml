// Copyright 2015 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.2
import Esri.ArcGISRuntime 100.00
import Esri.ArcGISExtras 1.1

Rectangle {
    width: 800
    height: 600

    property real scaleFactor: System.displayScaleFactor

    // Map view UI presentation at top
    MapView {
        id: mapView

        anchors.fill: parent

        Map {
            id: map

            BasemapTopographic {}
            initialViewpoint: viewPoint

            FeatureLayer {
                id: featureLayer

                // default property (renderer)
                SimpleRenderer {
                    SimpleFillSymbol {
                        style: Enums.SimpleFillSymbolStyleSolid
                        color: "#F2F5A9"
                        opacity: 0.6

                        // default property (outline)
                        SimpleLineSymbol {
                            style: Enums.SimpleLineSymbolStyleSolid
                            color: "black"
                            width: 2.0 * scaleFactor
                            antiAlias: true
                            opacity: 1.0
                        }
                    }
                }

                // feature table
                ServiceFeatureTable {
                    id: featureTable
                    url: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer/2"

                    onQueryFeaturesStatusChanged: {
                        if (queryFeaturesStatus === Enums.TaskStatusCompleted) {
                            if (!queryFeaturesResult.iterator.hasNext) {
                                errorMsgDialog.visible = true;
                                return;
                            }

                            // clear any previous selection
                            featureLayer.clearSelection();
                            // get the first feature
                            var feature = queryFeaturesResult.iterator.next();
                            // select the first feature.
                            // The ideal way to select features is to call featureLayer.selectFeaturesWithQuery(), which will
                            // automatically select the features based on your query.  This is just a way to show you operations
                            // that you can do with query results. Refer to API doc for more details.
                            featureLayer.selectFeature(feature);

                            // zoom to the first feature
                            mapView.setViewpointGeometryAndPadding(feature.geometry, 200);
                        }
                    }
                }
            }
        }

        // initial viewPoint
        ViewpointCenter {
            id: viewPoint
            center: Point {
                x: -11e6
                y: 5e6
                spatialReference: SpatialReference {
                    wkid: 102100
                }
            }
            scale: 9e7
        }

        QueryParameters {
            id: params
            outFields: ["*"]
        }

        Row {
            id: findRow

            anchors {
                top: parent.top
                bottom: map.top
                left: parent.left
                right: parent.right
                margins: 5
            }
            spacing: 5

            TextField {
                id: findText

                width: parent.width * 0.25
                placeholderText: "Enter a state name to select"
                Keys.onReturnPressed: {
                    query();
                }
            }

            Button {
                text: "Find and Select"
                enabled: featureTable.loadStatus === Enums.LoadStatusLoaded
                onClicked: {
                    query();
                }
            }
        }

        // error message dialog
        MessageDialog {
            id: errorMsgDialog
            visible: false
            text: "No state named " + findText.text.toUpperCase() + " exists."
            onAccepted: {
                visible = false;
            }
        }
    }

    // Neatline rectangle
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border {
            width: 0.5 * scaleFactor
            color: "black"
        }
    }

    // function to form and execute the query
    function query() {
        // set the where clause
        params.whereClause = "STATE_NAME LIKE \'" + findText.text.toUpperCase() + "\'";

        // start the query
        featureTable.queryFeatures(params);
    }
}