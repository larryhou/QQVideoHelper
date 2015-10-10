package com.larryhou.tools
{
	import com.larryhou.tools.data.VideoClipInfo;
	import com.larryhou.tools.utils.browser;
	import com.larryhou.tools.utils.log;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.sendToURL;
	import flash.system.ApplicationDomain;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	import avmplus.getQualifiedClassName;
	
	
	/**
	 * 
	 * @author larryhou
	 * @createTime Oct 9, 2015 11:32:49 AM
	 */
	public class QQVideoHelper extends Sprite
	{
		private var domain:ApplicationDomain;
		private var params:Object;
		private var globalvars:Object;
		private var tvinfo:Object;
		
		private var libv:Object;
		private var clips:Vector.<VideoClipInfo>;
		
		private var tvName:String;
		private var episodeName:String;
		
		private var stdfrom:String;
		private var mp4urls:Vector.<String>;
		
		/**
		 * 构造函数
		 * create a [QQVideoHelper] object
		 */
		public function QQVideoHelper()
		{
			browser.log("#i: " + getTimer());
			
			params = {};
			mp4urls = new Vector.<String>();
			addEventListener("allComplete", allCompleteHandler);
		}
		
		private function allCompleteHandler(e:Event):void
		{
			removeEventListener("allComplete", arguments.callee);
			
			var info:LoaderInfo = e.target as LoaderInfo;
			domain = info.applicationDomain;
			
			browser.log("#1: " + info.url);
			browser.log(getQualifiedClassName(info.content));
			if (info.url.indexOf("player/TencentPlayer.swf") <= 0) return;
			if (ExternalInterface.call("function(){return window.trap}") == 1) return;
			ExternalInterface.call("function(){window.trap = 1}");
			
			globalvars = domain.getDefinition("com.tencent.tpv3.model::GlobalVars");
			
			log(info.url);
			log("flashvars = " + JSON.stringify(info.parameters));
			log("globalvars = " + JSON.stringify(getGlobalVars()));
			
			var title:String = info.parameters.title;
			
			tvName = title.split(/\s+/g).shift();
			episodeName = title.split(/\s+/g).pop();
			
			params.vid = info.parameters.vid;
			params.vids = info.parameters.vid;
			params.otype = "json";
			params.defnpayver = 1;
			params.platform = globalvars.playerPlatform;
			params.charge = 0;
			params.ran = Math.random();
			params.speed = 4000;
			params.pid = createGuid();
			params.appver = domain.getDefinition("com.tencent.tpv3.utils::PlayerUtils").versionNo;
			params.fhdswitch = 0;
			params.guid = createGuid();
			params.ehost = ExternalInterface.call("eval", "location.href");
			params.utype = ExternalInterface.call("__tenplay_getuinfo");
			params.fp2p = 1;
			params.defaultfmt = "fhd";
			params.defn = "fhd";
			
			libv = domain.getDefinition("com.tencent.tpv3.module::KlibV2").getInstance();
			libv.addEventListener("klib_ckey", ckeyCompleteHandler);
			libv.currData = {changeurl:0};
			libv.loadKey(params.vid, globalvars.playerPlatform, params.appver, false, globalvars.playerversion);
		}
		
		private function ckeyCompleteHandler(e:Event):void
		{
			libv.removeEventListener(e.type, arguments.callee);
			browser.log("#2: ckeyComplete");
			
			params.ran = Math.random();
			params.cKey = libv.currCk;
			params.encryptVer = libv.currEver;
			
			log("params = " + JSON.stringify(params));
			
			var data:URLVariables = new URLVariables();
			for (var key:String in params)
			{
				data[key] = params[key];
			}
			
			var request:URLRequest = new URLRequest(globalvars.cgi_get_videoinfo);
			request.method = URLRequestMethod.POST;
			request.data = data;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, infoCompleteHandler);
			loader.load(request);
		}
		
		private function stripJSON(data:String):String
		{
			return data.replace(/^[^\{\[=]+=/, "").replace(/;$/, "");
		}
		
		private function infoCompleteHandler(e:Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			loader.removeEventListener(e.type, arguments.callee);
			browser.log("#3: infoComplete");
			
			var jsonObj:String = stripJSON(loader.data);
			log("tvinfo = " + jsonObj);
			
			tvinfo = JSON.parse(jsonObj);
			
			var cache:Object = params;
			
			params = {};
			params.otype = cache.otype;
			params.platform = globalvars.playerPlatform;
			params.appver = cache.appver;
			params.charge = cache.charge;
			params.vid = cache.vid;
			params.ran = Math.random();
			params.guid = cache.guid;
			params.ehost = cache.ehost;
			params.format = 10209;//globalvars.currformat;
			
			params.buffer = 0;
			params.dltype = 1;
			params.fmt = cache.defn;
			params.ltime = 0;
			params.speed = 1000 + 3000 * Math.random() >> 0;
			
			var vi:Object = tvinfo.vl.vi[0];
			var ui:Object = vi.ul.ui[0];
			params.vt = ui.vt;
			
			stdfrom = domain.getDefinition("com.tencent.tpv3.utils::SdtFromGetter").getSdtFrom(globalvars.usingHost,
				globalvars.p2pStreamType == domain.getDefinition("com.tencent.tpv3.managers::StreamFactory").STREAMTYPE_NATIVE,
				globalvars.ptag);
			clips = new Vector.<VideoClipInfo>();
			
			var vclip:VideoClipInfo;
			if (vi.cl && vi.cl.ci && !isNaN(Number(vi.cl.fc)) && Number(vi.cl.fc) > 0)
			{
				var cis:Array = vi.cl.ci;
				for (var i:int = 0; i < cis.length; i++)
				{
					var item:Object = cis[i];
					vclip = new VideoClipInfo();
					vclip.index = item.idx;
					vclip.duration = item.cd;
					vclip.bytesTotal = item.cs;
					vclip.key = item.keyid;
					vclip.fileName = vi.fn.replace(/(\.[^.]+)$/, "." + vclip.index + "$1");
					vclip.url = ui.url;
					clips.push(vclip);
				}
			}
			else
			{
				vclip = new VideoClipInfo();
				vclip.index = 1;
				vclip.duration = vi.td;
				vclip.bytesTotal = vi.fs;
				vclip.fileName = vi.fn;
				vclip.key = vi.fvkey;
				vclip.url = ui.url;
				clips.push(vclip);
			}
			
			parseClipInfo(clips[0]);
		}
		
		private function parseClipInfo(clip:VideoClipInfo):void
		{
			params.idx = clip.index;
			
			libv = domain.getDefinition("com.tencent.tpv3.module::KlibV2").getInstance();
			libv.addEventListener("klib_ckey", newCkeyCompleteHandler);
			libv.currData = {changeurl:0};
			libv.loadKey(params.vid, globalvars.playerPlatform, params.appver, false, globalvars.playerversion);
		}
		
		private function newCkeyCompleteHandler(e:Event):void
		{
			libv.removeEventListener(e.type, arguments.callee);
			browser.log("#4: ckeyComplete -> " + clips[0].index);
			
			params.ran = Math.random();
			params.cKey = libv.currCk;
			params.encryptVer = libv.currEver;
			
			var data:URLVariables = new URLVariables();
			for (var key:String in params)
			{
				data[key] = params[key];
			}
			
			var request:URLRequest = new URLRequest(globalvars.cgi_get_videoclip);
			request.method = URLRequestMethod.POST;
			request.data = data;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.COMPLETE, clipInfoCompleteHandler);
			loader.load(request);
		}
		
		private function clipInfoCompleteHandler(e:Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			loader.removeEventListener(e.type, arguments.callee);
			
			browser.log("#5: clipInfoComplete -> " + clips[0].index + "@" + getTimer());
			
			var jsonObj:String = stripJSON(loader.data);
			log("clip#" + clips[0].index + " = " + jsonObj);
			
			var vinfo:Object = JSON.parse(jsonObj);
			if (vinfo.s == "f")
			{
				browser.notify(vinfo.em + ": " + vinfo.msg);
				return;
			}
			
			var data:URLVariables = new URLVariables();
			data.stdfrom = stdfrom;
			data.type = "mp4";
			data.vkey = vinfo.vi.key;
			data.level = vinfo.level;
			data.platform = params.platform;
			data.br = vinfo.vi.br;
			data.fmt = vinfo.vi.fmt;
			data.sp = vinfo.sp;
			data.guid = params.guid;
			data.size = vinfo.vi.fs;
			
			var url:String = clips[0].url + vinfo.vi.fn + "?" + data.toString();
			mp4urls.push(url);
			browser.log(url);
			
			clips.shift();
			if (clips.length)
			{
				parseClipInfo(clips[0]);
			}
			else
			{
				uploadResult(mp4urls.join("\n"));
			}
		}
		
		private function uploadResult(data:String):void
		{
			var gateway:String = "http://localhost:8080/qqtv.php?tv=" + tvName + "&episode=" + episodeName;
			var request:URLRequest = new URLRequest(encodeURI(gateway));
			request.method = URLRequestMethod.POST;
			request.data = data;
			
			var uploader:URLLoader = new URLLoader();
			uploader.dataFormat = URLLoaderDataFormat.TEXT;
			uploader.addEventListener(Event.COMPLETE, uploadCompleteHandler);
			uploader.load(request);
		}
		
		private function uploadCompleteHandler(e:Event):void
		{
			var uploader:URLLoader = e.currentTarget as URLLoader;
			uploader.removeEventListener(e.type, arguments.callee);
			
			browser.log("#6: uploadComplete");
			browser.notify("解析并上传成功：" + tvName + " - " + episodeName);
		}
		
		private function createGuid():String
		{
			return domain.getDefinition("com.koma.utils::Guid").create();
		}
		
		private function getGlobalVars():Object
		{
			var data:Object = {};
			var config:XML = describeType(globalvars);
			for each(var node:XML in config.variable)
			{
				var name:String = node.@name;
				data[name] = globalvars[name];
			}
			return data;
		}
	}
}