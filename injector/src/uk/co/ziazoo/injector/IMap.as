package uk.co.ziazoo.injector
{
	public interface IMap
	{
		function get provider():Class;
		function get clazz():Class;
		function get clazzName():String;
	}
}