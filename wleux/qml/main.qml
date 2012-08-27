/** Wleux : Wallpaper downloader from desktoppr.co for MeeGo Harmattan
 * Copyright (c) 2012 Benoit HERVIER <khertan@khertan.net>
 * Licenced under GPLv3
 *
 * An idea base on mustr : Pattern downloader from COLOURlovers.com for MeeGo Harmattan
 * By Copyright (C) 2012  Thomas Perl
 * Heavy copy paste of the qml source
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation; version 3 only.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 **/

import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.0

PageStackWindow {
    initialPage: Page {
        orientationLock: PageOrientation.LockPortrait

        tools: ToolBarLayout {
            ButtonRow {
                anchors.left: parent.left
                style: TabButtonStyle { }
            }
            ToolIcon {
                anchors.right: parent.right
                iconId: 'toolbar-view-menu'
                onClicked: contextMenu.open()
            }
        }

        ContextMenu {
            id: contextMenu

            MenuLayout {                
                MenuItem {
                    text: 'About Wleux'
                    onClicked: pushAbout()
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            platformStyle: BusyIndicatorStyle { size: "large" }
            running: visible
            visible: wallpapersModel.running
        }

        ListView {
            id: listView
            property int imageItemHeight: 150
            width: parent.width
            visible: wallpapersModel.running ? false : true
            header: Item {
                height: wallpapersModel.previouspage == 0 ? 0 : listView.imageItemHeight
                width: parent.width

                Button {
                    id: lastPage
                    anchors.centerIn: parent
                    text: 'Previous page'
                    onClicked: wallpapersModel.loadPage(wallpapersModel.previousPage)
                    visible: wallpapersModel.previouspage > 0
                    width: parent.width * .5                    
                }
            }

            footer: Item {
                height: listView.imageItemHeight
                width: parent.width

                Button {
                    id: nextPage
                    anchors.centerIn: parent
                    text: 'Next page'
                    onClicked: wallpapersModel.loadPage(wallpapersModel.nextpage)
                    width: parent.width * .5
                    visible: wallpapersModel.nextpage > 0
                }
            }

            anchors.fill: parent
            model: wallpapersModel

            delegate: Item {
                width: parent.width
                height: listView.imageItemHeight

                Image {
                    clip: true
                    anchors.fill: parent
                    anchors.margins: mouseArea.pressed?10:0
                    fillMode: Image.PreserveAspectCrop

                    Behavior on anchors.margins {
                        PropertyAnimation {
                            duration: 100
                        }
                    }

                    source: thumb

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: {
                            previewPage.title = title;
                            //Not yet available
                            //previewPage.username = username;
                            previewPage.website = url;
                            previewPage.url = url;
                            //previewPage.url = url;
                            pageStack.push(previewPage);
                        }
                    }

                    Rectangle {
                        anchors {
                            right: parent.right
                            bottom: parent.bottom
                            margins: -10
                        }
                        width: credits.width + 20
                        height: credits.height + 20

                        color: '#80000000'
                        radius: 10

                        Label {
                            id: credits
                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                                margins: 15
                            }
                            //User not yet available in api
                            //text: ' ' + title + ' by ' + username
                            text: ' ' + title
                        }
                    }

                    BusyIndicator {
                        anchors.centerIn: parent
                        visible: parent.status === Image.Loading
                        running: visible
                    }
                }
            }
        }

        ScrollDecorator {
            flickableItem: listView
        }
    }

    Page {
        id: previewPage

        orientationLock: PageOrientation.LockPortrait

        tools: ToolBarLayout {
            ToolIcon {
                iconId: 'toolbar-back'
                onClicked: pageStack.pop()
            }
        }

        property string title: ''
        property string username: ''
        property string website: ''
        property string url: ''

        Flickable {
            id: flicker

            anchors.fill: parent
            contentWidth: img.paintedWidth
            contentHeight: 854
            flickableDirection: Flickable.HorizontalFlick
            visible: !busyIndicator.visible
            Image {
                id:img
                fillMode: Image.PreserveAspectFit
                source: previewPage.url
                sourceSize.height: 854
                height: 854
                
                smooth: true

            }
        }


        BusyIndicator {
            id: busyIndicator
            anchors.centerIn: flicker
            visible: img.status === Image.Loading
            platformStyle: BusyIndicatorStyle { size: "large" }
            running: visible
        }   
                
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }

            color: '#80000000'

            height: previewColumn.height + 2*previewColumn.anchors.margins

            Column {
                id: previewColumn

                anchors {
                    margins: 20
                    top: parent.top
                    left: parent.left
                }

                width: parent.width

                Label {
                    text: previewPage.title
                    font.bold: true
                    font.pixelSize: 30
                }

                //User not yet available in api
                //Label {
                //    text: 'by ' + previewPage.username
                //}
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Qt.openUrlExternally(previewPage.website)
            }
        }

        Button {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                margins: 20
            }

            text: 'Use as wallpaper'
            width: parent.width * .7
            onClicked: wallpaper.setWallpaper(previewPage.website, flicker.contentX, img.paintedWidth )
            BusyIndicator {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 20
                visible: wallpaper.running
                running: visible
                }
        }

        InfoBanner {
            id: infoBanner
            text: 'Wallpaper was successfully set.'
        }

        Connections {
            target: wallpaper
            onDone: infoBanner.show()
        }
    }

    function pushAbout() {
        pageStack.push(Qt.createComponent(Qt.resolvedUrl("components/AboutPage.qml")),
             {
                          title : 'Wleux ' + __version__,
                          iconSource: Qt.resolvedUrl('../icons/wleux.png'),
                          slogan : 'Because patterns are boring !',
                          text : 
                             'A nice looking wallpaper setting application.' +
                             '\nWeb Site : http://khertan.net/Wleux' +
                             '\n\nBy Benoît HERVIER (Khertan)' +
                             '\nLicenced under GPLv3' +
                             '\nWallpapers by desktoppr.co'+
                             '\n\nDerivated and Inspired by\nThomas Perl\'s "Mustr" app' +
                             '\nhttp://thp.io/2012/mustr/' + 
                             '\nwhich was inspired by Lucas Rocha\'s "Pattrn" app' +
                             '\nMustr Tab support by Seppo Tomperi' +
                             '\n\nThanks to : ' +
                             '\nThomas Perl' +
                             '\nThe team running desktoppr.co' +
                             '\nFaenil on #harmattan'
             }
             );
    }
    
 
 
    function onError(errMsg) {
        errorEditBanner.text = errMsg;
        errorEditBanner.show();
    }

    InfoBanner{
                      id:errorEditBanner
                      text: ''
                      timerShowTime: 15000
                      timerEnabled:true
                      anchors.top: parent.top
                      anchors.topMargin: 60
                      anchors.horizontalCenter: parent.horizontalCenter
                 }


    Component.onCompleted: theme.inverted = true
}

