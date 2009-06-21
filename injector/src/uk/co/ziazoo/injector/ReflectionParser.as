package uk.co.ziazoo.injector
{
	import de.polygonal.ds.Iterator;
	import de.polygonal.ds.TreeIterator;
	import de.polygonal.ds.TreeNode;
	
	import flash.utils.describeType;

	public class ReflectionParser implements IMapper, IBuilder
	{
		private var _config:IMappingConfiguration;
		private var _maps:Array;
		
		public function ReflectionParser( config:IMappingConfiguration )
		{
			_config = config;
			_maps = new Array();
			_config.create( this );
		}
		
		public function map( clazz:Class, provider:Class ):IMap
		{
			var map:IMap = new Map( clazz, provider );
			_maps.push( map );
			return map;
		}
	
		public function getObject( entryPoint:Class ):Object
		{
			var node:TreeNode = createNode( entryPoint );
			
			TreeIterator.postorder( node, construct );
						
			return null;
		}
		
		internal function construct( node:TreeNode ):void
		{
			var clazz:Class = node.data as Class;
			var obj:* = new clazz();
			
			var itr:Iterator = node.children.getIterator();
			while( itr.hasNext() )
			{
				trace( "child", itr.next(), clazz );
			}
		}
		
		
		internal function createNode( clazz:Class, parent:TreeNode = null ):TreeNode
		{
			var node:TreeNode = new TreeNode( clazz, parent );
			
			for each( var accessor:XML in describeType( clazz ).factory.accessor )
			{
				if( accessor.hasOwnProperty( "metadata" ) )
				{
					for each( var metadata:XML in accessor.metadata )
					{
						if( metadata.@name )
						{
							createNode( getClass( accessor.@type ), node );
						}
					}
				}
			}
			return node;
		}
		
		internal function getClass( reflectedName:String ):Class
		{
			return getProvider( reflectedName );
		}
		
		internal function getProvider( clazzName:String ):Class
		{
			for each( var map:IMap in _maps )
			{
				if( map.clazzName == clazzName )
				{
					return map.provider;
				}
			}
			return null;
		}
	}
}

import uk.co.ziazoo.injector.IMap;
import flash.utils.describeType;

class Map implements IMap
{
	private var _clazz:Class;
	private var _provider:Class;
	
	public function Map( clazz:Class, provider:Class )
	{
		_clazz = clazz;
		_provider = provider;
	}
	
	public function get provider():Class
	{
		return _provider;
	}
	
	public function get clazz():Class
	{
		return _clazz;
	}
	
	public function get clazzName():String
	{
		return describeType( _clazz ).@name;
	}	
}



