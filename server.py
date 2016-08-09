#!/usr/bin/python

import SimpleHTTPServer
import SocketServer
import logging
import cgi
import os
import urllib


class ServerHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):

    def do_GET(self):
        logging.warning("======= GET STARTED =======")
        logging.warning(self.headers)
        SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self)

    def do_POST(self):
        #length = int(self.headers['Content-Length'])
        #post_data = urllib.parse.parse_qs(self.rfile.read(length).decode('utf-8'))
        #print(post_data)
	content_len = int(self.headers.getheader('content-length', 0))
	post_body = self.rfile.read(content_len)
        data = post_body.strip()
	if 'http://www.appmybox.com/mobile/' in post_body:
		data = post_body.strip()[-4:]
	print(data)
	os.system('osascript -e \'tell app "System Events" to keystroke "' + chr(126) + chr(27) + data + '"\'')
	os.system('osascript -e \'tell app "System Events" to keystroke return\'')

Handler = ServerHandler

httpd = SocketServer.TCPServer(("", 8000), Handler)

httpd.serve_forever()
