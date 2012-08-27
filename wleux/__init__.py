#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2011 Benoit HERVIER <khertan@khertan.net>
# Licenced under GPLv3

## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published
## by the Free Software Foundation; version 3 only.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

from PySide.QtGui import QApplication, QImage
from PySide.QtCore import QUrl, Slot, QObject, \
                          QAbstractListModel, QModelIndex, \
                          Signal, Property, Qt
from PySide import QtDeclarative
from PySide.QtOpenGL import QGLWidget

import sys
import os
import os.path

import json
import urllib2
import threading

__author__ = 'Benoit HERVIER (Khertan)'
__email__ = 'khertan@khertan.net'
__version__ = '1.1'

GCONFKEY = '/desktop/meego/background/portrait/picture_filename'
WALLPATH = '/home/user/.config/wleux_wallpaper.png'

class Wallpaper(QObject):
    def __init__(self, ):
        QObject.__init__(self)
        self._running = False

    @Slot(unicode, int, int)
    def setWallpaper(self, url, offset, width):
        self._set_running(True)
        self.thread = threading.Thread(target=self._setWallpaper, \
                                        args=(url, offset, width))
        self.thread.start()

    def _setWallpaper(self, url, offset, width):
        inStream = urllib2.urlopen(url)
        img = QImage.fromData(inStream.read())
        img = img.scaledToHeight(854,Qt.SmoothTransformation)
        #offset = int(img.width() / 2) - 240
        print 'offset:', offset, 'img.width', img.width(), 'width', width
        img = img.copy(offset, 0, 480, 854)
        img.save(WALLPATH)

        #Set in gconf
        import gconf
        gclient = gconf.client_get_default()
        gclient.set_string(GCONFKEY, '')
        gclient.set_string(GCONFKEY, \
                           WALLPATH)
        #Emit done signal
        self._set_running(False)
        self.done.emit()

    def _get_running(self):
        return self._running

    def _set_running(self, b):
        self._running = b
        self.on_running.emit()


    done = Signal()
    on_running = Signal()
    running = Property(bool, _get_running, _set_running, notify=on_running)

class WallpapersModel(QAbstractListModel):
    COLUMNS = ('id', 'preview', 'url', 'thumb', 'user-id', 'title', 'username')

    def __init__(self, ):
        self._wallpapers = None
        self._currentpage = 1
        self._running = False
        self._previouspage = 0
        self._nextpage = 0
        QAbstractListModel.__init__(self)
        self.setRoleNames(dict(enumerate(WallpapersModel.COLUMNS)))
        self.loadPage(1)

    def loadData(self,):
        try:
            self._wallpapers = json.load(urllib2.urlopen( \
                'https://api.desktoppr.co/1/wallpapers?page=%s' \
                % self._currentpage))
        except Exception, err:
            self.on_error.emit(unicode(err))
            print err

        self._previouspage = self._wallpapers['pagination']['previous']
        self._nextpage = self._wallpapers['pagination']['next']
        if self._nextpage == None:
            self._nextpage = 0
        if self._previouspage == None:
            self._previouspage = 0

        self.on_nextpage.emit()
        self.on_previouspage.emit()

    def rowCount(self, parent=QModelIndex()):
        try:
            return len(self._wallpapers['response'])
        except TypeError:
            return 0

    def data(self, index, role):
        try:
            if role == WallpapersModel.COLUMNS.index('id'):
                return self._wallpapers['response'][index.row()]['id']
            elif role == WallpapersModel.COLUMNS.index('preview'):
                return self._wallpapers['response'][index.row()] \
                       ['image']['preview']['url']
            elif role == WallpapersModel.COLUMNS.index('url'):
                return self._wallpapers['response'][index.row()] \
                       ['image']['url']
            elif role == WallpapersModel.COLUMNS.index('thumb'):
                return self._wallpapers['response'][index.row()] \
                       ['image']['thumb']['url']
            elif role == WallpapersModel.COLUMNS.index('user-id'):
                return self._wallpapers['response'][index.row()]['user_id']
            elif role == WallpapersModel.COLUMNS.index('username'):
                return self._wallpapers['response'][index.row()]['user_id']
            elif role == WallpapersModel.COLUMNS.index('title'):
                return os.path.basename(self._wallpapers['response'] \
                       [index.row()]['image']['url'])
            return None
        except (KeyError, TypeError):
            return None

    @Slot(int)
    def loadPage(self,pageNum):
        self._currentpage = pageNum
        self._set_running(True)
        self.thread = threading.Thread(target=self.reload)
        self.thread.start()

    def reload(self):
        self.beginResetModel()
        self.loadData()
        self.endResetModel()
        self._set_running(False)

    def _get_running(self):
        return self._running

    def _set_running(self, b):
        self._running = b
        self.on_running.emit()

    def _get_previouspage(self,):
        return self._previouspage
    def _get_nextpage(self,):
        return self._nextpage

    on_finished = Signal()
    on_error = Signal(unicode)
    on_running = Signal()
    running = Property(bool, _get_running, _set_running, notify=on_running)
    on_nextpage = Signal()
    on_previouspage = Signal()
    nextpage = Property(int, _get_nextpage, notify=on_nextpage)
    previouspage = Property(int, _get_previouspage, notify=on_previouspage)

class Wleux(QApplication):
    ''' Application class '''
    def __init__(self):
        QApplication.__init__(self, sys.argv)
        self.setOrganizationName("Khertan Software")
        self.setOrganizationDomain("khertan.net")
        self.setApplicationName("Wleux")

        self.view = QtDeclarative.QDeclarativeView()
        self.glw = QGLWidget()
        self.view.setViewport(self.glw)
        self.wallpapersModel = WallpapersModel()
        self.wallpaper = Wallpaper()
        self.rootContext = self.view.rootContext()
        self.rootContext.setContextProperty("argv", sys.argv)
        self.rootContext.setContextProperty("__version__", __version__)
        self.rootContext.setContextProperty('wallpapersModel', self.wallpapersModel)
        self.rootContext.setContextProperty('wallpaper', self.wallpaper)
        self.view.setSource(QUrl.fromLocalFile( \
                os.path.join(os.path.dirname(__file__), 'qml', 'main.qml')))
        self.rootObject = self.view.rootObject()
        self.view.showFullScreen()
        self.wallpapersModel.on_error.connect(self.rootObject.onError)

if __name__ == '__main__':
    sys.exit(Wleux().exec_())
