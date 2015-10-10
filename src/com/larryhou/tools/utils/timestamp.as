package com.larryhou.tools.utils
{
	
	/**
	 * 
	 * @author larryhou
	 * @createTime Oct 9, 2015 1:41:59 PM
	 */
	public function timestamp():String
	{
		var date:Date = new Date();
		return date.fullYear + "_" + padding(date.month + 1) + "_" + padding(date.date) + "-"
			+ padding(date.hours) + "-" + padding(date.minutes) + "-" + padding(date.seconds);
	}
}

function padding(value:*, length:uint = 2):String
{
	var result:String = String(value);
	while (result.length < length)
	{
		result = "0" + result;
	}
	
	return result;
}