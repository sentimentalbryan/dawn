package uk.co.ziazoo.injector
{
	public interface IMap
	{
		function get provider():Class;
		function get clazz():Class;
		function get clazzName():String;
		function set singleton( value:Boolean ):void;
		function get singleton():Boolean;
		function get providerName():String
		function provideInstance():Object;
		function addAccessor( name:String, clazzName:String ):void
		function getAccessor( clazzName:String ):String
	}
}