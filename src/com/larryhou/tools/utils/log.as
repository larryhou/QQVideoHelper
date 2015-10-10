package com.larryhou.tools.utils
{
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.sendToURL;
	
	/**
	 * 
	 * @author larryhou
	 * @createTime Oct 9, 2015 1:39:54 PM
	 */
	public function log(msg:String, append:Boolean = true):void
	{
		var request:URLRequest = new URLRequest(GATEWAY + "&append=" + int(append));
		request.method = URLRequestMethod.POST;
		request.data = msg;
		sendToURL(request);
	}
}

import com.larryhou.tools.utils.timestamp;

const GATEWAY:String = "http://localhost:8080/flashlog.php?name=QQV-" + timestamp();