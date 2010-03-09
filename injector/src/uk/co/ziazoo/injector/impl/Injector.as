package uk.co.ziazoo.injector.impl
{	
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import uk.co.ziazoo.injector.IConfiguration;
	import uk.co.ziazoo.injector.IDependency;
	import uk.co.ziazoo.injector.IInjectionPoint;
	import uk.co.ziazoo.injector.IInjector;
	import uk.co.ziazoo.injector.IMapper;
	import uk.co.ziazoo.injector.IMapping;
	import uk.co.ziazoo.injector.IProvider;
	
	public class Injector implements IInjector
	{
		private var mapper:IMapper;
		private var dependencyFactory:DependencyFactory;
		private var injectionPointFactory:InjectionPointFactory;
    private var reflector:Reflector;
    
		public function Injector( dependencyFactory:DependencyFactory, mapper:IMapper,
		 	injectionPointFactory:InjectionPointFactory, reflector:Reflector )
		{
			this.dependencyFactory = dependencyFactory;
			this.injectionPointFactory = injectionPointFactory;
			this.mapper = mapper;
      this.reflector = reflector;
		}
    
    public static function createInjector():IInjector
    {
      var reflector:Reflector = new Reflector();
      var mapper:IMapper = new Mapper( reflector );
      var dependencyFactory:DependencyFactory = new DependencyFactory();
      var injectionFactory:InjectionPointFactory = 
        new InjectionPointFactory( dependencyFactory, mapper );
      
      return new Injector( 
        dependencyFactory, mapper, injectionFactory, reflector );
    }
		
		/**
		*	@inheritDoc
		*/	
		public function inject( object:Object ):Object
		{
			var mapping:IMapping = getMapping( object );
			var dependency:IDependency = dependencyFactory.forMapping( mapping );
			
			return create( dependency ).getObject();
		}
		
		private function create( dependency:IDependency ):IDependency
		{
      var provider:IProvider = dependency.getProvider();
      if( !provider.requiresInjection )
      {
        return dependency;
      }
      
      var reflection:Reflection = getReflection( dependency );
      
      if( reflection.constructor.hasParams() )
      {
        var injectionPoint:IInjectionPoint = 
          injectionPointFactory.forConstructor( reflection.constructor );

        for each( var child:IDependency in injectionPoint.getDependencies() )
        {
          create( child );
        }
        provider.withDependencies( injectionPoint.getDependencies() ); 
      }
      
      injectMethodDependencies( dependency );
      injectPropertyDependencies( dependency );
      
			return dependency;
		}
    
    private function injectPropertyDependencies( dependency:IDependency ):void
    {
      var reflection:Reflection = getReflection( dependency );
      
      var injectionPoints:Array = injectionPointFactory.forProperties( 
        reflection.properties );
      
      for each( var injectionPoint:PropertyInjectionPoint in injectionPoints )
      {
        for each( var child:IDependency in injectionPoint.getDependencies() )
        {
          var injector:InstancePropertyInjector = new InstancePropertyInjector(
            injectionPoint.getPropertyName(), create( child ).getObject() );
          
          injector.inject( dependency.getObject() );
        }
      }
    }
    
    private function injectMethodDependencies( dependency:IDependency ):void
    {
      var reflection:Reflection = getReflection( dependency );
      
      var injectionPoints:Array = injectionPointFactory.forMethods( 
        reflection.methods );
      
      for each( var injectionPoint:MethodInjectionPoint in injectionPoints )
      {
        for each( var child:IDependency in injectionPoint.getDependencies() )
        {
          create( child );
        }
        
        var injector:InstanceMethodInjector = new InstanceMethodInjector(
          injectionPoint.getMethodName(), injectionPoint.getDependencies() );
        
        injector.inject( dependency.getObject() );
      }
    }
    
    private function getReflection( dependency:IDependency ):Reflection
    {
      var type:Class = dependency.getProvider().type;
      return reflector.getReflection( type ); 
    }
		
		/**
		*	@inheritDoc
		*/	
		public function install( configuration:IConfiguration ):void
		{
			configuration.configure( mapper );
		}
		
    private function getMapping( object:Object, name:String = "" ):IMapping
		{
			return mapper.getMapping( getClass( object ), name );
		}
		
    private function getClass( object:Object ):Class
		{
			if( object is Class )
			{
				return object as Class;
			}
			else
			{
				return getDefinitionByName( getQualifiedClassName( object ) ) as Class;
			}
		}
	}
}