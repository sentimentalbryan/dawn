package uk.co.ziazoo.injector
{
	import de.polygonal.ds.DListIterator;
	import de.polygonal.ds.TreeNode;
	
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;

	public class Builder implements IBuilder, IMapper
	{
		private var _config:IConfig;
		private var _maps:Array;
		private var _singletons:Dictionary;
		
		public function Builder( config:IConfig )
		{
			_config = config;
			_maps = new Array();
			_singletons = new Dictionary();
			_config.create( this );
		}
		
		public function map( clazz:Class ):IMap
		{
			var map:IMap = new Map( clazz );
			_maps.push( map );
			return map;
		}
		
		public function getMap( clazz:Class, name:String = null ):IMap
		{
			var noneNamed:IMap = null;
			for each( var map:IMap in _maps )
			{
				if( map.clazz == clazz )
				{
					if( name == map.provider.name )
					{
						return map;
					}
					else if( !map.provider.name )
					{
						noneNamed = map;
					}
				}
			}
			return noneNamed;
		}
		
		public function getMapByName( className:String, name:String = null ):IMap
		{
			return getMap( getDefinitionByName( className ) as Class, name );
		}
			
		
		public function getObject( entryPoint:Class ):Object
		{
			var node:TreeNode = createNode( getMap( entryPoint ) );
			trace( node.dump() );
			return construct( node );
		}
		
		
		internal function construct( root:TreeNode ):Object
		{
			var itr:DListIterator = root.children.getIterator() as DListIterator;
			
			// get the map for this node
			var map:IMap = root.data as IMap;
			
			// have we already created this object?
			if( map.provider.singleton
				&& _singletons[ map.provider.clazz ] )
			{
				return _singletons[ map.provider.clazz ]; 
			}
			
			// create the dependencies			
			var children:Array = [];
			for ( ; itr.valid(); itr.forth() )
			{
				var node:TreeNode = TreeNode( itr.data );
				var child:Object = construct( node );
				children.push( new MapWithInstance( node.data as IMap, child ) );
			}
			
			var obj:Object = map.provider.createInstance();
			
			for each( var pair:MapWithInstance in children )
			{
				obj[ map.provider.getAccessor( pair.map.provider ) ] = pair.instance;
			}
			
			// object is now created and dependencies have been injected
			
			if( map.provider.singleton )
			{
				_singletons[ map.provider.clazz ] = obj
			}
			
			if( map.provider.hasCompletionTrigger() )
			{
				var trigger:Function = obj[ map.provider.completionTrigger ];
				trigger.apply( obj );
			}

			return obj;
		}
		
		internal function createNode( map:IMap, parent:TreeNode = null ):TreeNode
		{
			var node:TreeNode = new TreeNode( map, parent );
			
			var clazz:Class = map.provider.clazz;
			var reflection:XML = describeType( clazz );
			var injects:XMLList = reflection.factory..metadata.(@name == "Inject");
			
			for each( var metadata:XML in injects )
			{
				var accessor:XML = metadata.parent();
				var name:String = null
				if( metadata.hasOwnProperty( "arg" ) )
				{
					name = metadata.arg.( @key=="name" ).@value;
				}
				// the provider has a dependency on a 
				// class/interface of type accessor.@type
				var childMap:IMap = getMapByName( accessor.@type, name );
				map.provider.addAccessor( accessor.@name, childMap.provider );
				createNode( childMap, node );
			}
			
			var callbacks:XMLList = reflection.factory.method.metadata.(@name == "DependenciesInjected");
			var callback:XML = callbacks.parent();
			
			if( callback )
			{
				map.provider.completionTrigger = callback.@name;
			}
			
			return node;
		}
	}
}
import uk.co.ziazoo.injector.IMap;

class MapWithInstance
{
	public var map:IMap;
	public var instance:Object;
	
	public function MapWithInstance( map:IMap, instance:Object )
	{
		this.map = map;
		this.instance = instance;
	}
}