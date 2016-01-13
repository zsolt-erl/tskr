#! /usr/local/bin/python
# -*- coding: utf-8 -*-

import sys
import json

import tornado.ioloop
import tornado.web

import tornadoredis
import tornadoredis.pubsub
import sockjs.tornado

import logging
logging.getLogger().setLevel(logging.DEBUG)


class RedisMessageHandler(sockjs.tornado.SockJSConnection):
    """
    SockJS connection handler.
    Note that there are no "on message" handlers - SockJSSubscriber class
    calls SockJSConnection.broadcast method to transfer messages
    to subscribed clients.
    """

    def on_open(self, request):
        subscriber.subscribe(['broadcast_channel'], self)
        self.send(json.dumps({'type': 'cmd', 'msg': 'hello leo', 'user': 'aaa'}))

    def on_close(self):
       subscriber.unsubscribe('broadcast_channel', self)


if __name__ == "__main__":

    subscriber = tornadoredis.pubsub.SockJSSubscriber(tornadoredis.Client())

    redishandler = sockjs.tornado.SockJSRouter(RedisMessageHandler, '/sockjs').urls
    statichandler = [ (r'/static/(.*)', tornado.web.StaticFileHandler, {'path': 'static'}) ]

    settings = {'debug': True}
    app = tornado.web.Application(redishandler + statichandler, **settings)
    app.listen(8888)
    tornado.ioloop.IOLoop.instance().start()

