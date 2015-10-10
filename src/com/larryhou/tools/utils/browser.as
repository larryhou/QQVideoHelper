package com.larryhou.tools.utils
{
	import flash.external.ExternalInterface;
	
	/**
	 * 
	 * @author larryhou
	 * @createTime Oct 10, 2015 12:19:25 AM
	 */
	public class browser
	{
		static public function log(msg:String):void
		{
			if (ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call("console.log", msg);
				} 
				catch(error:Error) {}
			}
		}
		
		static public function notify(msg:String):void
		{
			if (ExternalInterface.available)
			{
				ExternalInterface.call('function(){if (Notification.permission != "granted"){Notification.requestPermission()};new Notification("' + msg + '");}');
			}
		}
	}
}